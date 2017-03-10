# NAME

Lingua::PT::Actants - compute verb actants for Portuguese

# VERSION

version 0.04

# SYNOPSIS

    # using as a library
    use Lingua::PT::Actants;
    my $a = Lingua::PT::Actants->new( conll => $input );
    my $actants = $a->actants;  # a list cores per main verb found

    # example from the command line
    $ cat examples/input-1.txt
    1   A       _   DET     DET     _   2   det     _   _
    2   Maria   _   PROPN   PROPN   _   3   nsubj   _   _
    3   tem     _   VERB    VERB    _   0   ROOT    _   _
    4   razão   _   NOUN    NOUN    _   3   dobj    _   _
    5   .       _   PUNCT   PUNCT   _   3   punct   _   _

    $ actants examples/input-1.txt
    A Maria tem razão .
    
    # Actants syntagma cores
     Verb: tem
      = Maria
      = razão
    
    # Actants syntagmas
     Verb: tem
      = A Maria
      = razão

# DESCRIPTION

This module implements an algorithm that computes the actants, and
corresponding syntagmas, for a sentence.

For a complete example visit this
[page](http://norma-simplex.nrc.pt/docs/acts-1.html).

# METHODS

## new

Create a new object, pass as argument the input text in CONLL format.

## text

Returns the original text.

## acts\_cores

Compute the core (a token) of the actants syntagmas.

## acts\_syntagmas

Given the actants cores compute the full syntagma (phrase) for each core.

## actants

Compute actants for a sentence, returns a list of actants found.

## pp\_acts\_cores

Pretty print actants cores, mainly to be used by the command line interface.

## pp\_acts\_syntagmas

Pretty print actants syntagmas, mainly to be used by the command line interface.

# ACKNOWLEDGEMENTS

This work is a result of the project “SmartEGOV: Harnessing EGOV for Smart
Governance (Foundations, methods, Tools) / NORTE-01-0145-FEDER-000037”,
supported by Norte Portugal Regional Operational Programme (NORTE 2020),
under the PORTUGAL 2020 Partnership Agreement, through the European Regional
Development Fund (EFDR).

# AUTHOR

Nuno Carvalho <smash@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016-2017 by Nuno Carvalho.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
