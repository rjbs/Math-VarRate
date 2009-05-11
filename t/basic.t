#!perl
use strict;
use warnings;
use Test::More 'no_plan';

# Setup:
# in Reference, constant rate of 1
# in Alpha,     rate of 1 from 0 to 100, 2   from 100 to 200, 1.5 from 200 on
# in Beta,      rate of 1 from 0 to 100, 0.5 from 100 to 175, 1   from 175 on

use Math::VarRate;

my %meter = (
  ref   => Math::VarRate->new({ rate_changes => [ 0 => 1 ] }),
  alpha => Math::VarRate->new({
    rate_changes => [
      0   => 1,
      100 => 2.0,
      200 => 1.5,
    ],
  }),
  beta  => Math::VarRate->new({
    rate_changes => [
      0   => 1,
      100 => 0.5,
      175 => 1,
    ],
  }),
);

isa_ok($meter{$_}, 'Math::VarRate') for keys %meter;

is($meter{$_}->value_at(0), 0, "start $_ meter at 0") for keys %meter;
