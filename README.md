# NAME

Lingua::PT::Actants - compute verb actants for portuguese

# VERSION

version 0.01

# SYNOPSIS

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

# DESCRIPTION

This module implements an algorithm that computes a sorted rank of tokens
where the score measures the propensity of the token being an actant
for the verb to which is related.

# FUNCTIONS

## new

Create a new object.

## actants

Compute actants for a sentence, returns a list of actants found.

## pp\_acts

Pretty print actants list, mainly to be used by the command line interface.

# AUTHOR

Nuno Carvalho <smash@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Nuno Carvalho.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
