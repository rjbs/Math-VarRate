use strict;
use warnings;
package Math::VarRate;
# ABSTRACT: deal with linear, variable rates of increase

use Carp ();
use Scalar::Util ();

=head1 DESCRIPTION

Math::VarRate is a very, very poor man's calculus.  A Math::VarRate object
represents an accumulator that increases at a varying rate over time.  The rate
may change, it is always a linear, positive rate of change.

You can imagine the rate as representing "units gained per time."  You can then
interrogate the Math::VarRate object for the total units accumulated at any
given offset in time, or for the time at which a given number of units will
have first been accumulated.

=method new

  my $varrate = Math::VarRate->new(\%arg);

Valid arguments to C<new> are:

  rate_changes - a hashref in which keys are offsets and values are rates

=cut

sub new {
  my ($class, $arg) = @_;

  my $changes = $arg->{rate_changes} || {};
  my $self = bless {
    rate_changes   => $changes,
    starting_value => $arg->{starting_value} || 0,
  } => $class;

  $self->_sanity_check_rate_changes;
  $self->_precompute_offsets;

  return $self;
}

sub _sanity_check_rate_changes {
  my ($self) = @_;
  my $rc = $self->{rate_changes};

  my %check = (
    rates   => [ values %$rc ],
    offsets => [ keys %$rc   ],
  );

  while (my ($k, $v) = each %check) {
    Carp::confess("non-numeric $k are not allowed")
      if grep { ! Scalar::Util::looks_like_number($_) } @$v;
    Carp::confess("negative $k are not allowed") if grep { $_ < 0 } @$v;
  }
}

=method starting_value

The starting value of the accumulator.  At present, it is fixed at zero and
non-zero starting values have not been tested.

=cut

sub starting_value { $_[0]->{starting_value} || 0 }

=method offset_for

  my $offset = $varrate->offset_for($value);

This method returns the offset (positive, from 0) at which the given value is
reached.  If the given value will never be reached, undef will be returned.

=cut

sub offset_for {
  my ($self, $value) = @_;

  Carp::croak("illegal value: non-numeric")
    unless Scalar::Util::looks_like_number($value);

  Carp::croak("illegal value: negative") unless $value >= 0;

  $value += 0;

  return 0 if $value == $self->starting_value;

  my $ko       = $self->{known_offsets};
  my ($offset) = sort { $b <=> $a } grep { $ko->{ $_ } < $value } keys %$ko;

  return unless defined $offset;

  my $rate     = $self->{rate_changes}{ $offset };

  # If we stopped for good, we can never reach the target. -- rjbs, 2009-05-11
  return undef if $rate == 0;

  my $to_go    = $value - $ko->{ $offset };
  my $dur      = $to_go / $rate;

  return $offset + $dur;
}

=method value_at

  my $value = $varrate->value_at($offset);

This returns the value in the accumulator at the given offset.

=cut

sub value_at {
  my ($self, $offset) = @_;

  Carp::croak("illegal offset: non-numeric")
    unless Scalar::Util::looks_like_number($offset);

  Carp::croak("illegal offset: negative") unless $offset >= 0;

  $offset += 0;

  my $known_offsets = $self->{known_offsets};

  return $known_offsets->{ $offset } if exists $known_offsets->{ $offset };

  my ($max) = sort { $b <=> $a } grep { $_ < $offset } keys %$known_offsets;

  return $self->starting_value unless defined $max;

  my $start = $known_offsets->{ $max };
  my $rate  = $self->{rate_changes}{ $max };
  my $dur   = $offset - $max;

  return $start  +  $rate * $dur;
}

sub _precompute_offsets {
  my ($self) = @_;

  my $value   = $self->starting_value;
  my $v_at_o  = {};
  my %changes = %{ $self->{rate_changes} };
  my $prev    = 0;
  my $rate    = 0;

  for my $offset (sort { $a <=> $b } keys %changes) {
    my $duration = $offset - $prev;

    $value += $duration * $rate;
    $v_at_o->{ $offset } = $value;

    $rate = $changes{ $offset };
    $prev = $offset;
  }

  $self->{known_offsets} = $v_at_o;
}

1;
