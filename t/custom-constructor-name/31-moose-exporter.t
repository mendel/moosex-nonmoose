#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN {
    require Moose;

    package Foo::Exporter::Class;
    use Moose::Exporter;
    Moose::Exporter->setup_import_methods(also => ['Moose']);

    sub init_meta {
        shift;
        my %options = @_;
        Moose->init_meta(%options);
        Moose::Util::MetaRole::apply_metaclass_roles(
            for_class               => $options{for_class},
            metaclass_roles         => ['MooseX::NonMoose::Meta::Role::Class'],
        );
        my $meta = Class::MOP::class_of($options{for_class});
        $meta->constructor_name('new_instance');
        return $meta;
    }

    package Foo::Exporter::ClassAndConstructor;
    use Moose::Exporter;
    Moose::Exporter->setup_import_methods(also => ['Moose']);

    sub init_meta {
        shift;
        my %options = @_;
        Moose->init_meta(%options);
        Moose::Util::MetaRole::apply_metaclass_roles(
            for_class               => $options{for_class},
            metaclass_roles         => ['MooseX::NonMoose::Meta::Role::Class'],
            constructor_class_roles =>
                ['MooseX::NonMoose::Meta::Role::Constructor'],
        );
        my $meta = Class::MOP::class_of($options{for_class});
        $meta->constructor_name('new_instance');
        return $meta;
    }

}

package Foo;

sub new_instance { bless {}, shift }

package Foo::Moose;
BEGIN { Foo::Exporter::Class->import }
extends 'Foo';

package Foo::Moose2;
BEGIN { Foo::Exporter::ClassAndConstructor->import }
extends 'Foo';

package main;
ok(Foo::Moose->meta->has_method('new_instance'),
   'using only the metaclass trait still installs the constructor');
isa_ok(Foo::Moose->new_instance, 'Moose::Object');
isa_ok(Foo::Moose->new_instance, 'Foo');
my $method = Foo::Moose->meta->get_method('new_instance');
Foo::Moose->meta->make_immutable;
is(Foo::Moose->meta->get_method('new_instance'), $method,
   'inlining doesn\'t happen when the constructor trait isn\'t used');
ok(Foo::Moose2->meta->has_method('new_instance'),
   'using only the metaclass trait still installs the constructor');
isa_ok(Foo::Moose2->new_instance, 'Moose::Object');
isa_ok(Foo::Moose2->new_instance, 'Foo');
my $method2 = Foo::Moose2->meta->get_method('new_instance');
Foo::Moose2->meta->make_immutable;
isnt(Foo::Moose2->meta->get_method('new_instance'), $method2,
   'inlining does happen when the constructor trait is used');

done_testing;
