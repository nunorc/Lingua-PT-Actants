#!perl -T

use strict;
use warnings FATAL => 'all';

use Test::More tests => 4;
use Lingua::PT::Actants;
use Path::Tiny;
use Data::Dumper;

my $o = Lingua::PT::Actants->new;
ok( ref($o) eq 'Lingua::PT::Actants', 'create object' );

my $input = path('examples/input.txt')->slurp_utf8;
my @acts = $o->actants( conll => $input );

ok( scalar(@acts) == 1, 'only one actant' );
ok( $acts[0]->{verb}->{form} eq 'tem', 'verb is _tem_' );
ok( $acts[0]->{rank}->[0]->{token}->{form} eq 'Maria', 'top entry in rank is _Maria_' );


