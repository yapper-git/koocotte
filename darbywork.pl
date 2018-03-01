#!/usr/bin/perl -w
#
# Transforme le texte xhtml en un corps de document au format OSIS, l'enrobage est à faire indépendement.
#
# Sébastien Koechlin
# $Id: darbywork.pl,v 1.33 2013-08-22 10:13:47 seb Exp $
#

#use encoding "UTF-8",STDIN => 'UTF-8',STDOUT => 'UTF-8';	
	# Le code est écrit en UTF-8
use utf8;
#use locale;
#use utf8;
use strict;		# On n'écrit pas comme un porc
use warnings;		#   du quebec
use XML::Parser;	# Parser pour le xhtml
use Data::Dumper;	# Stringify perl data structures
use English;		# Explicit variables names
use File::Basename;	# basename and dirname

use bibleref;		# Reconnaissance des références bibliques

$OUTPUT_AUTOFLUSH = 1;	# Unbuffered ouput
my $TTY = 0;		# Output on tty, color

my %book = (		# Référentiel OSIS des noms de livre
	'LE PREMIER LIVRE DE MOÏSE dit LA GENÈSE' => 'Gen',
	'LE SECOND LIVRE DE MOÏSE DIT L'."'".'EXODE' => 'Exod',
	'Le TROISIÈME LIVRE de MOÏSE dit le LÉVITIQUE' => 'Lev',
	'Le QUATRIÈME LIVRE de MOÏSE dit les NOMBRES' => 'Num',
	'Le CINQUIÈME LIVRE de MOÏSE dit le DEUTÉRONOME' => 'Deut',
	'LE LIVRE DE JOSUÉ' => 'Josh',
	'LE LIVRE DES JUGES' => 'Judg',
	'RUTH' => 'Ruth',
	'LE PREMIER LIVRE DE SAMUEL' => '1Sam',
	'LE SECOND LIVRE DE SAMUEL' => '2Sam',
	'LE PREMIER LIVRE DES ROIS' => '1Kgs',
	'LE SECOND LIVRE DES ROIS' => '2Kgs',
	'LE PREMIER LIVRE DES CHRONIQUES' => '1Chr',
	'LE SECOND LIVRE DES CHRONIQUES' => '2Chr',
	'ESDRAS' => 'Ezra',
	'NÉHÉMIE' => 'Neh',
	'ESTHER' => 'Esth',
	'LE LIVRE DE JOB' => 'Job',
	'LES PSAUMES' => 'Ps',
	'LES PROVERBES' => 'Prov',
	'Le PRÉDICATEUR connu sous le nom de L'."'".'ECCLÉSIASTE' => 'Eccl',
	'LE CANTIQUE DES CANTIQUES' => 'Song',
	'LE LIVRE DU PROPHÈTE ÉSAÏE' => 'Isa',
	'LE LIVRE DU PROPHÈTE JÉRÉMIE' => 'Jer',
	'Les LAMENTATIONS de JÉRÉMIE' => 'Lam',
	'Le Livre du Prophète ÉZÉCHIEL' => 'Ezek',
	'Le LIVRE du PROPHÈTE DANIEL' => 'Dan',
	'Le LIVRE des PETITS PROPHÈTES OSÉE' => 'Hos',
	'JOËL' => 'Joel',
	'AMOS' => 'Amos',
	'ABDIAS' => 'Obad',
	'JONAS' => 'Jonah',
	'MICHÉE' => 'Mic',
	'NAHUM' => 'Nah',
	'HABAKUK' => 'Hab',
	'SOPHONIE' => 'Zeph',
	'AGGÉE' => 'Hag',
	'ZACHARIE' => 'Zech',
	'MALACHIE' => 'Mal',
	'Évangile selon MATTHIEU' => 'Matt',
	'Évangile selon MARC' => 'Mark',
	'Évangile selon LUC' => 'Luke',
	'Évangile selon JEAN' => 'John',
	'ACTES DES APÔTRES' => 'Acts',
	'Épître aux ROMAINS' => 'Rom',
	'Première Épître aux CORINTHIENS' => '1Cor',
	'Seconde Épître aux CORINTHIENS' => '2Cor',
	'Épître aux GALATES' => 'Gal',
	'Épître aux ÉPHÉSIENS' => 'Eph',
	'Épître aux PHILIPPIENS' => 'Phil',
	'Épître aux COLOSSIENS' => 'Col',
	'Première Épître aux THESSALONICIENS' => '1Thess',
	'Seconde Épître aux THESSALONICIENS' => '2Thess',
	'Première Épître à TIMOTHÉE' => '1Tim',
	'Seconde Épître à TIMOTHÉE' => '2Tim',
	'Épître à TITE' => 'Titus',
	'Épître à PHILÉMON' => 'Phlm',
	'Épître aux HÉBREUX' => 'Heb',
	'Épître de JACQUES' => 'Jas',
	'Première Épître de PIERRE' => '1Pet',
	'Seconde Épître de PIERRE' => '2Pet',
	'Première Épître de JEAN' => '1John',
	'Deuxième Épître de JEAN' => '2John',
	'Troisième Épître de JEAN' => '3John',
	'Épître de JUDE' => 'Jude',
	'APOCALYPSE' => 'Rev',
);

my @book = (		# Ordre des livres 
	'Gen', 'Exod', 'Lev', 'Num', 'Deut', 'Josh', 'Judg', 'Ruth', '1Sam', '2Sam', '1Kgs', '2Kgs', '1Chr', '2Chr',
	'Ezra', 'Neh', 'Esth', 'Job', 'Ps', 'Prov', 'Eccl', 'Song', 'Isa', 'Jer', 'Lam', 'Ezek', 'Dan', 'Hos', 'Joel',
	'Amos', 'Obad', 'Jonah', 'Mic', 'Nah', 'Hab', 'Zeph', 'Hag', 'Zech', 'Mal', 'Matt', 'Mark', 'Luke', 'John',
	'Acts', 'Rom', '1Cor', '2Cor', 'Gal', 'Eph', 'Phil', 'Col', '1Thess', '2Thess', '1Tim', '2Tim', 'Titus',
	'Phlm', 'Heb', 'Jas', '1Pet', '2Pet', '1John', '2John', '3John', 'Jude', 'Rev',
);


#############################################################################################################################
# Escape & < et >
sub escape($) {
	my $t = $_[0];	# Parametre
	$t =~ s/&/&amp;/g;
	$t =~ s/</&lt;/g;
	$t =~ s/>/&gt;/g;
	return $t;
}

#####################################################################################
# Escape & < > ' et "
sub escapeAttr($) {
	my $t = escape( $_[0] );
	$t =~ s/\'/&apos;/g;
	$t =~ s/\"/&quot;/g;
	return $t;
}

#####################################################################################
# Normalise le texte
sub normalize($) {
	my $n = $_[0];
	$n =~ s/^\s+//s;
	$n =~ s/\s+$//s;
	$n =~ s/\s+/ /gs;
	return $n;
}

#####################################################################################
# Supprime le balisage
sub unmarkup($) {
	my $n = $_[0];
	$n =~ s/<\/?hi.*?>/\//g;
	$n =~ s/<\w.*?>/{/g;
	$n =~ s/<\/.*?>/}/g;
	$n =~ s/\s+/ /g;
	$n =~ s/^\s+//g;
	$n =~ s/\s+$//g;
	return $n;
}

#####################################################################################
# Variables

my $bookID;		# osisID du livre courant
my $chapterID;		# osisID du chapitre courant
my $verseID;		# osisID du verset en cours d'analyse

my $chapterNB;		# Numéro du chapitre courant
my $verseNB;		# Numéro du verset courant
my $noteNB;		# Numéro de la note (a..z aa..az)

my $ptype;		# Type de paragraphe <p> ou <lg>

my $testament;		# Id du testament
my $path;		# Type de paragraphe en cours
my $basepath;		# Nom de base des fonctions

my $in_a_name = '';	# Indique le dernier a_name rencontré

my $mark_endp;		# Marque de fin de paragraphe
my $mark_poetic;	# Marque que l'on est dans un vers de poème
my $mark_ptype;		# Marque que l'on est dans un poème ou non

my $alinea;

#my $in_book;		# Un livre est ouvert
#my $in_chapter;	# Un chapitre est ouvert
#my $in_verse;		# Un verset est ouvert

