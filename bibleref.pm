package bibleref;
#
# Normalise une référence biblique
#
# Sébastien Koechlin
# $Id: bibleref.pm,v 1.3 2007-12-29 20:54:12 seb Exp $
#

use utf8;	# Le code est écrit en UTF-8
use strict;		# On n'écrit pas comme un porc
use warnings;		#   du quebec
use English;		# Explicit variables names
use Roman;		# Module de conversion des nombres romains

our %bookpatt;		# Hachage contenant les regex de chaque livre
our $bookregex;		# Variable contenant la regex globale de tous les livres
#my %rom2ara;		# Hachage des nombres romains (dans le cas où Roman n'est pas dispo)

BEGIN {
	%bookpatt = (
		'Gen' =>	'Gen%[èe]se',
		'Exod' =>	'Ex%od%e',
		'Lev' =>	'L[ée]v%it%ique',
		'Num' =>	'Nomb%res',
		'Deut' =>	'Deut%[ée]r%onome',
		'Josh' =>	'Jos%u[ée]',
		'Judg' =>	'Jug%es',
		'Ruth' =>	'Ruth',
		'1Sam' =>	'1[ -]?Sam%uel',
		'2Sam' =>	'2[ -]?Sam%uel',
		'1Kgs' =>	'1[ -]?R%ois',
		'2Kgs' =>	'2[ -]?R%ois',
		'1Chr' =>	'1[ -]?Ch%r%on%iques',
		'2Chr' =>	'2[ -]?Ch%r%on%iques',
		'Ezra' =>	'Esd%r%as',
		'Neh' =>	'N[ée]h%[ée]mie',
		'Esth' =>	'Esth%er',
		'Job' =>	'Job',
		'Ps' =>		'Ps%aume',
		'Prov' =>	'Prov%erbes',
		'Eccl' =>	'Eccl%[ée]siaste',
		'Song' =>	'Cant%ique des Cantiques',
		'Isa' =>	'(?:És\b\.?|[ÉE]sa[ïi]e\b)',		# Bug de Perl ? Ne fonctionne pas
#		'isa' =>	'[ÉE]sa[ïi]e',
#		'isa' =>	'(?:\bÉs\.)',
		'Jer' =>	'J[ée]r%[ée]mie',
		'Lam' =>	'Lam%entations de J[ée]r[ée]mie',
		'Ezek' =>	'[ÉE]z%[ée]ch%iel',
		'Dan' =>	'Dan%iel',
		'Hos' =>	'Os%[ée]e',
		'Joel' =>	'Jo[ëe]l',
		'Amos' =>	'Am%os',
		'Obad' =>	'Abd%ias',
		'Jonah' =>	'Jon%as',
		'Mic' =>	'Mich%[ée]e',
		'Nah' =>	'Nah%um',
		'Hab' =>	'Hab%akuk',
		'Zeph' =>	'Soph%onie',
		'Hag' =>	'Agg%[ée]e',
		'Zech' =>	'Zach%arie',
		'Mal' =>	'Mal%achie',
		'Matt' =>	'Matt%hieu',
		'Mark' =>	'Marc',
		'Luke' =>	'Luc',
		'John' =>	'(?<![123][ -])Jean',
		'Acts' =>	'Actes',
		'Rom' =>	'Rom%ains',
		'1Cor' =>	'1[ -]?Cor%inthiens',
		'2Cor' =>	'2[ -]?Cor%inthiens',
		'Gal' =>	'Gal%ates',
		'Eph' =>	'[ÉE]ph%[ée]siens',
		'Phil' =>	'Phil%ippiens',
		'Col' =>	'Col%ossiens',
		'1Thess' =>	'1[ -]?Thess%aloniciens',
		'2Thess' =>	'2[ -]?Thess%aloniciens',
		'1Tim' =>	'1[ -]?Tim%oth[ée]e',
		'2Tim' =>	'2[ -]?Tim%oth[ée]e',
		'Titus' =>	'Tite',
		'Phlm' =>	'Phil%[ée]mon',
		'Heb' =>	'H[ée]b%r%eux',
		'Jas' =>	'Jacq%ues',
		'1Pet' =>	'1[ -]?P%ierre',
		'2Pet' =>	'2[ -]?P%ierre',
		'1John' =>	'1[ -]?J%ean',
		'2John' =>	'2[ -]?J%ean',
		'3John' =>	'3[ -]?J%ean',
		'Jude' =>	'Jude',
		'Rev' =>	'Apoc%alypse'
	); 

	# Recompile chaque texte pour rendre la partie après le % facultative
	my $k;
	foreach $k (keys %bookpatt) {
		
		# Marque la fin textuelle du mot
		$bookpatt{$k} =~ s/(\w)$/$1\\b/;

		# Tant qu'il y a un pourcent
		if( $bookpatt{$k} =~ /\%/ ) {
			while ( $bookpatt{$k} =~ /\%/ ) {
				# Rends ce qui suit facultatif   Gen%èse -> Gen(?:\b\.?|èse\b)
				$bookpatt{$k} =~ s/^(.+)\%(.+)$/$1(?:\\b\\.?|$2)/;
				#print $bookpatt{$k}, "\n";
			}	
		}
		
		# Marque le début du mot
		$bookpatt{$k} =~ s/^(.)/\\b$1/;	

		#print "$k => ", $bookpatt{$k}, "\n";
	}  
	
	$bookregex = '(?:'.join(')|(?:',values %bookpatt).')';

	#print "bookregex = $bookregex\n";
}

