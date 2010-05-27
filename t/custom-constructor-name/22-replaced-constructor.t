#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

our $foo_constructed = 0;

package Foo;

sub new_instance {
    my $class = shift;
    bless {}, $class;
}

package Foo::Moose;
use Moose;
use MooseX::NonMoose -constructor => 'new_instance';
extends 'Foo';

after new_instance => sub {
    $main::foo_constructed = 1;
};

package Foo::Moose2;
use Moose;
use MooseX::NonMoose -constructor => 'new_instance';
extends 'Foo';

sub new_instance {
    my $class = shift;
    $main::foo_constructed = 1;
    return $class->meta->new_object(@_);
}

package main;
my $method = Foo::Moose->meta->get_method('new_instance');
isa_ok($method, 'Class::MOP::Method::Wrapped');
my $foo = Foo::Moose->new_instance;
ok($foo_constructed, 'method modifier called for the constructor');
$foo_constructed = 0;
{
    # we don't care about the warning that moose isn't going to inline our
    # constructor - this is the behavior we're testing
    local $SIG{__WARN__} = sub {};
    Foo::Moose->meta->make_immutable;
}
is($method, Foo::Moose->meta->get_method('new_instance'),
   'make_immutable doesn\'t overwrite constructor with method modifiers');
$foo = Foo::Moose->new_instance;
ok($foo_constructed, 'method modifier called for the constructor (immutable)');

$foo_constructed = 0;
$method = Foo::Moose2->meta->get_method('new_instance');
$foo = Foo::Moose2->new_instance;
ok($foo_constructed, 'custom constructor called');
$foo_constructed = 0;
# still need to specify inline_constructor => 0 when overriding new_instance manually
Foo::Moose2->meta->make_immutable(inline_constructor => 0);
is($method, Foo::Moose2->meta->get_method('new_instance'),
   'make_immutable doesn\'t overwrite custom constructor');
$foo = Foo::Moose2->new_instance;
ok($foo_constructed, 'custom constructor called (immutable)');

done_testing;