#####################################################################################
# Crée une ligne de log de titre
my $ESC_NORM =  ( $TTY ? "\033[0m" : "" );
my $ESC_GRAS =  ( $TTY ? "\033[1m" : "" );
my $ESC_OFF =   ( $TTY ? "\033[30;0m": "" );
my $ESC_VERSE = ( $TTY ? "\033[33m": "" );
my $ESC_CIT =   ( $TTY ? "\033[34m": "" );

# Log de premier niveau
sub log1($) {
	print $ESC_GRAS, $_[0], $ESC_NORM, "\n";
}

# Log de second niveau	1:Texte 2:Citation
sub log2b($$) {
	print "  (", $ESC_VERSE, $verseID, '	', osis2brach($verseID), $ESC_OFF, ")",substr(' 'x12,0,(12-length($verseID))), 
		$_[0]," \"",$ESC_CIT,$_[1],$ESC_OFF,"\"\n";
}

# Log de second niveau	1:Texte
sub log2($) {
	print "  (", $ESC_VERSE, $verseID, '    ', osis2brach($verseID), $ESC_OFF, ")",substr(' 'x12,0,(12-length($verseID))), $_[0],"\n";
}

# Convertion d'une référence OSIS à une référence du document original (at##_##)
sub osis2brach($) {
	my $book = $_[0];	$book =~ s/^(\w+)\..*$/$1/;
	my $chap = $_[0];	$chap =~ s/^\w+\.(\d+)\..*$/$1/;
	my $i;

	# Recherche $book dans le tableau des livres
	for( $i=1; $i <= 66; $i++ ) {	last if( $book[$i-1] eq $book ); }
	
	# Livre non trouvé
	if( $i > 66 ) {
		return 'inconnue';
	
	# Psaumes
	} elsif( $i == 19 ) {

		# Psaumes 1-41
		if( $chap < 42 ) {	return 'at19_1_' . sprintf('%.2i',$chap);	}
	
		# Psaumes 42-72
		elsif( $chap < 73 ) {	return 'at19_2_' . sprintf('%.2i',$chap);	}
	
		# Psaumes 73-89
		elsif( $chap < 90 ) {	return 'at19_3_' . sprintf('%.2i',$chap);	}
	
		# Psaumes 90-106
		elsif( $chap < 107 ) {	return 'at19_4_' . sprintf('%.3i',$chap);	}
	
		# Psaumes 107-150
		else {			return 'at19_5_' . sprintf('%.3i',$chap);	}
	
	# Nouveau testament
	} elsif( $i > 39 ) {
		return 'nt' . (sprintf('%.2i',$i-39)) . '_' . sprintf('%.2i',$chap);
	
	# Ancien testament
	} else {
		return 'at' . sprintf('%.2i',$i) . '_' . sprintf('%.2i',$chap);
	}
}

#####################################################################################
# Callbacks du parser
#####################################################################################

###########################################################################
# This event is generated when non-markup is recognized.
#   (Expat, String)
#
#	$xml_capt = 0	Warning if text
#	          = 1	Append text in $xml_txt
#	          = 2	Drop content
#		  = 3	Warning if text, &#160; => New <p>
#

my $xml_txt;		# Texte capturé
my $xml_capt = 0;	# '0' -> nothing '1' -> Capture '2' -> Drop '3' -> Récupère les espaces insécables (saut de parag)
sub xml_char() {

	my $t = $_[1];
	#print STDERR "DEBUG: txt($xml_capt) \"", normalize($t), "\"\n";

	# On ne doit pas avoir de contenu
	if( $xml_capt == 0 and $t !~ /^\s*$/ ) {
		&log2b("Texte ignoré",$t);
	}

	# On récupère le contenu
	elsif( $xml_capt == 1 ) {
		$xml_txt .= $t;
	}
	
	# On ne doit pas avoir de contenu (sauf espaces insécables)
	elsif( $xml_capt == 3 ) {

		# Il ne doit pas y avoir de texte
		if( $t !~ /^\s*$/ ) {
			&log2b('Texte ignoré',$t);
		}
	
		# Recherche d'un espace insécable
		#if( $t =~ m/\x{00A0}/ ) {
		if( index( $t, pack('U',0x00a0) ) >= 0 ) {
			#log2("  PARAGRAPHE");
			$mark_endp = 1;		# On pensera a changer de <p> au plus vite
			#osis_end_p();
			#osis_start_p();
		}
	}
	
	# Texte ignoré
}



###########################################################################
# This is called just before the parsing of the document starts.
#   (Expat)
sub xml_init() { 

	$xml_capt	= 0;
	$xml_txt	= '';
	
	$verseID	= 'HEADER';
	$chapterID	= '';
	$bookID		= '';
	
	$chapterNB	= 0;
	$verseNB	= 0;
	$noteNB		= 'a';
	$ptype	=	 'p';
	
	$path		= '';

	$mark_endp	= 0;
	$mark_poetic	= 0;	
	
	$alinea		= undef;
	
	#$in_book	= '';
	#$in_chapter	= '';
	#$in_verse	= '';
}

###########################################################################
# This is called just after parsing has finished, but only if no errors occurred during the parse. Parse returns what this returns.
#   (Expat)
sub xml_final() { 

	if ( defined $alinea ) {
		die "  \$alinea non null à la fin du document (il n'a pas été imprimé)\n";
	}
}

###########################################################################
# Called on external entities
#	(Expat, Base, Sysid, Pubid)
sub xml_externEnt() {
	my( $e, $b, $sysid, $p ) = (@_);
	my( $file, $hdl );

	# Get filename
	$file = 'dtd/'.basename($sysid);
	if ( -e $file) {
		open( $hdl, $file ) or die( "Erreur a la lecture de \"$file\":$!\n" );
		return $hdl;
	} else {
		&log1("EXTERNAL ENTITY: base: $b, sysid: $sysid, pubid: $p");
		return undef;
	}
}


###########################################################################
# This event is generated when an XML start tag is recognized.
#   (Expat, Element [, Attr, Val [,...]])
sub xml_start() {

	# Crée un hash des attributs
	my( $attrNB, $element, %attr ) = (@_);
	$attrNB = scalar(keys(%attr));
	
	#print STDERR "DEBUG: ", "<", $_[1], " ", Dumper(\%attr), ">\n";
	
	# Balise <div class='WordSection1'>
	if( $element eq 'div' and $attr{'class'} eq 'WordSection1' and $attrNB == 1 ) {	
		# Début de l'analyse
		&log1("Debut du document");
	}
	
	# Balise <p class='??' align='??'>
	elsif( $element eq 'p' ) {

		# Il est interdit d'imbriquer des <p>
		if( $path ne '' ) {
			die "Entrée dans un <p> alors que l'on est déjà dans $path\n";
		}

		# Calcul le nom de la fonction
		$path = 'p_c';
	
		# Ajoute la classe
		my $c = (exists $attr{'class'} ? $attr{'class'} : 'none' );
		$c =~ s/\W//;
		$path .= $c;
		
		# Ajoute l'alignement
		if ( exists $attr{'align'} ) {
			$c = $attr{'align'};
			$c =~ s/\W//;
			$path .= '_' . $c;
		}
		
		# Fait l'appel à la sortie plutot
		#{
		#	no strict 'refs';
		#	$c = $basepath . 'start_' . $path;
		#	&$c();
		#}
		
		# Capture le contenu
		$xml_capt = 1;	# Lance la capture
		$xml_txt  = '';	# Part d'un buffer vide

	}
	
	# Balises de contenu
	elsif( $element eq 'b' or $element eq 'i' ) {

		# Ces éléments sont obligatoirement dans un <p>
		if( $path eq '' ) { 
			die "  ($verseID) <$element> Rencontré en dehors d'un <p>\n"; 
		} 
		
		# Appel à la fonction correspondante
		{
			no strict 'refs';
			my $c = $basepath . 'start_' . $element;
			&$c();
		}
	}

	elsif( $element eq 'a' and exists $attr{'name'}) {

		# Ces éléments sont obligatoirement dans un <p>
		if( $path eq '' ) { 
			die "  ($verseID) <$element> Rencontré en dehors d'un <p>\n"; 
		} 

		# Appel à la fonction correspondante
		{
			no strict 'refs';
			my $c = $basepath . 'start_a_name';
			&$c( $attr{'name'} );
		}
	}

	elsif( $element eq 'a' ) {

		# Ces éléments sont obligatoirement dans un <p>
		if( $path eq '' ) { 
			die "  ($verseID) <$element> Rencontré en dehors d'un <p>\n"; 
		} 

		# Appel à la fonction correspondante
		{
			no strict 'refs';
			my $c = $basepath . 'start_a';
			&$c();
		}
	}

	# Balises ignorées
	elsif( $element eq 'html' ) {}
	elsif( $element eq 'head' ) {}
	elsif( $element eq 'meta' ) {}
	elsif( $element eq 'link' ) {}
	elsif( $element eq 'title' ) {}
	elsif( $element eq 'body' ) {}
	elsif( $element eq 'br' ) {}
	
	# Balises inconnues
	else {
		die "($verseID) Balise ouvrante inconnue: \"" . $element . "\" (" . Dumper(\%attr) . ")\n";
	}
}

