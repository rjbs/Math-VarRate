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
  ref   => Math::VarRate->new({ rate_changes => { 0 => 1 } }),
  alpha => Math::VarRate->new({
    rate_changes => {
      0   => 1,
      100 => 2.0,
      200 => 1.5,
    },
  }),
  beta  => Math::VarRate->new({
    rate_changes => {
      0   => 1,
      100 => 0.5,
      175 => 1,
    },
  }),
);

isa_ok($meter{$_}, 'Math::VarRate') for keys %meter;

is($meter{$_}->value_at(0),  0,  "$_ meter: 0 at 0") for keys %meter;
is($meter{$_}->value_at(50), 50, "$_ meter: 50 at 50") for keys %meter;

is(
  $meter{ref}->value_at(300),
  300,
  "ref meter: 300 at 300",
);

is(
  $meter{alpha}->value_at(300),
  450,
  "alpha meter: 450 at 300",
);

is(
  $meter{beta}->value_at(300),
  262.5,
  "beta meter: 262.5 at 300",
);

is($meter{ref}->offset_for(300),    300, "ref meter: 300 at 300 (value_at)");
is($meter{alpha}->offset_for(450),  300, "ref meter: 450 at 300 (value_at)");
is($meter{beta}->offset_for(262.5), 300, "ref meter: 262.5 at 300 (value_at)");
