package Lingua::PT::Actants;
# ABSTRACT: compute verb actants for Portuguese

use strict;
use warnings;

sub new {
  my ($class, %args) = @_;
  my $data;

  # input is in conll* format
  if (exists($args{conll})) {
    $data = _conll2data($args{conll});
  }

  my $self = bless({ data=>$data }, $class);
  return $self;
}

sub _conll2data {
  my ($input) = @_;

  my @data;
  foreach my $line (split /\n/, $input) {
    next if $line =~ m/^\s*$/;

    my @l = split /\s+/, $line;
    push @data, {
        id=>$l[0], form=>$l[1], pos=>$l[3], dep=>$l[6], rule=>$l[7]
      };
  }

  return [@data];
}

sub text {
  my ($self) = @_;

  return join(' ', map {$_->{form}} @{$self->{data}});
}

sub actants {
  my ($self, %args) = @_;

  my ($cores, $ranks) = $self->acts_cores($self->{data});
  $self->{cores} = $cores;
  $self->{ranks} = $ranks;

  my @acts = $self->acts_syntagmas($cores, $self->{data});
  $self->{acts} = [@acts];

  return $self->{acts};
}

# compute actant cores
sub acts_cores {
  my ($self) = @_;
  my $data = $self->{data};

  # compute main verbs in the sentence
  my @verbs = _main_verbs($data);

  my @ranks;
  foreach my $v (@verbs) {
    my @result;
    foreach (@$data) {
      my $score = _score($_, $v);
      if ($score >= 0) {
        push @result, { token => $_, score => $score };
      }
    }

    # normalize results
    my $total = 0;
    $total += $_->{score} foreach @result;
    $_->{score} = $_->{score}/$total foreach @result;

    # sort results by score
    @result = sort {$b->{score} <=> $a->{score}} @result;

    push @ranks, { verb => $v, rank => [@result] };
  }

  my @cores;
  foreach (@ranks) {
    my ($verb, @rank) = ( $_->{verb}, @{ $_->{rank} } );

    # trim cores in rank
    my @final;
    my $ac = 0;
    foreach (@rank) {
      next if ($ac > 0.7 or $_->{score} < 0.1);

      push @final, $_;
      $ac += $_->{score};
    }

    # sort cores by token position in sentence
    @final = sort { $a->{token}->{id} <=> $b->{token}->{id} } @final;

    # set to simple list of tokens
    @final = map {$_->{token}} @final;

    push @cores, { verb => $verb, cores => [@final] };
  }

  return ([@cores], [@ranks]);
}

sub _main_verbs {
  my ($data) = @_;
  my @verbs;

  my $i;
  my @tmp;
  for ($i = 0; $i < @$data-1; $i++) {
    my ($a, $b) = ($data->[$i], $data->[$i+1]);

    unless ($a->{pos} eq 'VERB' and $b->{pos} eq 'VERB') {
      push @tmp, $a;
    }
    push @tmp, $b if ($i >= @$data);
  }

  foreach (@tmp) {
    push @verbs, $_ if (lc($_->{pos}) eq 'verb');
  }

  return @verbs;
}

sub acts_syntagmas {
  my ($self, $cores, $data) = @_;

  my @acts;
  foreach (@$cores) {
    my ($verb, @tokens) = ($_->{verb}, @{ $_->{cores} });

    my @list;
    foreach my $t (@tokens) {
      my @child = _child($t, $data);

      next unless @child;
      push @list, { tokens=>[@child] };
    }
    push @acts, { verb=>$verb, acts=>[@list] };
  }

  return @acts;
}

sub _score {
  my ($token, $verb) = @_;
  my $score = 0;

  $score = _score_token($token, $verb);
  my $dist = _dist($token, $verb);

  return ($dist ? $score/sqrt($dist) : 0);
}

sub _score_token {
  my ($token) = @_;

  my $score = (_score_pos($token->{pos}) + _score_rule($token->{rule})) / 2;

  return $score;
}

sub _score_pos {
  my ($pos) = @_;

  return 0.8 if ($pos =~ m/^(noun|propn|prop)$/i);
  return 0 if ($pos =~ m/^(punct)$/i);

  return 0.1;
}

sub _score_rule {
  my ($rule) = @_;

  return 0.8 if ($rule =~ m/^(nsubj|nsubjpass)$/i);
  return 0.6 if ($rule =~ m/^(dobj)$/i);

  return 0.1;
}