###########################################################################
# This event is generated when an XML end tag is recognized.
#   (Expat, Element)
sub xml_end() { 

	my $element = $_[1];
	#print STDERR "DEBUG: txt=\"" . $xml_txt . "\"\n" if ($xml_capt == 1 );

	# Sortie de balise <div>
	if( $element eq 'div' ) {
		&log1("Fin du document");
	}

	# Sortie de balise <p>
	elsif( $element eq 'p' ) {
		# Fait l'appel à la fonction de sortie
		{
			no strict 'refs';
			my $c = $basepath . 'end_' . $path;
			&$c();
		}
		$path = '';
	}

	# Balises de contenu
	elsif( $element eq 'b' or $element eq 'i' or $element eq 'a' ) {
		
		# Appel à la fonction correspondante
		{
			no strict 'refs';
			my $c = $basepath . 'end_' . $element;
			&$c();
		}
	}

	# Balises ignorées
	elsif( $element eq 'html' )  {}
	elsif( $element eq 'head' )  {}
	elsif( $element eq 'meta' )  {}
	elsif( $element eq 'link' )  {}
	elsif( $element eq 'title' ) {}
	elsif( $element eq 'body' )  {}
	elsif( $element eq 'br' )    {}	# Toujours vide

	# Balises inconnues
	else {
		die "Balise fermante inconnue: \"" . $element . "\"\n";
		# Normalement impossible puisqu'on aurait du la voir s'ouvrir
	}
}

#############################################################################################################################
#############################################################################################################################
#############################################################################################################################

# Fichier à traiter
my $infile = shift;	# Fichier en entrée
my $outfile = shift;	# Fichier en sortie

my %notes;		# Dictionnaire des notes
my $parser =		# Parser XML
	new XML::Parser(Handlers => {
		Init	=> \&xml_init,
		Final	=> \&xml_final,
		Start   => \&xml_start,
		End     => \&xml_end,
		Char    => \&xml_char,
		ExternEnt => \&xml_externEnt,
		}, ParseParamEnt => 1)
	or die "Impossible d'initialiser le parser: $!\n";
	
# Parse une première fois pour les notes
&log1("### Premiere analyse: collecte des notes ###");
$basepath = 'parsenotes_';
$parser->parsefile( $infile );
&log1("Il y a ". scalar keys(%notes). " notes");

#exit 1;

# Parse une seconde fois le fichier pour le texte
&log1("### Seconde analyse: production du document ###");

# Ouvre le fichier
open OUTFILE, ">$outfile" or die "Can not write into $outfile\n";
binmode(OUTFILE,':encoding(utf8)');	# Problème avec l'UTF-8 ??
$basepath = 'parsebible_';

# Génère l'entête
print OUTFILE "<?xml version='1.0' encoding='UTF-8'?>\n<fakeroot xmlns='http://www.bibletechnologies.net/2003/OSIS/namespace'>\n";
$parser->parsefile( $infile );

# Termine le fichier
&osis_end_verse();
&osis_end_p();
&osis_end_chapter();
&osis_end_book();
print OUTFILE "</fakeroot>\n\n";

# Ferme le ficher
close OUTFILE;

# Notes qu'il n'a pas été possible de placer
if ( scalar(keys %notes) > 0 ) {

	my $v;
	&log1("### Impossible de placer les commentaires suivants ###");

	foreach $v (sort(keys(%notes))) {
		$verseID=$v;
		log2b('*', unmarkup($notes{$verseID}) );
	}
}

exit 0;

#####################################################################################
# Autres fonctions
#####################################################################################

#####################################################################################
# Create a note
#	$0: $p_chap		BookID
#	$1: $p_vers		verse
#	$2: $p_stars		sub-verse
#	$3: $p_note		text
#	$4: $p_autocorrect	0 => fixed 1 => chapter autocorrection (généralement 1 sauf exception)
# La note est placées dans le hashage  %notes avec la clef 

sub create_note($$$$$) {
	my $p_chap = $_[0];		# Chapitre détecté (osisID)
	my $p_vers = $_[1];		# Verset détecté
	my $p_stars= $_[2];		# Etoiles trouvées
	my $p_note = $_[3];		# Contenu de la note
	my $p_autocorrect = $_[4];	# Autocorrection de la référence ?

	# La référence osisID du livre n'est pas correcte
	unless( $p_chap =~ /^\w+\.\d+$/ ) {
		die "  ($verseID) Note avec référence invalide: \"$p_chap\"\n";
	}
	
	# Le verset n'est pas numérique
	unless( $p_vers =~ /^\d+$/ ) {
		die "  ($verseID) Note avec référence invalide: \"$p_chap.$p_vers\"\n";
	}
	
	# le plus long fait 4 étoiles
	$p_stars = '*' if ( length($p_stars) < 1 );
	
	# Numéro de verset postérieur au verset courant
	if( $p_vers > $verseNB and $p_autocorrect ) { 
		# On est au début d'un chapitre -> on change pour le chapitre précédent
		my ($b, $c);
		$p_chap =~ m/^(\w+)\.(\d+)$/ or die "Impossible de parser le chapitre";
		$b = $1;
		$c = $2;
		if ($c > 1 and $p_vers >= 12 and $verseNB <= 10 and ($verseNB + 4) < $p_vers) {
			$p_chap = $b . '.' . ($c-1);
			log2("Correction: note pour le verset $p_vers alors qu'on est en $verseNB considéré comme $p_chap");
		} else {
			log2("Note pour le verset $p_vers alors qu'on est en $verseNB (pas de correction du chapitre)");
		}
	}
	
	# On enregistre le nombre d'étoile plutot que les étoiles elles-mêmes
	my $num = length($p_stars);
	my $key = $p_chap . '.' . $p_vers . '_' . $num;

	#print STDERR "DEBUG: note sur ".$book_chap.".".$vers.": ".$note."\n";
	if( exists $notes{$key} ) {
		if( $notes{$key} ne $p_note ) {
			log2("Il existe déjà une note pour la référence $key !\n\t- ".
				unmarkup($notes{$key})."\n\t- ".unmarkup($p_note));
		} else {
			log2("La note de $key est présente deux fois");
		}
	}
	
	# Ajoute la note au référentiel
	$notes{ $key } = $p_note;

	# Il ne doit plus rester de séparateur de notes
	log2b("Il reste un \x{2014} dans la note",unmarkup($p_note)) if ( $p_note =~ /\x{2014}/ );
}


#####################################################################################
# Balise une note avec ce qui va bien
#
#	$0: $txt	Texte de la note
#	$1: $id		Reference de la note (Gen.1.1_1)
#	retour		Note balisée

sub markup_note($$) {

	my $txt = $_[0];
	my $id = $_[1];
	
	# Calcul du verset concerné
	my $ref = $id;
	$ref =~ s/^(\w+\.\d+\.\d+)_.*$/$1/ or die "Impossible de récupérer la référence dans \"$ref\"";

	# Balisage de la note	
	my $txt_balise = '<note osisRef="'.$ref.'" osisID="'.$id.'" n="'.$noteNB.'"';
	
	# Est-ce une référence ?
	if( $txt =~ /<reference/ ) {
		$txt_balise .= ' type="crossReference"';
	}
	
	$txt_balise .= '>'.$txt.'</note>';
	
	#osis_comment('note ', $noteNB, ' on ', $id);
	# N'incrémente pas, dans un verset multiligne, cette fct est appelé plusieurs fois
	#inc_noteNB();

	return $txt_balise; 
}


