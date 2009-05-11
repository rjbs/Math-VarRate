use strict;
use warnings;
package Math::VarRate;
# ABSTRACT: deal with linear, variable rates of increase

use Carp ();
use Scalar::Util ();

=method new

  my $varrate = Math::VarRate->new(\%arg);

Valid arguments to C<new> are:

  rate_changes - a hashref in which keys are offsets and values are rates

=cut

sub new {
  my ($class, $arg) = @_;

  my $self = bless { rate_changes => $arg->{rate_changes} }  => $class;

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

sub starting_value { 0 }

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

  return $self->__initial_compute_value_at($offset) if ! $known_offsets;
  return $known_offsets->{ $offset } if exists $known_offsets->{ $offset };

  my ($max) = sort { $b <=> $a } grep { $_ < $offset } keys %$known_offsets;

  return $self->starting_value unless defined $max;

  my $start = $known_offsets->{ $max };
  my $rate  = $self->{rate_changes}{ $max };
  my $dur   = $offset - $max;

  return $start  +  $rate * $dur;
}

sub __initial_compute_value_at {
  my ($self, $offset) = @_;

  my $value   = $self->starting_value;
  my %changes = %{ $self->{rate_changes} || {} };

  my @points = sort { $a <=> $b } grep { $_ < $offset } keys %changes;

  for my $i (0 .. $#points) {
    my $rate     = $changes{ $points[ $i ] };
    my $duration = $i == $#points
                 ? ($offset - $points[ $i ])
                 : ($points[ $i + 1 ] - $points[ $i ]);

    $value += $rate * $duration;
  }

  return $value;
}

sub _precompute_offsets {
  my ($self) = @_;

  my $value   = {};
  my %changes = %{ $self->{rate_changes} || {} };
  
  for my $offset (keys %changes) {
    $value->{ $offset } = $self->value_at( $offset );
  }

  $self->{known_offsets} = $value;
}

1;