sub _dist {
  my ($token, $verb) = @_;

  my $dist = 0;
  $dist = $token->{id} - $verb->{id};
  $dist *= -1 if $dist < 0;

  return $dist;
}

sub _child {
  my ($node, $data) = @_;
  my @child = ();

  my $id_tree = {};
  $id_tree = _id_tree($id_tree, $node, $data);

  foreach my $id (sort keys %$id_tree) {
    foreach (@$data) {
      push @child, $_ if ($_->{id} == $id);
    }
  }

  return @child;
}

sub _id_tree {
  my ($id_tree, $node, $data) = @_;

  $id_tree->{$node->{id}}++;
  foreach (@$data) {
    if ($node->{id} == $_->{dep}) {
      $id_tree = _id_tree($id_tree, $_, $data)
    }
  }

  return $id_tree;
}

sub pp_acts_cores {
  my ($self, $cores) = @_;
  $cores = $self->{cores} unless $cores;

  my $r = "# Actants syntagma cores\n";
  foreach (@$cores) {
    my ($verb, @tokens) = ($_->{verb}, @{$_->{cores}} );

    $r .= " Verb: $verb->{form}\n";
    foreach (@tokens) {
      #$r .= sprintf "  %.6f | %s\n", $_->{score}, $_->{form};
      $r .= sprintf "  + %s\n", $_->{form};
    }
  }

  return $r;
}

sub pp_acts_syntagmas {
  my ($self, $acts) = @_;
  $acts = $self->{acts} unless $acts;

  my $r = "# Actants syntagmas\n";
  foreach (@$acts) {
    my ($verb, @list) = ($_->{verb}, @{ $_->{acts} });

    $r .= " Verb: $verb->{form}\n";
    my $i = 1;
    foreach (@list) {
      $r .= sprintf "  %s: %s\n",
              "A$i",
                join(' ', map {$_->{form}} @{ $_->{tokens}});
      $i++;
    }
  }

  return $r;
}

sub pp_acts_ranks {
  my ($self, $ranks) = @_;
  $ranks = $self->{ranks} unless $ranks;

  my $r = "# Actants cores ranks\n";
  foreach (@$ranks) {
    my ($verb, @rank) = ($_->{verb}, @{$_->{rank}} );

    $r .= " Verb: $verb->{form}\n";
    foreach (@rank) {
      $r .= sprintf "  %.6f | %s\n", $_->{score}, $_->{token}->{form};
    }
  }

  return $r;
}


1;

__END__

=encoding UTF-8

=head1 SYNOPSIS

    # using as a library
    use Lingua::PT::Actants;
    my $a = Lingua::PT::Actants->new( conll => $input );
    my @cores = $a->acts_cores;
    my @actants = $a->actatans;

    # example from the command line
    $ cat examples/input.txt 
    1   A       _   DET     DET     _   2   det     _   _
    2   Maria   _   PROPN   PROPN   _   3   nsubj   _   _
    3   tem     _   VERB    VERB    _   0   ROOT    _   _
    4   razão   _   NOUN    NOUN    _   3   dobj    _   _
    5   .       _   PUNCT   PUNCT   _   3   punct   _   _
    $ cat examples/input.txt | actants
    Sentence: A Maria tem razão .
    # Actants syntagma cores
     Verb: tem
      0.526990 | Maria
      0.461116 | razão
      0.008234 | .
      0.003660 | A
    # Actants syntagmas
     Verb: tem
      A1: A Maria
      A2: razão

=head1 DESCRIPTION

This module implements an algorithm that computes a sorted rank of tokens
where the score measures the propensity of the token being an actant
for the verb to which is related.

=func new

Create a new object, pass as argument the input text in CONLL format.

=func text

Returns the original text.

=func acts_cores

Compute the core (a token) of the actants syntagmas as rank sorted by score.

=func pp_acts_cores

Pretty print actants cores, mainly to be used by the command line interface.

=func actants

Compute actants for a sentence, returns a list of actants found.

=func pp_acts_syntagmas

Pretty print actants syntagmas, mainly to be used by the command line interface.

=head1 ACKNOWLEDGEMENTS

This work is partially supported by the "Programa Operacional da Região Norte", NORTE2020, in the context of project NORTE-01-0145-FEDER-000037.

