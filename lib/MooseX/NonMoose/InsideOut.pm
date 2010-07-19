package MooseX::NonMoose::InsideOut;
use Moose::Exporter;
# ABSTRACT: easy subclassing of non-Moose non-hashref classes

=head1 SYNOPSIS

  package Term::VT102::NBased;
  use Moose;
  use MooseX::NonMoose::InsideOut;
  extends 'Term::VT102';

  has [qw/x_base y_base/] => (
      is      => 'ro',
      isa     => 'Int',
      default => 1,
  );

  around x => sub {
      my $orig = shift;
      my $self = shift;
      $self->$orig(@_) + $self->x_base - 1;
  };

  # ... (wrap other methods)

  no Moose;
  # no need to fiddle with inline_constructor here
  __PACKAGE__->meta->make_immutable;

  my $vt = Term::VT102::NBased->new(x_base => 0, y_base => 0);

=head1 DESCRIPTION

=cut

my ($import, $unimport, $init_meta) = Moose::Exporter->build_import_methods(
    metaclass_roles          => ['MooseX::NonMoose::Meta::Role::Class'],
    constructor_class_roles  => ['MooseX::NonMoose::Meta::Role::Constructor'],
    instance_metaclass_roles => ['MooseX::InsideOut::Role::Meta::Instance'],
    install                  => [qw(unimport)],
);

#FIXME code duplicated from MooseX::NonMoose -> extract to a role
sub import {
    my $class = shift;

    my $constructor_idx = first_index { $_ eq '-constructor' } @_;
    my $constructor_name =
      $constructor_idx >= 0
        ? ( splice @_, $constructor_idx, 2 )[1]
        : 'new';

    my $config = ref $_[0] eq 'HASH' ? shift : {};
    my $into_class = $config->{into} || caller($config->{into_level} || 0);
    $config->{into_level}++;
    $class->$import($config, @_);

    $into_class->meta->constructor_name($constructor_name);
}

sub init_meta {
    my $package = shift;
    my %options = @_;
    Carp::cluck('Roles have no use for MooseX::NonMoose')
        if Class::MOP::class_of($options{for_class})->isa('Moose::Meta::Role');
    $package->$init_meta(@_);
}

=begin Pod::Coverage

  init_meta

=end Pod::Coverage

=cut

1;