#####################################################################################
# Ajoute les balises permettant de marquer les références
#
#	$0: $txt	Texte de la note
#	$1: $id		Reference du verset (Gen.1.1)
#	retour		Note avec les renvois marqués par les balises OSIS

sub find_references($$) {

	my $txt = $_[0];
	my $id = $_[1];
	
	# Livre concerné
	my $book = $id;
	$book =~ s/^(\w+)\.\d.*$/$1/ or die "Impossible de récupérer le livre dans \"$book\"";
	
	# Cherche les références complète (livre chapitre:verset ou livre chapitre)
	$txt =~ s/($bibleref::bookregex)[\s:-](\d+|[IVXLC]+)(?:(?:\s*v\.?|[\.,;\:])\s*(\d+))?/'<reference osisRef="'.&bibleref::txt2ref($1,$2,$3).'">'.$MATCH.'<\/reference>'/gie

	# Cherche les références relatives au livre courant (chapitre:verset)
	or $txt =~ s/\b(\d+|[IVXLC]+)\:(\d+)\b/'<reference osisRef="'.&bibleref::txt2ref($book,$1,$2).'">'.$MATCH.'<\/reference>'/ge;
	
	# Logs
	#log2b( "Référence trouvée", unmarkup($txt) ) if( $_[0] ne $txt );
	
	return $txt;
}


#####################################################################################
# Début d'un chapitre
#
#	Controle la cohérence de l'enchainement des chapitres et mets à jours 
#	$chapterNB et $chapterID, ainsi que $verseNB à 0 et $noteNB à 'a'
#
#	$0: $newNB		Nouveau numéro de chapitre 	

sub check_newchapter($) {

	my $newNB = $_[0];
		
	# Test de retour en arrière
	if( $newNB <= $chapterNB ) {
		log2("Le chapitre $newNB fait suite au chapitre $chapterNB");
		die "Fatal\n";
	}

	# Test d'enchainement
	if( $newNB != $chapterNB + 1 ) {
		&log2("Le chapitre $newNB fait suite au chapitre $chapterNB");
	}

	# Nouvelle position
	$chapterNB = $newNB;
	$chapterID = $bookID . '.' . $chapterNB;
	$verseNB   = 0;
	$noteNB    = 'a';
}

# Incrémente le numéro de note
sub inc_noteNB() {

	# Test le dépassement
	if( $noteNB eq 'az' ) {
		die "Plus de 55 notes dans le chapitre $verseID";

	} elsif ( $noteNB =~ /^a(.)$/ ) {
		$noteNB = 'a'. chr( ord($1) + 1 );
		#log2b( "Note n° ", $noteNB );
	
	} elsif ( $noteNB eq 'z' ) {
		$noteNB = 'aa';
		#log2b( "Note n° ", $noteNB );
	
	} else {
		$noteNB = chr( ord($noteNB) + 1 );
	}
}	

#####################################################################################
# Affiche du texte d'un verset, avec les notes insérées et l'éventuel alinéa
#
#	Extrait les notes du hash %notes
#
#	$0: $txt	Texte du verset; les notes sont marquées avec des
#			étoiles, on espère qu'elles servent toute à cela

sub print_with_notes($) {

	my $txt = $_[0];	# Paramêtre
	my $i;			# Itérateur
	my $nid;		# Identifiant de la note
	my $ntxt;		# Contenu de la note
	my $w;			# mot trouvé associé à la note

	# Italique dans le NT -> Renvoi vers un passage
	if( ($testament eq 'NT') and ($txt =~ m/<hi/) ) {

		# Pour chacun
		$i = 1;
		while( $txt =~ /<hi/ ) {
			# Texte
			#log2b( "Italique initial:",$txt);
			$txt =~ s/<hi type="italic">(.*?)<\/hi>/‡/s;
			$ntxt = $1;
			$ntxt =~ s/[\n\[\]]//g;	# Supprime les crochets
			$ntxt =~ s/\s+/ /g;
			#log2b( "Italique texte:",$txt);
			#log2b( "Italique note:",$ntxt);

			# On marque les renvois
			$ntxt =~ s/($bibleref::bookregex)(?:[\s:-](\d+|[IVXLC]+)(?:(?:\s*v\.?|[\.,;\:])\s*(\d+))?)?/'<reference osisRef="'.&bibleref::txt2ref($1,$2,$3).'">'.$MATCH.'<\/reference>'/gies;
			#log2b("Italique renvois",$ntxt);

			# Replace la note dans le texte
			$ntxt = markup_note( $ntxt, $verseID.'_r'.$i );
			$txt =~ s/‡/$ntxt/;
			inc_noteNB();
			#log2b("Italique final:",$txt);
			$i++;
		}
		#log2b( "Référence", unmarkup($txt) );
	}

	# Recherche toutes les notes du verset
	for( $i=0; $i<6; $i++ ) {
		$nid = $verseID . '_' . $i;
		
		# Il y a une note
		if( exists( $notes{$nid} ) ) {
			
			# Substitution
			$ntxt = expand_notes( $notes{$nid} );		# Supprime les raccourcis
			$ntxt = find_references( $ntxt, $verseID );	# Recherche des références
			$ntxt = markup_note( $ntxt, $nid );		# Ajoute les balises
			
			#log2b("VersetA", unmarkup($txt)) if ($verseID eq 'Gen.17.15');
			
			# La note est trouvée
			if( $txt =~ s/\b(\w+)\*{$i}(?!\*)/$1$ntxt/ ) {

				$w = $1;
				$w =~ s/[^a-zA-Z]/[^\*]/g;	# Sinon perl explose :(
				delete $notes{$nid};
				inc_noteNB();
				#log2b("Note insérée sur", $w);
				#log2b("VersetB ($w)", unmarkup($txt)) if ($verseID eq 'Gen.17.15');

				# Si le même mot est ré-utilisé
				if( $txt =~ s/\b($w)\*{$i}(?!\*)/$1$ntxt/g ) {
					#log2b( "Plusieurs fois le même mot avec la même note:", unmarkup($txt) );
				}
			
				#log2b("VersetC ($w)", unmarkup($txt)) if ($verseID eq 'Gen.17.15');
				# Si la note est utilisé plusieurs fois
				if( $txt =~ s/\b(\w+)\*{$i}(?!\*)/$1$ntxt/ ) {
					log2b( "La même note ($i:".unmarkup($ntxt).") est ajouté plusieurs fois sur des mots différents:", unmarkup($txt) );
				}
				#log2b("VersetD", unmarkup($txt)) if ($verseID eq 'Gen.17.15');

			# La note n'est pas à la suite d'un mot
			} elsif( $txt =~ s/(?<!\*)\*{$i}(?!\*)/$ntxt/ ) {
				#log2b("Note ". ('*' x $i) ." sans mot:", unmarkup($txt));
				delete $notes{$nid};
				inc_noteNB();
				
			# La note n'est pas trouvée
			#} else { # En fait le verset peut être sur plusieurs lignes
			#	log2b("Impossible d'insérer la note de référence $nid",$ntxt);
			}
		}
	}

	# Début d'une ligne de poème
	if( $mark_poetic > 0 ) {
		print OUTFILE '<l>';
	}

	# Alinéa
	if( defined $alinea ) {
		&$alinea();
		$alinea = undef;
	}

	# Le texte
	print OUTFILE $txt;

	# Fin de ligne de poème
	if( $mark_poetic > 0 ) {
		print OUTFILE '</l>';
	}
	
	# Il ne doit plus rester d'étoiles
	$txt =~ s/<note.*?<\/note>/\x{2022}/g;
	if( $txt =~ /\*(?!dieu)/ ) {	#$txt =~ /\*(?!<divineName)/ 
		log2b("Il reste des étoiles dans",unmarkup($txt));
	}
	
}