#%rom2ara = (
#	'XXXVII'	=>  37,
#);

#############################################################################################################################
# Fonction de reconnaissance
# Il faut matcher de la façon suivante: 
# $txt =~ s/($bibleref::bookregex)(?:[\s:-](\d+|[IVXLC]+)(?:(?:\s*v\.?|[\.,;\:])\s*(\d+))?)?/'<ref id="'.bibleref::txt2ref($1,$2,$3).'">'.$MATCH.'<\/ref>'/gie;
#		$MATCH est une référence à txt2ref($1,$2,$3);
#	1: Nom du livre
#	2: Chapitre (nombres romains ou arabes)
#	3: Verset

sub txt2ref($$$) {
	
	my ($res, $k);
	my $livre = $_[0];
	my $chap = $_[1];
	my $vers = $_[2];

	#print STDERR "livre[$livre] chap[$chap] vers[$vers]\n";

	# Est-ce que le nom du livre est déjà OSIS ?
	if( defined($bookpatt{$livre}) ) {
		$res = $livre;

	# Recherche le nom du livre
	} else {
		foreach $k (keys %bookpatt) {
			if( $livre =~ m/$bookpatt{$k}/i ) {
				$res = $k;
				last;
			}
		}
	}

	# Recherche le chapitre
	if( defined $chap ) {
	
		# Ces livres n'ont qu'un seul chapitre
		if( $res =~ /^Obad|Phlm|2John|3John|Jude$/ ) {
		
			# On a des chiffres, c'est le verset
			if( $chap =~ /\d/ ) {
				$vers = $chap

			# On a confondu 'v.' pour verset avec un n° de chapitre
			} elsif( $chap =~ /^v$/i ) {
				
			# Ceci est impossible, on abandonne la suite
			} else {
				return $res;
			}

			$chap = 1;
			
		# Nom du livre écrit en Romains
		} elsif( $chap =~ m/[IVXLC]/i ) {
			#if( exists $rom2ara{$chap} ) {
			#	$chap = $rom2ara{$chap};
			#} else {
			#	die "%rom2ara ne reconnait pas \"$chap\"\n"; 
			#}
			$chap = arabic($chap);
		}

		$res .= '.' . $chap;
	}
	
	# Recherche le verset
	if( defined $vers ) {
		$res .= '.' . $vers;
	}

	return $res;
}
