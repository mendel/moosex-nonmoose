#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

package Foo;

sub new_instance {
    my $class = shift;
    bless { _class => $class }, $class;
}

package Foo::Moose;
use Moose;
use MooseX::NonMoose -constructor => 'new_instance';
extends 'Foo';

package main;
my $foo = Foo->new_instance;
my $foo_moose = Foo::Moose->new_instance;
isa_ok($foo, 'Foo');
is($foo->{_class}, 'Foo', 'Foo gets the correct class');
isa_ok($foo_moose, 'Foo::Moose');
isa_ok($foo_moose, 'Foo');
isa_ok($foo_moose, 'Moose::Object');
is($foo_moose->{_class}, 'Foo::Moose', 'Foo::Moose gets the correct class');
my $meta = Foo::Moose->meta;
ok($meta->has_method('new_instance'), 'Foo::Moose has its own constructor');
my $cc_meta = $meta->constructor_class->meta;
isa_ok($cc_meta, 'Moose::Meta::Class');
ok($cc_meta->does_role('MooseX::NonMoose::Meta::Role::Constructor'),
   'Foo::Moose gets its constructor from MooseX::NonMoose');

done_testing;