#####################################################################################
#  Transforme les signes et abréviations du texte
#  Marque les renvois (A FAIRE TODO)
#  Ajoute le balisage des notes (A FAIRE TODO)
#
#	Retrouve les références des versets
#	A.C.	Avant Jésus-Christ
#	aj.	ajoute, ajoutent
#	chald.	chaldéen
#	comp.	comparez
#	env.	environ
#	hébr.	hébreu
#	litt.	littéralement
#	om.	omet, omettent
#	ordin.	traduit d'ordinaire
#	pl.	plusieurs, plusieurs lisent
#	qqs.	quelques-uns, selon quelques-uns
#	vers.	verset
#	LXX	version grec dite des "Septante"
#	R.	texte des Elzévirs de 1633 ou "texte reçu"
#
#	Dieu (Élohim)
#	*Dieu (Éloah)
#	+Dieu (El)
#	*Seigneur (Jéhovah, uniquement NT)
#
#	$0: $txt	Texte
#	out		Texte transformé

sub expand_notes($) {

	my $t = $_[0];	# Texte de la note
	my $r = $_[1];  # Référence de la note

	# date : A.C. 536
	$t =~ s/\bdate\s*:\s*A\.\s?C\.\s*([\d-]+)<hi[^>]*>, environ(\W?)<\/hi>/date : environ $1 avant Jésus-Christ$2/g;
	$t =~ s/\bdate\s*:\s*A\.\s?C\.\s*([\d-]+), <hi[^>]*>environ<\/hi>/date : environ $1 avant Jésus-Christ/g;
	$t =~ s/\bdate\s*:\s*A\.\s?C\.\s*([\d-]+),? environ\b/date : environ $1 avant Jésus-Christ/g;
	$t =~ s/\bdate\s*:\s*A\.\s?C\.\W*([\d-]+)/date : $1 avant Jésus-Christ/g;
	$t =~ s/\sA\.\s?C\.\s+([\d-]+)/ $1 avant Jésus-Christ/g;
	#$t =~ s/\sA\.\s?C\./ avant Jésus-Christ/g;


	#$t =~ s/\baj\./ajoute(nt)/g;
	#$t =~ s/\bchald\./chaldéen(s)/g;
	#$t =~ s/\bcomp\./comparez/g;
	#$t =~ s/\benv\./environ/g;
	#$t =~ s/\bhébr\./hébreu(x)/g;
	#$t =~ s/\blitt\./littéralement/g;
	#$t =~ s/\bom\./omet(tent)/g;
	#$t =~ s/\bordin\./traduit d\'ordinaire/g;
	#$t =~ s/\bpl\./plusieurs (lisent)/g;
	#$t =~ s/\bqqs\./(selon) quelques-uns/g;
	#$t =~ s/\bvers\.\s/verset(s) /g;
	#$t =~ s/\bLXX\b/version des "Septente"/g;
	$t =~ s/\bR\./texte reçu/g;

	#$t =~ s/(?<!\w)c\. à d\./c'est à dire/g;
	
	# Affiche les modifications
	#log2b( "Note transformée", unmarkup($_[0]) . ' -> ' . unmarkup($t) ) if( $_[0] ne $t );
	
	return $t;
}

#####################################################################################
# Transforme les signes et abréviations du texte
#
#	Dieu (Élohim)
#	*Dieu (Éloah)
#	+Dieu (El)
#	Seigneur (Adonai)
#	*Seigneur (Jéhovah, uniquement NT)
#
#	Jah, Jéhovah, l'Éternel, l'Éternel Dieu
#
#	$0: $txt	Texte
#	out		Texte transformé

sub expand_bible($) {
	
	my $txt = $_[0];	# Texte

	#TODO: donner un type a la balise divineName <divineName type='yhwh'> cf 11.5.2.1
	#Ca ne marche pas avec bibletime
	
	# On marque Dieu et Seigneur tous seuls pour faciliter le traitement suivant
	$txt =~ s/(.?)(Dieu|Seigneur)(?!\w)/( ($1 ne '*' && $1 ne '#') ? ($1.'‡'.$2) : ($1.$2) )/eg;
	
	#   $txt =~ s/(?<!\S)\*(Dieu)\b/<divineName type=\"El\">\x{2217}$1<\/divineName>/g;
	#$txt =~ s/\*(Dieu)(?!\w)/<divineName type=\"El\">\x{2217}$1<\/divineName>/g;
	#$txt =~ s/\#(Dieu)(?!\w)/<divineName type=\"Éloah\">\x{2020}$1<\/divineName>/g;
	#$txt =~ s/‡(Dieu)(?!\w)/<divineName type=\"Élohim\">$1<\/divineName>/g;
	#$txt =~ s/\*(Seigneur)(?!\w)/<divineName type=\"Jéhovah\">\x{2217}$1<\/divineName>/g;
	#$txt =~ s/‡(Seigneur)(?!\w)/<divineName>$1<\/divineName>/g;
	#$txt =~ s/(?<!\w)(Jah)(?!\w)/<divineName>$1<\/divineName>/g;
	#$txt =~ s/(?<!\w)(Jéhovah)(?!\w)/<divineName>$1<\/divineName>/g;
	#$txt =~ s/(?<!\w)(Éternel(?: Dieu)?)(?!\w)/<divineName>$1<\/divineName>/g;
	#   $txt =~ s/\b(?<=[lL]\')(Éternel Dieu|Éternel)\b/<divineName>$1<\/divineName>/g;

	$txt =~ s/\*(Dieu)(?!\w)/<divineName>\x{2217}$1<\/divineName>/g;
	$txt =~ s/\#(Dieu)(?!\w)/<divineName>\x{2020}$1<\/divineName>/g;
	$txt =~ s/‡(Dieu)(?!\w)/<divineName>$1<\/divineName>/g;
	$txt =~ s/\*(Seigneur)(?!\w)/<divineName>\x{2217}$1<\/divineName>/g;
	$txt =~ s/‡(Seigneur)(?!\w)/<divineName>$1<\/divineName>/g;
	$txt =~ s/(?<!\w)(Jah)(?!\w)/<divineName>$1<\/divineName>/g;
	$txt =~ s/(?<!\w)(Jéhovah)(?!\w)/<divineName>$1<\/divineName>/g;
	$txt =~ s/(?<!\w)(Éternel(?:\sDieu)?)(?!\w)/<divineName>$1<\/divineName>/g;


	return $txt;
}

# \x{2020} - †			†Dieu = Éloah
# \x{2021} - ‡			utilisé comme marqueur temporaire
# \x{2022} - •			utilisé comme marqueur de note sur la sortie 
# \x{2217} - ∗			∗Dieu = El	∗Seigneur = Jéhovah
# \x{2218} - ∘
# \x{2605} - ★			Très grand alinéa
# \x{2606} - ☆			Grand alinéa
# \x{2731} - ✱			Alinéa
#	perl -e 'for( $i=32; $i< 0xFFFF; $i++ ) { printf "%x - %c\n", $i, $i; }' 2>/dev/null| less

#####################################################################################
# Fonctions utilisées pour produire la sortie au format OSIS

# Début d'un livre (nom en paramêtre)
sub osis_start_book($$) {
	print OUTFILE "<div type=\"book\" osisID=\"",$_[0],"\" canonical=\"true\">\n",
		"\t<title type=\"main\">",$_[1],"</title>\n";
}

# Fin d'un livre
sub osis_end_book() {
	print OUTFILE "</div>\n\n";
}

# Début d'un chapitre (nom en paramêtre)
sub osis_start_chapter($$) {
	print OUTFILE "\t<chapter osisID=\"",$_[0],"\" chapterTitle=\"",$_[1],"\">",
		"<title type=\"chapter\">",$_[1],"</title>\n";
}

# Fin d'un chapitre
sub osis_end_chapter() {
	print OUTFILE "\t</chapter>\n";
}

# Début d'un paragraphe <p> ou <lg>
sub osis_start_p() {
	print OUTFILE "\t<".$ptype.">\n";
	$mark_ptype = $ptype;
}

# Fin d'un paragraphe <p> ou <lg>
sub osis_end_p() {
	print OUTFILE "\t</".$mark_ptype.">\n";
}

# Début d'un verset
sub osis_start_verse() {
	print OUTFILE "\t\t<verse sID=\"",$verseID,"\" osisID=\"",$verseID,"\" n=\"",$verseNB,"\"/>";
}

# Fin d'un verset (Bible)
sub osis_end_verse() {
	print OUTFILE "<verse eID=\"",$verseID,"\"/>\n";
}

# Debut d'un sous-titre		# Normalement titre, mais le résultat est étrange avec bibletime
sub osis_start_sub() {
	#print OUTFILE "\t\t<p><head canonical=\"true\">";
	print OUTFILE "\t\t<p><title canonical=\"true\">";
}

