<?xml version='1.0' encoding='UTF-8'?>

<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns="http://www.bibletechnologies.net/2003/OSIS/namespace"
	xmlns:osis="http://www.bibletechnologies.net/2003/OSIS/namespace">

	<xsl:output method="text" encoding="UTF-8" omit-xml-declaration="yes" indent="no"/>

	<xsl:template match="/">
		<xsl:variable name="revisions" select="count(/osis:osis/osis:osisText/osis:header/osis:revisionDesc) - 1"/>
		<xsl:text>[FreJND]
Description=French John Nelson Darby (1975)
About=Traduction française par John Nelson Darby en 1859\par Texte libre de droits\par Vous pouvez acheter une version imprimée à\par\
	French translation by John Nelson Darby (JND) 1859\par Public Domain\par You can buy a printed version at\par\par\
	Bibles &amp; Publications Chrétiennes\par Calendrier La Bonne Semence\par\
	Web: http://www.labonnesemence.com/\par tel: +33 (0)4 75 78 12 78 fax: +33 (0)4 75 42 81 55\par BP 335\par 26003 Valence CEDEX\par France
DataPath=./modules/texts/ztext/frejnd/
ModDrv=zText
CompressType=ZIP
BlockType=BOOK
SourceType=OSIS
Lang=fr
MinimumVersion=1.5.9
Encoding=UTF-8
GlobalOptionFilter=OSISFootnotes
GlobalOptionFilter=OSISScripref
GlobalOptionFilter=OSISHeadings
TextSource=http://www.bibliquest.org/Bible/BibleJNDhtm-Bible.zip
DistributionNotes=Report errors to &lt;seb.sword(a)koocotte.org&gt;
DistributionLicense=Public Domain
LCSH=Bible. French.
Version=1.</xsl:text><xsl:value-of select="$revisions"/><xsl:text>
</xsl:text>
<xsl:apply-templates select="/osis:osis/osis:osisText/osis:header/osis:revisionDesc">
	<xsl:with-param name="revisions" select="$revisions"/>
</xsl:apply-templates>
<xsl:text>Obsoletes=FreDRB
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


