<?xml version='1.0' encoding='UTF-8'?>

<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns="http://www.bibletechnologies.net/2003/OSIS/namespace"
	xmlns:osis="http://www.bibletechnologies.net/2003/OSIS/namespace">

	<xsl:output method="text" encoding="UTF-8" omit-xml-declaration="yes" indent="no"/>

	<xsl:template match="/">
		<xsl:variable name="revisions" select="count(/osis:osis/osis:osisText/osis:header/osis:revisionDesc) - 1"/>
		<xsl:text>[FreJND]
DataPath=./modules/texts/ztext/frejnd
ModDrv=zText
CompressType=ZIP
BlockType=BOOK
Lang=fr
GlobalOptionFilter=OSISHeadings
GlobalOptionFilter=OSISFootnotes
GlobalOptionFilter=OSISScripref
Encoding=UTF-8
SourceType=OSIS
LCSH=bible.French
SwordVersionDate=2015-11-07
Versification=NRSV
Description=French John Nelson Darby (1975)
About=Traduction française par John Nelson Darby (JND) en 1859.\par\
    Texte libre de droits.\par\
    Vous pouvez acheter une version imprimée à la maison d'édition ci-dessous.\par\
    \par\
    French translation by John Nelson Darby (JND) 1859.\par\
    Public Domain.\par\
    You can buy a printed version at the following publishing house.\par\
    \par\
    Bibles et Publications Chrétiennes\par\
    30 rue Châteauvert\par CS 40335\par 26003 Valence Cedex\par FRANCE\par\
    Web: http://www.labonnesemence.com/\par\
    Tel: +33 (0)4 75 78 12 78
TextSource=http://www.bibliquest.org/Bible/BibleJNDhtm-Bible.zip
DistributionNotes=Report errors to &lt;seb.sword(a)koocotte.org&gt; or to &lt;yvand.sword(a)gmail.com&gt;
DistributionLicense=Public Domain
</xsl:text>
<xsl:apply-templates select="/osis:osis/osis:osisText/osis:header/osis:revisionDesc">
	<xsl:with-param name="revisions" select="$revisions"/>
</xsl:apply-templates>
<xsl:text>Obsoletes=FreDRB
Version=1.</xsl:text><xsl:value-of select="$revisions"/>
<xsl:text>
InstallSize=2229870
</xsl:text>
	</xsl:template>


	<xsl:template match="osis:revisionDesc">
		<xsl:param name="revisions"/>
		<xsl:text>History_1.</xsl:text>
		<xsl:value-of select="$revisions - position() + 1"/>
		<xsl:text>=</xsl:text>
		<xsl:value-of select="osis:p"/>
		<xsl:text> (</xsl:text>
		<xsl:value-of select="osis:date"/>
		<xsl:text>)
</xsl:text>
	</xsl:template>


</xsl:stylesheet>