# Fin d'un sous-titre
sub osis_end_sub() {
	#print OUTFILE "</head></p>\n";
	print OUTFILE "</title></p>\n";
	#&osis_end_p();
	#&osis_start_p();
}

# Commentaire
sub osis_comment() {
	print OUTFILE '<!-- '.escape(join('',@_)).' -->';
}

# \x{2605} - ★			Très grand alinéa
# \x{2606} - ☆			Grand alinéa
# \x{2731} - ✱			Alinéa
sub osis_alinea1() {
	print OUTFILE "✱ ";
}

sub osis_alinea2() {
	print OUTFILE "☆ ";
}

sub osis_alinea3() {
	print OUTFILE "★ ";
}

	#print "  ($verseID) TEXT p_cXXX: \"", normalize($xml_txt), "\"\n";

####################################################
# Balises de forme:	<b></b> <br> <i></i> <a></a> <br/>

# <b></b>
sub parsenotes_start_b() {}		# Est utilisé pour les chapitres dans le flux
sub parsebible_start_b() {}

sub parsenotes_end_b()   { 
	# Parfois se cache un titre de chapitre
	if( $xml_txt =~ /^Chapitre \d+\.$/ ) {
		log2("Correction: le texte \"<b>".normalize($xml_txt)."</b>\" est considéré comme un titre de chapitre.");
		&parsenotes_end_p_cChapitre();	# Fait comme si c'était un chapitre
		$xml_txt = '';			# Supprime le texte parasite
		$xml_capt = 1;			# On recommence la capture (terminée par notes_end_p_cChapitre())
	}
}

sub parsebible_end_b()   {
	# Parfois se cache un titre de chapitre
	if( $xml_txt =~ /^Chapitre (\d+)\.$/ ) {
	
		# Récupération du texte
		my $c = normalize( $xml_txt );
		
		log2("Correction: le texte \"<b>".normalize($xml_txt)."</b>\" est considéré comme un titre de chapitre");

		# Nouveau numéro de chapitre, controle avec le numéro lu dans le a_name
		my $newNB = $1;

		# Controle de cohérence
		if( $newNB != $chapterNB ) {
			log2("Le nom du chapitre de $xml_txt ne correspond pas au numéro de chapitre $chapterNB");
		}
		
		# Supprime le texte parasite du flux
		$xml_txt = '';
	}
}


# <a></a>
sub parsenotes_start_a($)  {} 	# Un <a> sans nom est sans intérêt
sub parsenotes_end_a()     {}
sub parsebible_start_a($)  {}
sub parsebible_end_a()     {}

sub parsenotes_start_a_name($) {

	# Récupère le numéro de chapitre le cas échéant 
	$in_a_name=$_[0];
	if( $in_a_name =~ /^at19_[1-5]_(\d\d\d?)$/ or $in_a_name =~ /^[an]t\d\d_(\d\d)$/ ) {
		&check_newchapter( 0 + $1 );

	# Début de testament
	} elsif( $in_a_name =~ /^[AN]T$/ ) {
		$testament = $in_a_name;

	# Vérifie que le a name= est correct
	} elsif( $in_a_name !~ /^[an]t\d\d$/ and $in_a_name !~ /^at19_[1-5]$/ ) {
	
		log2("<a name=\"$in_a_name\"> non reconnu");
	}
}

sub parsebible_start_a_name($) {

	# Récupère le numéro de chapitre le cas échéant
	$in_a_name=$_[0];
	if( $in_a_name =~ /^at(19)_[1-5]_(\d\d\d?)$/ or $in_a_name =~ /^[an]t(\d\d)_(\d\d)$/ ) {

		# Récupère le nouveau numéro
		my $t = ( ($testament eq 'AT' and $1 == 19) ? 'Psaume' : 'Chapitre' );
		my $c = 0 + $2;

		# Ferme le verset et le chapitre précédent
		if( $verseNB > 0 ) {
			&osis_end_verse();
			$verseNB = 0;
			$noteNB = 'a';
			&osis_end_p();
			$mark_endp = 0; # Il n'est plus nécessaire de fermer le paragraphe
			&osis_end_chapter();
			&osis_comment('r=',$in_a_name);
		}

		# Vérifie et ouvre le nouveau chapitre
		&check_newchapter($c);
		&osis_start_chapter( $chapterID, $t.' '.$chapterNB );
		#&osis_start_p();
		
	# Début de testament
	} elsif( $in_a_name =~ /^[AN]T$/ ) {
		$testament = $in_a_name;

	# Vérifie que le a name= est correct
	} elsif( $in_a_name !~ /^[an]t\d\d$/ and $in_a_name !~ /^at19_[1-5]$/ ) {
	
		log2("<a name=\"$in_a_name\"> non reconnu");
	} 
}



### <br/>	(ne sert à rien, n'est présent que dans les titres de livres)
#sub parsenotes_start_br()	{}			# Ignoré pour les notes
#sub parsebible_start_br()	{}

### <i></i> Exceptionnellement, cette balise est simplement copiée dans le texte
sub parsenotes_start_i() {
	if ( $xml_capt == 0 ) {
		die "  ($verseID) Balise <i> alors qu'aucune capture n'est en cours\n";
	} elsif( $xml_capt == 1 ) {
		$xml_txt .= '<hi type="italic">';
	}
}
sub parsenotes_end_i() {
	if( $xml_capt == 1 ) {
		$xml_txt .= '</hi>';
	}
}

# Pour la bible, on fait pareil, peu fréquent
sub parsebible_start_i()	{  &parsenotes_start_i();    }
sub parsebible_end_i()		{  &parsenotes_end_i();      }


####################################################
# Balises de paragraphes, première passe:  </p>

sub parsenotes_end_p_cLivre() {

	# On ferme, pour éviter de se perdre
	$chapterNB = 0;
	$verseNB = 0;

	# Récupération du texte
	$xml_capt = 0;
	$xml_txt = normalize( $xml_txt );
	
	# Recherche du nom normalisé du livre
	if( exists $book{$xml_txt} ) {
		$bookID = $book{$xml_txt};
		&log1("Lecture de $bookID (".$xml_txt.")");
	} elsif( $xml_txt !~ /^\s*$/ ) {
		&log1("Nom de livre inconnu \"".$xml_txt."\" (ignoré)");
	}
}


sub parsenotes_end_p_cChapitre() {


	# Récupération du texte
	$xml_capt = 0;
	$xml_txt = normalize( $xml_txt );
	
	# Recherche du nom titre du chapitre
	if( $xml_txt =~ /^(?:Chapitre|PSAUME) (\d+)(?:\.|\*)?$/ ) {
	
		# Nouveau numéro de chapitre, controle avec le numéro lu dans le a_name
		my $newNB = $1;
		
		# Controle de cohérence
		if( $newNB != $chapterNB ) {
			log2("Le nom du chapitre de $xml_txt ne correspond pas au numéro de chapitre $chapterNB");
		}
	}
	
	## Recherche et prise en compte du numéro de chapitre (les Psaumes n'ont pas de a_name individuels)
	#elsif( $xml_txt =~ /^PSAUME (\d+)\*?$/ ) {
	#	&check_newchapter($1);
	#}
	
	# Chapitre introuvable
	else {
		die "  ($verseID) Impossible de parser le numéro du chapitre \"$xml_txt\"\n";
	}
}


sub parsenotes_end_p_cUsuel() {	# Tiens à jour la numérotation des versets
	
	$xml_capt = 0;  # Fin de capture
	my $v;

	# Autocorrection du numéro de verset
	if( $xml_txt !~ /^\s*(\d+)\s/ and $xml_txt =~ /^\s*(\d+)\W/ ) {
		$v = $1;
		log2b("Correction: verset numero $v dans",substr($xml_txt,0,16)."...");
		$xml_txt = $1.' ';
	}

	# Récupération du numéro de verset
	if( $xml_txt =~ /^\s*(\d+)\s+/ ) {
		$v = $1;
		
		# Cohérence de la progression
		if( $v <= $verseNB ) {
			log2("Le verset $verseNB est suivi du verset $v");
			die "Fatal\n";
		}
		if( $v != $verseNB + 1 ) {
			log2("Le verset $verseNB est suivi du verset $v");
		}
		
		$verseNB = $v;
		$verseID = $chapterID . '.' . $verseNB;
	}
	
	# Pas de numéro de verset
	#else {
	#	print "  ($verseID) Pas de numéro de verset dans \"".substr($xml_txt,0,32)."...\"\n";
	#}
}


