# Makefile to build Darby Bible files
#
#  Sébastien Koechlin <seb.osis@koocotte.org>
#
#	Variable	Description
#	$@	This will always expand to the current target.
#	$<	The name of the first prerequisite. This is the first item listed after the colon. (binarytree.o in the first rule above)
#	$?	The names of all the prerequisites that are newer than the target.
#	$^	The names of all the prerequisites, with spaces between them. No duplicates
#	$+	Like $^, but with duplicates. Items are listed in the order they were specified in the rule.


SRC=BibleJNDhtm-Bible.html
#SCHEMA=http://www.bibletechnologies.net/osisCore.2.1.1.xsd
SCHEMA=dtd/osisCore.2.1.1.xsd
#NONET=
NONET=--nonet --path dtd
WWW=http://www.bibliquest.org/Bible/BibleJNDhtm-Bible.zip
INSTALLMOD=~/.sword/modules/texts/ztext/frejnd
INSTALLCONF=~/.sword/mods.d
#OSIS2MOD=/usr/local/bin/osis2mod1511
OSIS2MOD=/usr/bin/osis2mod
BOOKS=Gen Exod Lev Num Deut Josh Judg Ruth 1Sam 2Sam 1Kgs 2Kgs 1Chr 2Chr Ezra Neh Esth Job Ps Prov Eccl Song Isa Jer Lam Ezek Dan Hos Joel Amos Obad Jonah Mic Nah Hab Zeph Hag Zech Mal Matt Mark Luke John Acts Rom 1Cor 2Cor Gal Eph Phil Col 1Thess 2Thess 1Tim 2Tim Titus Phlm Heb Jas 1Pet 2Pet 1John 2John 3John Jude Rev

default: install

all: install html zip

# Get raw file
wget:
	wget -O `basename $(WWW)` $(WWW)
	unzip `basename $(WWW)`
	rm `basename $(WWW)`
	mv BibleJNDhtm-Bible.htm $(SRC)

# Create HTML file to work on
#	Translate word-apos to ascii-apos
#	Fix a bug? in tidy about significant space in <i> and <span>
build/1-darby.html: $(SRC)
	-mkdir build
	perl -p -e 's/&#8217;/\x27/g; s/(?<=\S)(<(?:i|span)[^>]*>\s*)$$/ $$1/g;' $< > $@
	#perl -p -e "s/&#8217;/\'/g;" $< > $@
	#sed -i -r 's/<(i|span)[^>]*>\r/ \0/g' $@

# Tidy: HTML to well-formed xhtml translator 
build/2-darby.xhtml: build/1-darby.html
	-tidy -indent -wrap 120 -numeric -asxml -language fr --char-encoding utf8 --input-encoding latin1 --word-2000 true --doctype omit -o $@ $<

# Patch source to correct upstream known problems
build/3-darby.xhtml: build/2-darby.xhtml darby.patch
	cp -f $< $@.p
	patch $@.p darby.patch
	mv $@.p $@

# Automatic corrections for upstream known problems
build/4-darby.xhtml: build/3-darby.xhtml
	perl -p -e 's/(?<=[0-9]\])(\p{IsPunct})<\/i>(?!\p{IsPunct})/<\/i>$$1/g;' $< > $@

# darbywork.pl: xhtml to xml-pseudo-osis translator
build/5-darby.xml: build/4-darby.xhtml darbywork.pl
	./darbywork.pl $< $@.p
	xmlwf -t $@.p
	mv $@.p $@
	#false

# Transform xml-pseudo-osis to OSIS
build/6-darby.xml: build/5-darby.xml darby2osis.xslt
	xsltproc --output $@ darby2osis.xslt $<

# Validate OSIS file
darby.osis.xml: build/6-darby.xml
	xmllint $(NONET) --timing --output $@ --schema $(SCHEMA) $< 

# Create HTML files
html/darby.html: darby.osis.xml osis2html.xslt
	xsltproc --xinclude --output $@ osis2html.xslt $<
	for B in $(BOOKS); do make html/$$B.html; done

html/%.html: darby.osis.xml osis2html.xslt
	xsltproc --xinclude --stringparam BOOK $* --output $@ osis2html.xslt $<

html: html/darby.html

# Create sword files
frejnd.conf: darby.osis.xml darby-conf.xslt
	xsltproc --output $@ darby-conf.xslt $<

sword/nt.bzz: darby.osis.xml
	-mkdir sword
	#$(OSIS2MOD) sword $< 0 2 4
	$(OSIS2MOD) sword $< -z
	du -sh $< sword

$(INSTALLCONF)/frejnd.conf: frejnd.conf
	-mkdir -p $(INSTALLCONF)
	cp frejnd.conf $(INSTALLCONF)

$(INSTALLMOD)/nt.bzz: sword/nt.bzz
	-mkdir -p $(INSTALLMOD)
	cp sword/[on]* $(INSTALLMOD)

install: $(INSTALLCONF)/frejnd.conf $(INSTALLMOD)/nt.bzz

# Various targets
#  Modifier build/3-darby.xhtml et lancer "make diff" pour enregistrer les modifications
diff: build/2-darby.xhtml build/3-darby.xhtml
	-diff -u $+ > darby.patch

clean:
	-rm -f build/[3-9]* darby.osis.xml html/*.html sword/[a-z]* zsword/[a-z]* darby.osis.bz2 darby.osis.zip darby.zip darby.html.zip

distclean: clean
	-rm -f build/*.* *~

swordclean:
	-rm -f $(INSTALLCONF)/frejnd.conf
	-rm -rf $(INSTALLMOD)

test: install
	@echo "Version texte:"
	diatheke -b FreJND -k Gen 1:1-3
	@echo "Version OSIS:"
	diatheke -b FreJND -f osis -k Gen 1:1-3
	emptyvss FreJND

# Zip files for distribution

darby.osis.bz2: darby.osis.xml
	-rm -f $@ darby.osis.xml.bz2
	bzip2 --keep $<
	mv darby.osis.xml.bz2 $@
	chmod u=rw,go=r $@

darby.osis.zip: darby.osis.xml frejnd.conf
	-rm -f $@
	zip -9 $@ $^
	chmod u=rw,go=r $@

darby.zip: frejnd.conf sword/nt.bzz
	-rm -f $@
	zip -9 -r $@ $< sword
	chmod u=rw,go=r $@

darby.html.zip: html/Gen.html html/darby.html
	-rm -f $@
	zip -9 -r $@ html
	chmod u=rw,go=r $@

zip: darby.osis.bz2 darby.osis.zip darby.zip darby.html.zip

.PHONY: default all wget install clean distclean swordclean check zip html diff

