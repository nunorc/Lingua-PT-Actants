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

  # pre process data
  $data = _pre_proc_tree($data) if $data;

  my $self = bless({ data=>$data }, $class);
  return $self;
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

sub sentence {
  my ($self) = @_;

  return join(' ', map {$_->{form}} @{$self->{data}});
}

sub actants {
  my ($self, %args) = @_;

  my @cores = $self->acts_cores($self->{data});
  my @acts = $self->acts_syntagmas([@cores], $self->{data});

  return @acts;
}

sub acts_cores {
  my ($self) = @_;
  my $data = $self->{data};

  my @verbs;
  foreach (@{$data}) {
    push @verbs, $_ if (lc($_->{pos}) eq 'verb');
  }

  my @cores;
  foreach my $v (@verbs) {
    my $paths = _paths($v, $data);

    my @result;
    foreach (@$paths) {
      my $score = _score($_);
      if ($score >= 0) {
        push @result, { token=>$_->[0], score=>$score};
      }
    }

    # normalize results
    my $total = 0;
    $total += $_->{score} foreach @result;
    $_->{score} = $_->{score}/$total foreach @result;

    # sort results
    @result = sort {$b->{score} <=> $a->{score}} @result;

    push @cores, { verb=>$v, rank=>[@result] };
  }

  return @cores;
}

sub acts_syntagmas {
  my ($self, $cores, $data) = @_;

  my @acts;
  foreach my $v (@$cores) {
    my @list;
    foreach my $r (@{ $v->{rank} }) {
      next unless $r->{score} >= 0.02;  # FIXME: threshold cut option

      my @child = _child($r->{token}, $data);

      next unless @child;
      push @list, { tokens=>[@child] };
    }
    push @acts, { verb=>$v->{verb}, acts=>[@list] };
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
  return -1 if ($pos =~ m/^(punct)$/i);

  return 0.1;
}

sub _score_rule {
  my ($rule) = @_;

  return 0.8 if ($rule =~ m/^(nsubj)$/i);
  return 0.7 if ($rule =~ m/^(dobj)$/i);

  return 0.1;
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
  my ($self, @cores) = @_;
  my $r = "# Actants syntagma cores\n";

  foreach my $v (@cores) {
    $r .= " Verb: $v->{verb}->{form}\n";
    foreach (@{$v->{rank}}) {
      $r .= sprintf "  %.6f | %s\n", $_->{score}, $_->{token}->{form};
    }
  }

  return $r;
}

sub pp_acts_syntagmas {
  my ($self, @acts) = @_;
  my $r = "# Actants syntagmas\n";

  foreach my $v (@acts) {
    $r .= " Verb: $v->{verb}->{form}\n";
    my $i = 1;
    foreach (@{$v->{acts}}) {
      $r .= sprintf "  %s: %s\n", "A$i", join(' ', map {$_->{form}} @{$_->{tokens}});
      $i++;
    }
  }

  return $r;
}

sub _pre_proc_tree {
  my ($data) = @_;

  my $i;
  for ($i = 0; $i < @$data-1; $i++) {
    my ($a, $b) = ($data->[$i], $data->[$i+1]);

    if ($a->{pos} eq 'VERB' and $b->{pos} eq 'VERB' and $b->{rule} eq 'xcomp') {
      $data = _update_tree($data, $a, $b);
    }
  }

  return $data;
}

sub _update_tree {
  my ($data, $v1, $v2) = @_;

  # handle auxiliar verbs
  my @final = ();
  my $i = 0;
  for (@$data) {
    $_->{dep} = $v1->{id} if ($_->{dep} == $v2->{id});

            #'id' => '3', 'form' => 'pode', 'rule' => 'ROOT', 'pos' => 'VERB',
            #'dep' => '0'
    if ($_->{id} == $v1->{id}) {
      push @final, {id=>$_->{id}, form=>join('-',$v1->{form}, $v2->{form}), rule=>'ROOT', pos=>'VERB', dep=> '0'};
    }

    $_->{id} = $_->{id}-1 if ($_->{id} > $v1->{id});
    $_->{dep} = $_->{dep}-1 if ($_->{dep} > $v1->{id});

    push @final, $_ unless ($_->{id} == $v1->{id} or $_->{id} == $v2->{id});
  }

  return [@final];
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

=func acts_cores

Compute the core (a token) of the actants syntagmas as rank sorted by score.

=func pp_acts_cores

Pretty print actants cores, mainly to be used by the command line interface.


=func actants

Compute actants for a sentence, returns a list of actants found.

=func pp_acts_syntagmas

Pretty print actants syntagmas, mainly to be used by the command line interface.

