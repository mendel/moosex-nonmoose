#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Moose;
use Symbol;
BEGIN {
    eval "use MooseX::GlobRef ()";
    plan skip_all => "MooseX::GlobRef is required for this test" if $@;
}

BEGIN {
    require Moose;

    package Foo::Exporter;
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
            instance_metaclass_roles =>
                ['MooseX::GlobRef::Role::Meta::Instance'],
        );
        my $meta = Class::MOP::class_of($options{for_class});
        $meta->constructor_name('new_instance');
        return $meta;
    }
}

package Foo;

sub new_instance {
    return bless Symbol::gensym, shift;
}

package Foo::Moose;
BEGIN { Foo::Exporter->import }
extends 'Foo';

has bar => (
    is => 'rw',
    isa => 'Str',
);

sub FOREIGNBUILDARGS { return }

package main;

with_immutable {
    my $handle = Foo::Moose->new_instance(bar => 'BAR');
    is($handle->bar, 'BAR', 'moose accessor works properly');
    $handle->bar('RAB');
    is($handle->bar, 'RAB', 'moose accessor works properly (setting)');
} 'Foo::Moose';

done_testing;
