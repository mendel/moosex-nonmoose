#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

package Foo;

sub new_instance { bless {}, shift }

package Foo::Moose;
use Moose -traits => 'MooseX::NonMoose::Meta::Role::Class';
__PACKAGE__->meta->constructor_name('new_instance');
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

done_testing;
