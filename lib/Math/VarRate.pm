use strict;
use warnings;
package Math::VarRate;

sub new {
  my ($class, $arg) = @_;

  my $self = bless { rate_changes => $arg->{rate_changes} }  => $class;

  $self->_precompute_offsets;

  return $self;
}

sub starting_value { 0 }

sub offset_for {
  my ($self, $value) = @_;
  $value += 0;

  my $ko       = $self->{known_offsets};
  my ($offset) = sort { $b <=> $a } grep { $ko->{ $_ } < $value } keys %$ko;

  my $rate     = $self->{rate_changes}{ $offset };
  my $to_go    = $value - $ko->{ $offset };
  my $dur      = $to_go / $rate;

  return $offset + $dur;
}

sub value_at {
  my ($self, $offset) = @_;
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
