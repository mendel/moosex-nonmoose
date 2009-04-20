package MooseX::NonMoose::Meta::Role::Class;
use Moose::Role;

has replace_constructor => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

around _make_immutable_transformer => sub {
    my $orig = shift;
    my $self = shift;
    my %args = @_;
    return $self->$orig(@_) if exists $args{inline_constructor}
                            && !$args{inline_constructor};
    $args{replace_constructor} = 1 if $self->replace_constructor;
    $self->$orig(%args);
};

around superclasses => sub {
    my $orig = shift;
    my $self = shift;

    return $self->$orig unless @_;

    my @superclasses = @_;
    push @superclasses, 'Moose::Object'
        unless grep { $_->isa('Moose::Object') } @superclasses;

    my @ret = $self->$orig(@superclasses);

    # we need to get the non-moose constructor from the superclass
    # of the class where this method actually exists, regardless of what class
    # we're calling it on
    # XXX: get constructor name from the constructor metaclass?
    my $super_new = $self->find_next_method_by_name('new');

    # if we're trying to extend a (non-immutable) moose class, just do nothing
    return @ret if $super_new->package_name eq 'Moose::Object';

    if ($super_new->associated_metaclass->can('constructor_class')) {
        my $constructor_class_meta = Class::MOP::Class->initialize(
            $super_new->associated_metaclass->constructor_class
        );

        # if the constructor we're inheriting is already one of ours, there's
        # no reason to install a new one
        return @ret if $constructor_class_meta->can('does_role')
                    && $constructor_class_meta->does_role('MooseX::NonMoose::Meta::Role::Constructor');

        # if the constructor we're inheriting is an inlined version of the
        # default moose constructor, don't do anything either
        # XXX: wrong if the class overrode new manually?
        return @ret if $constructor_class_meta->name eq 'Moose::Meta::Method::Constructor';
    }

    $self->add_method(new => sub {
        my $class = shift;

        my $params = $class->BUILDARGS(@_);
        my $instance = $super_new->execute($class, @_);
        my $self = Class::MOP::Class->initialize($class)->new_object(
            __INSTANCE__ => $instance,
            %$params,
        );
        $self->BUILDALL($params);
        return $self;
    });
    $self->replace_constructor(1);

    return @ret;
};

no Moose::Role;

1;
