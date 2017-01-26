# NAME

Lingua::PT::Actants - compute verb actants for Portuguese

# VERSION

version 0.03

# SYNOPSIS

    # using as a library
    use Lingua::PT::Actants;
    my $a = Lingua::PT::Actants->new( conll => $input );
    my $actants = $a->actants;  # a list cores per main verb found

    # example from the command line
    $ cat examples/input.txt 
    1   A       _   DET     DET     _   2   det     _   _
    2   Maria   _   PROPN   PROPN   _   3   nsubj   _   _
    3   tem     _   VERB    VERB    _   0   ROOT    _   _
    4   razão   _   NOUN    NOUN    _   3   dobj    _   _
    5   .       _   PUNCT   PUNCT   _   3   punct   _   _

    $ actants input.txt
    A Maria tem razão .
    
    # Actants syntagmas
     Verb: tem
      A1: A Maria
      A2: razão
    
    # Actants syntagma cores
     Verb: tem
      + Maria
      + razão
    
    # Actants cores ranks
     Verb: tem
      0.533333 | Maria
      0.466667 | razão
      0.000000 | A
      0.000000 | tem
      0.000000 | .

# DESCRIPTION

This module implements an algorithm that computes a sorted rank of tokens
where the score measures the propensity of the token being an actant
for the verb to which is related.

# METHODS

## new

Create a new object, pass as argument the input text in CONLL format.

## text

Returns the original text.

## acts\_cores

Compute the core (a token) of the actants syntagmas as rank sorted by score.

## pp\_acts\_cores

Pretty print actants cores, mainly to be used by the command line interface.

## actants

Compute actants for a sentence, returns a list of actants found.

## pp\_acts\_syntagmas

Pretty print actants syntagmas, mainly to be used by the command line interface.

# ACKNOWLEDGEMENTS

This work is partially supported by the "Programa Operacional da Região Norte", NORTE2020, in the context of project NORTE-01-0145-FEDER-000037.

# AUTHOR

Nuno Carvalho <smash@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016-2017 by Nuno Carvalho.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
