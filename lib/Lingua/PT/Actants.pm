package Lingua::PT::Actants;
# ABSTRACT: compute verb actants for Portuguese

use strict;
use warnings;

sub new {
  my ($class) = @_;
  my $self = bless({}, $class);

  return $self;
}

sub actants {
  my ($self, %args) = @_;

  my $data;

  # input is in conll* format
  if (exists($args{conll})) {
    $data = _conll2data($args{conll});
  }

  return _deps2acts($data);
}

sub _conll2data {
  my ($input) = @_;

  my @data;
  foreach my $line (split /\n/, $input) {
    my @l = split /\s+/, $line;
    push @data, {id=>$l[0],form=>$l[1],pos=>$l[3],dep=>$l[6],rule=>$l[7]};
  }

  return [@data];
}

sub _deps2acts {
  my ($data) = @_;
  my $acts = {};

  my @verbs;
  foreach (@{$data}) {
    push @verbs, $_ if (lc($_->{pos}) eq 'verb');
  }

  my @acts;
  foreach my $v (@verbs) {
    my $paths = _paths($v, $data);

    my @result;
    foreach (@$paths) {
      my $score = _score($_);
      push @result, {token=>$_->[0],score=>$score};
    }

    # normalize results
    my $total = 0;
    $total += $_->{score} foreach @result;
    $_->{score} = $_->{score}/$total foreach @result;

    # sort results
    @result = sort {$b->{score} <=> $a->{score}} @result;

    push @acts, { verb=>$v, rank=>[@result] };
  }

  return @acts;
}

sub _paths {
  my ($pivot, $data) = @_;
  my @paths;

  foreach (@{$data}) {
    my $p = _fullpath($_, $pivot, $data, []);
    push @paths, $p if ($p and @$p>1);
  }

  return [@paths];
}

sub _fullpath {
  my ($from, $to, $data, $path) = @_;
  push @$path, $from;

  if ($from->{id} == $to->{id}) {
    return $path;
  }
  else {
    foreach (@{$data}) {
      if ($from->{dep} == $_->{id}) {
        _fullpath($_, $to, $data, $path);
      }
    }
    return ($path->[-1]->{id} == $to->{id} ? $path : []);
  }

  return [];
}

sub _score {
  my ($path) = @_;
  my $score = 0;

  #foreach (@$path) { $score += _el_score($_); }
  $score = _el_score($path->[0]);

  return $score / (scalar(@$path)*scalar(@$path));
}

sub _el_score {
  my ($el) = @_;

  my $score = _score_pos($el->{pos}) * _score_rule($el->{rule});

  return $score;
}

sub _score_pos {
  my ($pos) = @_;

  return 0.8 if ($pos =~ m/^(noun|propn)$/i);

  return 0.1;
}

sub _score_rule {
  my ($rule) = @_;

  return 0.8 if ($rule =~ m/^(nsubj)$/i);
  return 0.7 if ($rule =~ m/^(dobj)$/i);

  return 0.1;
}

sub pp_acts {
  my ($self, @acts) = @_;

  foreach my $v (@acts) {
    print "Actants rank for verb: $v->{verb}->{form}\n";
    foreach (@{$v->{rank}}) {
      printf " %.6f | %s\n", $_->{score}, $_->{token}->{form};
    }
  }
}

1;

__END__

=encoding UTF-8

=head1 SYNOPSIS

    # using as a library
    use Lingua::PT::Actants;;
    my $a = Lingua::PT::Actants->new;
    my @actants = $a->actants($input);

    # example from the command line
    $ cat examples/input.txt 
    1   A       _   DET     DET     _   2   det     _   _
    2   Maria   _   PROPN   PROPN   _   3   nsubj   _   _
    3   tem     _   VERB    VERB    _   0   ROOT    _   _
    4   razão   _   NOUN    NOUN    _   3   dobj    _   _
    5   .       _   PUNCT   PUNCT   _   3   punct   _   _
    $ cat examples/input.txt | perl -Ilib bin/actants 
    Actants rank for verb: tem
     0.526990 | Maria
     0.461116 | razão
     0.008234 | .
     0.003660 | A


=head1 DESCRIPTION

This module implements an algorithm that computes a sorted rank of tokens
where the score measures the propensity of the token being an actant
for the verb to which is related.

=func new

Create a new object.

=func actants

Compute actants for a sentence, returns a list of actants found.

=func pp_acts

Pretty print actants list, mainly to be used by the command line interface.

