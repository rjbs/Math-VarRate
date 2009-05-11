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
  reference => Math::VarRate->new({ starting_rate => 1 }),
  alpha     => Math::VarRate->new({
    starting_rate => 1,
    rate_changes  => [
      100 => 2.0,
      200 => 1.5,
    ],
  }),
  beta      => Math::VarRate->new({
    starting_rate => 1,
    rate_changes  => [
      100 => 0.5,
      175 => 1,
    ],
  }),
);

isa_ok($meter{$_}, 'Math::VarRate') for keys %meter;