sub parsenotes_end_p_cNote() {

	$xml_capt = 0;  # Fin de capture
	#print "  ($verseID) TEXT p_cNote: \"", normalize($xml_txt), "\"\n";
		
	my ($n, $v);
	$xml_txt = normalize( $xml_txt );  # Supprime les sauts de ligne et espaces multiples
	foreach $n (split( m/\s*\x{2014}\s+(?=v\.\s)/si, $xml_txt )) {

		# Supprime les notes vides
		next if( $n =~ /^\s*$/ );
		next if( $n =~ /^\s*\W\s*$/ );

		# Note sur un unique verset
		if( $n =~ s/^v\. (\d+)(\**)\s?\:\s?(.*)$/$3/ ) {
			create_note( $chapterID, $1, $2, $n, 1 );
		}
		
		# Note sur une liste de versets
		elsif( $n =~ s/^v\. ((?:\d+\**,\s?)+\d+\**)\s\:\s?(.*)$/$2/ ) {
			my $tabvers = $1;
			#print STDERR "DEBUG: groupe $tabvers\n";
			foreach $v (split(/,\s+/,$tabvers)) {
				$v =~ /^(\d+)(\**)$/;
				create_note( $chapterID, $1, $2, $n, 1 );
				#print STDERR "DEBUG: (2) notes sur vv $v: $n\n";
			}
		}
		
		# Note sur deux versets
		elsif( $n =~ s/^v\. (\d+)(\**) (?:<hi\stype\=\"italic\">)?et(?:<\/hi>)? (\d+)(\**)\s\:\s?(.*)$/$5/ ) {
			create_note( $chapterID, $1, $2, $n, 1 );
			create_note( $chapterID, $3, $4, $n, 1 );
			#print STDERR "DEBUG: (4) notes sur $1$2 et $3$4\n";
		}
		
		# Note avec le chapitre
		elsif( $n =~ s/^v\. (\d+)(\**)\s?\(ch\. (\d+)\)\s:\s*(.*)$/$4/ ) {
			#print STDERR "  DEBUG: (3) Note pour ".$bookID.'.'.$2.'.'.$1." (".unmarkup($n).")\n";
			create_note( $bookID.'.'.$3, $1, $2, $n, 0 );
		}
		
		# Note avec le chapitre sur deux versets
		elsif( $verseID eq 'Heb.4.13' and $n =~ s/^v\. 18 \(ch\. 3\) et v\. 11 \(ch\. 4\)\s:\s+(.*)$/$1/ ) {
			create_note( 'Heb.3', '18', '', $n, 0 );
			create_note( 'Heb.4', '11', '', $n, 0 );
			log2b("Cas particulier, Note mal formattée (2 passages)", unmarkup($n));
		}
		
		# Note double sur un Psaume
		elsif( ($bookID eq 'Ps') and $n =~ /^\x{2014} (?:<hi.*?>)?\*(?:<\/hi>)?\s: (.*) \x{2014}(?:<\/hi>)? \*\*\s: (.*)$/ ) {
		#â<80><94> <hi type="italic">*</hi> : <hi type="italic">La lettre ... alphabÃ©tique. â<80><94></hi> ** : <hi type="italic">autrement dit</hi> : AllÃ©luia<hi type="italic">.</hi>
			create_note( $chapterID, 0, '*', $1, 0 );
			#create_note( $chapterID, 0, '**', $2.'.', 0 );
			create_note( $chapterID, 0, '**', $2, 0 );
			log2b("Cas particulier, note double dans le titre", unmarkup($n));
		}
		
		# Note sur un Psaume
		elsif( ($bookID eq 'Ps' or $bookID eq 'Song' or $bookID eq 'Lam' or $bookID eq 'Rev' ) and $n =~ s/^\x{2014} (\*+)\s?:\s?(.*)$/$2/ ) {
			#print "  ($verseID) Note pour $chapterID.0\n";
			create_note( $chapterID, 0, $1, $n, 0 );
			log2b("Cas particulier, Titre du Psaume/Song/Lam/Rev suivant", unmarkup($n));
		}
		
		## Note double sur un Psaume
		#elsif( ($verseID eq 'Ps.110.7' or $verseID eq 'Ps.111.10' or $verseID eq 'Ps.33.22' or $verseID eq 'Ps.59.17') and 
		#$n =~ /^\x{2014} <hi.*?>\*<\/hi> : (<hi.*?>La lettre.*tique\.) \x{2014}(<\/hi>) \*\* : (<hi.*?>autrement.*luia)<hi.*?>\.<\/hi>$/ ) {
		##â<80><94> <hi type="italic">*</hi> : <hi type="italic">La lettre ... alphabÃ©tique. â<80><94></hi> ** : <hi type="italic">autrement dit</hi> : AllÃ©luia<hi type="italic">.</hi>
		#	create_note( $chapterID, 0, '*', $1.$2, 0 );
		#	create_note( $chapterID, 0, '**', $3.'.', 0 );
		#}
		
		# Note double loupée, devrait être traité plus haut
		elsif( ($verseID eq 'Ps.110.7' or $verseID eq 'Ps.111.10' or $verseID eq 'Ps.33.22' or $verseID eq 'Ps.59.17') ) {
			log2b("CARAMBA, encore loupé:",$n);
		}
		
		## Titre de Jérémie
		#elsif( $verseID eq 'Jer.52.34' and $bookID eq 'Lam' and $n =~ // ) {
		#	create_note( 'Lam.1', 0, '', $n, 0 );
		#	log2b("Cas particulier, note de livre", unmarkup($n));
		#}
		
		
		# Inconnu
		else {
			log2b("Note non reconnue",unmarkup($n));
		}
	}
}


sub parsenotes_end_p_cSousTitre() {	# Exclusivement dans les Psaumes
	$xml_capt = 0;  # Fin de capture
	#print "  ($verseID) TEXT p_cSousTitre: \"", normalize($xml_txt), "\"\n";
}


sub parsenotes_end_p_cUsuel_center()	{  &parsenotes_end_p_cUsuel();    }	# Dans le cas des notes: idem verset
sub parsenotes_end_p_cPosie()		{  &parsenotes_end_p_cUsuel();    }	# Dans le cas des notes: idem verset


sub parsenotes_end_p_cClustermoyen()		{}	# Contient toujours '*', Ignoré à la lecture des notes
sub parsenotes_end_p_cClustersecondaire()	{}	# Contient toujours '*', Ignoré à la lecture des notes
sub parsenotes_end_p_cClustersuprieur()		{}	# Contient '* *', sauf Psaumes: "LIVRE PREMIER"..., Ignoré à la lecture des notes


####################################################
# Balises de paragraphes, seconde passe:  </p>

sub parsebible_end_p_cLivre() {

	# Il faut fermer les versets, chapitres et livres éventuellement ouverts
	if( $verseNB > 0 ) {
		&osis_end_verse();
		
		#if( $mark_inpoetic ) {
		#	$mark_inpoetic = 0;
		#	&osis_end_lg();
		#}
		
		$verseNB = 0;
		$noteNB = 'a';
		&osis_end_p();
		$mark_endp = 0;	# Il ne sera plus nécessaire de fermer par la suite, on vient de le faire

		&osis_end_chapter();
		$chapterNB = 0;

		&osis_end_book();
	}	

	# Récupération du texte
	$xml_capt = 0;
	$xml_txt = normalize( $xml_txt );

	# Recherche du nom normalisé du livre
	if( exists $book{$xml_txt} ) {
		$bookID = $book{$xml_txt};
		printf STDERR "Lecture de $bookID ($xml_txt)\n";
		&osis_start_book( $bookID, $xml_txt );
	} else {
		printf STDERR "Nom de livre inconnu \"$xml_txt\" (ignoré)\n" if ( $xml_txt !~ /^\s*$/ );
	}
}


sub parsebible_end_p_cChapitre() {

	# Récupération du texte
	$xml_capt = 0;
	$xml_txt = normalize( $xml_txt );
	
	# Recherche du nom titre du chapitre
	if( $xml_txt =~ /^(?:Chapitre|PSAUME) (\d+)(:?\.|\*)?$/ ) {

		# Nouveau numéro de chapitre, controle avec le numéro lu dans le a_name
		my $newNB = $1;

		# Controle de cohérence
		if( $newNB != $chapterNB ) {
			log2("Le nom du chapitre de $xml_txt ne correspond pas au numéro de chapitre $chapterNB");
		}
	}

	## Recherche et prise en compte du numéro de chapitre (les Psaumes n'ont pas de a_name individuels)
	#elsif( $xml_txt =~ /^PSAUME (\d+)\*?$/ ) {
	#	
	#	# Enregistre le numéro du Psaume
	#	my $p = $1;
	#	
	#	# Fermeture des versets et chapitres précédents
	#	if( $verseNB > 0 ) {
	#		&osis_end_verse();
	#		$verseNB = 0;
	#		&osis_end_p();
	#		&osis_end_chapter();
	#	}
	#	
	#	# Commence le nouveau Psaume
	#	&check_newchapter($p);
	#	&osis_start_chapter( $chapterID, $xml_txt );
	#	&osis_start_p();
	#}

	# Chapitre introuvable
	else {
		die "  ($verseID) Impossible de parser le numéro du chapitre \"$xml_txt\"\n";
	}
}


sub parsebible_end_p_cUsuel() {	# Tiens à jour la numérotation des versets

	# $ptype indique ce que l'on souhaite avoir lors de la sortie
	$ptype='p';
	$mark_poetic = 0;
	&parsebible_end_p_GENERIC();    
}
	
	
sub parsebible_end_p_cPosie() {	
	# Ajoutera les <l>
	$ptype='lg';
	$mark_poetic = 1;
	&parsebible_end_p_GENERIC();    
}


sub parsebible_end_p_GENERIC() {	# Tiens à jour la numérotation des versets

	if( $verseNB > 0 ) {
		$xml_capt = 3;  # Fin de capture, on regarde quand même les sauts de paragraphe
	} else {
		$xml_capt = 0;	# Fin de capture
	}
	
	# On n'a pas commencé
	if( '' eq $bookID ) {
		warn "Texte parasite avant le début: \"".$xml_txt."\" ignoré\n";
		return
	};

	# Texte vide, on ignore
	if( $xml_txt =~ /^\s*$/ ) {

		# Paragraphe vide (&#160; transformé en espace) = nouveau paragraphe
		if( ($xml_txt =~ m/^\s$/) ) { 
			$mark_endp = 1;
		} elsif( $mark_endp > 0 ) {
			log2("Ligne vide sur nouveau paragraphe");
#			&osis_end_p();
#			$mark_endp = 0;
#			&osis_start_p();
		} else {
			log2("Ligne vide");
		}
		return;
	}

	my $v;	# Numéro du verset

	# Autocorrection du numéro de verset
	if( $xml_txt !~ /^\s*\d+\s/ and $xml_txt =~ /^\s*\d+\W/ ) {
		$xml_txt =~ s/^\s*(\d+)/$1 /;
		$v = $1;
		log2b("Correction: verset numero $v dans",substr($xml_txt,0,16)."...");
	}

	# Ajoute la décoration
	$xml_txt = &expand_bible( $xml_txt );

	# DEBUG
	#if( $verseID =~ /^Deut\.27\.1\d/ ) {
	#	log2( "mark_ptype=".$mark_ptype." ptype=".$ptype );
	#}

	my $para = 0;	# Nouveau paragraphe ?

	# Nouveau verset (Récupération du numéro de verset)
	if( $xml_txt =~ s/^\s*(\d+)\s+// ) {
	
		# On a un nouveau verset !
		$v = $1;
		
		# Cohérence de la progression
		if( $v <= $verseNB ) {
			log2("Le verset $verseNB est suivi du verset $v");
			die "Fatal\n";
		}
		if( $v != $verseNB + 1 ) {
			log2("Le verset $verseNB est suivi du verset $v");
		}
		
		# Fermeture du verset précédent
		if( $verseNB > 0 ) {
			&osis_end_verse();
			
			# On ferme aussi le <p>
			if( ($mark_ptype ne $ptype) or ($mark_endp > 0) ) {
				&osis_end_p();
				#&osis_comment('$mark_endp=',$mark_endp);
				$mark_endp = 0;
				&osis_start_p();
				$para = 1;
			}
			
		# Il n'y a pas de verset précédent, on ouvre un paragraphe
		} else {
			&osis_start_p();
			$para = 1;
			# Dans ce cas, on cherche quand même les espaces insécables
			$xml_capt = 3;
			                                
		}

		# Début du nouveau verset
		$verseNB = $v;
		$verseID = $chapterID . '.' . $verseNB;
		&osis_start_verse( $verseID, $verseNB );
		
	# Changement de mode (p vers lg ou inversement)
	} elsif( ($mark_ptype ne $ptype) or ($mark_endp > 0) ) {	
		&osis_end_p();
		$mark_endp = 0;
		&osis_start_p();
		$para = 1;
	}
	
	# S'il y a un alinéa, il faudrait que ce soit au moins un nouveau paragraphe
	if( defined($alinea) && ! $para ) {
		log2("Alinéa sans nouveau paragraphe");
	}
	
	# Contenu du verset
	&print_with_notes( $xml_txt );
}


sub parsebible_end_p_cNote() {		# Indique un nouveau paragraphe

	# Nouveau paragraphe uniquement dans le texte
	if( $verseNB > 0 ) {
		$mark_endp = 1;	# Il faudra penser à fermer le <p> et en re-ouvrir un
		#&osis_end_p();
		#&osis_start_p();
	}
	
	else {
		log2("Note en dehors des versets");
	}
}
		

sub parsebible_end_p_cUsuel_center() {
	# Dans le cas des bible: idem verset
	#  USAGES:
	#	Jer.46.1	(at24_46)    
	#	Jer.47.7	(at24_47)    
	#	Jer.48.47	(at24_48)   
	#	Jer.49.6	(at24_49)    
	#	Jer.49.22	(at24_49)   
	#	Jer.49.27	(at24_49)   
	# Les textes sont déjà sur des paragraphes indépendants
	# aucune marque n'est ajouté.
	
	#log2("parsebible_end_p_cUsuel_center()");
	parsebible_end_p_cUsuel();    
}

sub parsebible_end_p_cSousTitre() {	# Exclusivement dans les Psaumes

	#print "  ($verseID) TEXT p_cSousTitre: \"", normalize($xml_txt), "\"\n";
	$xml_capt = 0;  # Fin de capture

	# Ne traite que les sous-titre en début de chapitre
	if( $verseNB > 0 ) {
		die "  ($verseID) Sous-titre non placé en début de chapitre\n";
	}
	
	# Position en verset 0
	$verseID = $chapterID . '.' . $verseNB;
	
	# On n'a pas commencé
	if( '' eq $bookID ) {
		warn "Sous-titre parasite avant le début: \"".$xml_txt."\" ignoré\n";
		return
	};

	&osis_start_sub();
	#print "  ($verseID) Ajout d'une note ??\n";
	&print_with_notes( $xml_txt );
	&osis_end_sub();
}


sub parsebible_end_p_cClustersecondaire() {	# Contient toujours '*'
	#log2("parsebible_end_p_cClustersecondaire()");
	die ("  ($verseID) Alinea déjà défini\n") if ( defined $alinea );
	$alinea = \&osis_alinea1;
}

sub parsebible_end_p_cClustermoyen() {	# Contient toujours '*'
	#log2("parsebible_end_p_cClustermoyen()");
	die ("  ($verseID) Alinea déjà défini\n") if ( defined $alinea );
	$alinea = \&osis_alinea2;
}

sub parsebible_end_p_cClustersuprieur()	{	# Contient '* *', sauf Psaumes: "LIVRE PREMIER"...
	#log2("parsebible_end_p_cClustersuprieur()");
	die ("  ($verseID) Alinea déjà défini\n") if ( defined $alinea );
	$alinea = \&osis_alinea3;
}


###################################
# Balisages sans intérêts (ces balises ne contiennent rien d'utile)

sub parsenotes_end_p_cAccesDirect()   {}
sub parsebible_end_p_cAccesDirect()   {}
sub parsenotes_end_p_cnone_center()   {}
sub parsebible_end_p_cnone_center()   {}
