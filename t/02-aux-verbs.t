#!perl -T

use strict;
use warnings FATAL => 'all';

use Test::More tests => 27;
use Lingua::PT::Actants;
use Path::Tiny;
use utf8;

foreach (2 .. 4) {
  my $input = path("examples/input-$_.conll")->slurp_utf8;
  my $o = Lingua::PT::Actants->new( conll => $input );

  my $verb = 'apresenta';
  $verb .= 'r' if $_ > 2;

  my ($cores, $ranks) = $o->acts_cores;
  ok( scalar(@$cores) == 1, 'one verb only' );
  ok( $cores->[0]->{verb}->{form} eq $verb, 'verb is _apresenta_' );
  ok( $cores->[0]->{cores}->[0]->{form} eq 'cidadão', 'first actant core is _cidadão_' );
  ok( $cores->[0]->{cores}->[1]->{form} eq 'proposta', 'second actant core is _proposta_' );

  my $acts = $o->actants;
  ok( scalar(@$acts) == 1, 'one verb only' );
  ok( scalar(@{$acts->[0]->{acts}}) == 2, 'two actants' );
  ok( $acts->[0]->{verb}->{form} eq $verb, 'verb is _apresenta_' );
  ok( _a2t(@{$acts->[0]->{acts}->[0]->{tokens}}) eq 'Cada cidadão', 'first actant is _Cada cidadão_');
  ok( _a2t(@{$acts->[0]->{acts}->[1]->{tokens}}) eq 'uma proposta', 'second actant is _uma proposta_');
}

sub _a2t {
  join(' ', map {$_->{form}} @_);
}
