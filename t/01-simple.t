#!perl -T

use strict;
use warnings FATAL => 'all';

use Test::More tests => 4;
use Lingua::PT::Actants;
use Path::Tiny;
use Data::Dumper;

my $o = Lingua::PT::Actants->new;
ok( ref($o) eq 'Lingua::PT::Actants', 'actants object' );

my $input = path('examples/input-1.conll')->slurp_utf8;
$o = Lingua::PT::Actants->new( conll=>$input );
my @cores = $o->acts_cores;
ok( scalar(@cores) == 1, 'one verb' );

ok( $cores[0]->{verb}->{form} eq 'tem', 'verb is _tem_' );
ok( $cores[0]->{rank}->[0]->{token}->{form} eq 'Maria', 'top entry in rank is _Maria_' );

