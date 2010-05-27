#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

package Foo;

sub new_instance {
    my $class = shift;
    bless { @_ }, $class;
}

sub foo {
    my $self = shift;
    return $self->{foo} unless @_;
    $self->{foo} = shift;
}

package Foo::Moose;
use Moose;
use MooseX::NonMoose -constructor => 'new_instance';
extends 'Foo';

has bar => (
    is => 'rw',
);

package main;

my $foo_moose = Foo::Moose->new_instance(foo => 'FOO', bar => 'BAR');
is($foo_moose->foo, 'FOO', 'foo set in constructor');
is($foo_moose->bar, 'BAR', 'bar set in constructor');
$foo_moose->foo('BAZ');
$foo_moose->bar('QUUX');
is($foo_moose->foo, 'BAZ', 'foo set by accessor');
is($foo_moose->bar, 'QUUX', 'bar set by accessor');

done_testing;
