#!/usr/bin/perl -w
#
# Transforme le texte xhtml en un corps de document au format OSIS, l'enrobage est à faire indépendement.
#
# Sébastien Koechlin
# $Id: bibleref.pl,v 1.2 2007-12-29 20:56:05 seb Exp $
#

use utf8;	# Le code est écrit en UTF-8
use strict;		# On n'écrit pas comme un porc
use warnings;		#   du quebec
use Data::Dumper;	# Stringify perl data structures
use English;		# Explicit variables names

use bibleref;		# Fonctions de recherche et conversion

$OUTPUT_AUTOFLUSH = 1;	# Unbuffered ouput

# Début du programme
my $cmd = join( ' ', @ARGV );

#print "bookregex = ".$bibleref::bookregex."\n";

$cmd =~ s/($bibleref::bookregex)(?:[\s:-](\d+|[IVXLC]+)(?:(?:\s*v\.?|[\.,;\:])\s*(\d+))?)?/'<ref id="'.bibleref::txt2ref($1,$2,$3).'">'.$MATCH.'<\/ref>'/gie;

print $cmd, "\n";

