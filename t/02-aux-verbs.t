#!perl -T

use strict;
use warnings FATAL => 'all';

use Test::More tests => 14;
use Lingua::PT::Actants;
use Path::Tiny;
use utf8::all;
use Data::Dumper;

my $gold = {
    c1 => 'cidadão',
    c2 => 'proposta',
    a1 => 'Cada cidadão',
    a2 => 'uma proposta',
    verb => {
        2 => 'apresenta',
        3 => 'pode-apresentar',
        4 => 'só-pode-apresentar',
      }
  };

foreach my $i (2 .. 4) {
  my $input = path("examples/input-$i.conll")->slurp;
  my $o = Lingua::PT::Actants->new( conll=>$input );
  my @cores = $o->acts_cores;
  ok( scalar(@cores) == 1, 'one verb only' );
  ok( $cores[0]->{verb}->{form} eq $gold->{verb}->{$i}, "verb is _$gold->{verb}->{$i}_" );

  ok( $cores[0]->{rank}->[0]->{token}->{form} eq $gold->{c1}, "first entry in rank is _$gold->{c1}_" );
  ok( $cores[0]->{rank}->[1]->{token}->{form} eq $gold->{c2}, "second entry in rank is _$gold->{c2}_" );

  my @acts = $o->actants;
  ok( $acts[0]->{verb}->{form} eq $gold->{verb}->{$i}, "verb is _$gold->{verb}->{$i}_" );
  my $a1 = join(' ', map {$_->{form}} @{ $acts[0]->{acts}->[0]->{tokens} });
  ok( $a1 eq $gold->{a1}, "first actant is _$gold->{a1}_");
  my $a2 = join(' ', map {$_->{form}} @{ $acts[0]->{acts}->[1]->{tokens} });
  ok( $a2 eq $gold->{a2}, "second actant is _$gold->{a2}_");
}

