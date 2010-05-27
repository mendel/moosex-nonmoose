#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

package Foo;

sub new_instance {
    my $class = shift;
    bless { _class => $class }, $class;
}

our $called_new;

sub new {   # not a constructor
    $called_new++;
}

package Foo::Moose;
use Moose;
use MooseX::NonMoose -constructor => 'new_instance';
extends 'Foo';

package main;
my $foo_moose = Foo::Moose->new_instance;
ok(!$Foo::called_new,
  'Foo->new is not called on construction (b/c is not a constructor)');

done_testing;
