<?xml version='1.0' encoding='UTF-8'?>

<xslt:stylesheet version="1.0"
	xmlns:xslt="http://www.w3.org/1999/XSL/Transform"
	xmlns="http://www.w3.org/1999/xhtml"
	xmlns:osis="http://www.bibletechnologies.net/2003/OSIS/namespace">

	<xslt:output
		method="xml"
		encoding="utf-8"
		omit-xml-declaration="no"
		doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"
		doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN"
		indent="yes"/>

	<xslt:param name='BOOK'/>

	<!-- #######################################################################################################
	- - 
	- - 		Racine du document, sélection d'un livre, ou de la totalité (variable $BOOK)
	-->

	<xslt:template match="/">
		<html>
			<head>
				<title>La Sainte Bible - Traduction J. N. Darby
					<xslt:if test="$BOOK"> - <xslt:value-of select=".//osis:div[@type='book' and @osisID=$BOOK]/osis:title"/></xslt:if>
				</title>
				<link rel="stylesheet" href="bible.css" type="text/css" media="screen"/>
				<link rel="stylesheet" href="bible_pda.css" type="text/css" media="handheld"/>
				<link rel="stylesheet" href="bible_print.css" type="text/css" media="print"/>
				<script type="text/javascript" src="bible.js"/>
				<!--xi:include  href="html/bible.js" parse="text" xmlns:xi="http://www.w3.org/2001/XInclude"/-->
				<xslt:comment><![CDATA[[if lte IE 6]>
<style type="text/css" media="screen">
p.osisP {
  width: 35em;
}
p.osisLg {
  width: 35em;
}
span.osisNote {
  width: 12em;
  position: absolute;
}
</style>
				<![endif]]]></xslt:comment>
			</head>
			<body>

		<xslt:choose>

			<!-- Sélection d'un livre unique -->
			<xslt:when test="$BOOK">
				<xslt:message terminate='no'>Génération du livre: <xslt:value-of select='$BOOK'/></xslt:message>
				<xslt:apply-templates select=".//osis:div[@type='book' and @osisID=$BOOK]"/>
			</xslt:when>

			<!-- Toute la Bible -->
			<xslt:otherwise>
				<xslt:message terminate='no'>Génération de la bible entière</xslt:message>

				<!-- Génère la liste des livres -->
				<p class='sommaireLivres'>Accès aux livres: <ul class='sommaireLivres'>
					<xslt:for-each select=".//osis:div[@type='book']">
						<li class='sommaireLivres'><a class='sommaireLivres' href="#{@osisID}"><xslt:value-of select="@osisID"/></a></li>
						<xslt:text> </xslt:text>
					</xslt:for-each>
				</ul>
				</p>

				<!-- Génère les livres -->
				<xslt:apply-templates select=".//osis:div[@type='book']"/>
			</xslt:otherwise>

		</xslt:choose>

			</body>
		</html>
	</xslt:template>



	<!-- #######################################################################################################
	- - 
	- - 		Un livre
	-->

	<xslt:template match="osis:div[@type='book']">
		<div class='osisBook'>

			<!-- Titre du livre -->
			<h1><a name='{@osisID}'><xslt:value-of select="osis:title[@type='main']"/></a></h1>

			<!-- Génère la liste des chapitres -->
			<div class='sommaireChap'>Accès aux chapitres:<ul class='sommaireChap'>
				<xslt:for-each select=".//osis:chapter">
					<li class='sommaireChap'><a class='sommaireChap' href="#{@osisID}"><xslt:value-of select="substring-after(@chapterTitle,' ')"/></a></li>
					<xslt:text> </xslt:text>
				</xslt:for-each>
			</ul>
			</div>

			<!-- Génère les chapitres -->
			<xslt:apply-templates/>
		</div>
	</xslt:template>




	<!-- #######################################################################################################
	- - 
	- - 		Un chapitre
	-->

	<xslt:template match="osis:chapter">
		<div class='osisChapter'>
			<h2><a name='{@osisID}'><xslt:value-of select="osis:title[@type='chapter']"/></a></h2>
			<xslt:apply-templates/>
		</div>
	</xslt:template>



	<!-- #######################################################################################################
	- - 
	- - 		Un paragraphe
	-->

	<xslt:template match="osis:p">
		<p class='osisP'>
			<xslt:apply-templates/>
		</p>
		<xslt:if test=".//osis:note">
		<p class='osisNotes'>
			<xslt:apply-templates select=".//osis:note" mode="notes"/>
		</p>
		</xslt:if>
	</xslt:template>



	<!-- #######################################################################################################
	- - 
	- - 		Une partie poétique
	-->

	<xslt:template match="osis:lg">
		<p class='osisLg'>«
			<xslt:apply-templates/>
		»</p>
		<xslt:if test=".//osis:note">
		<p class='osisNotes'>
			<xslt:apply-templates select=".//osis:note" mode="notes"/>
		</p>
		</xslt:if>
	</xslt:template>



	<!-- #######################################################################################################
	- - 
	- - 		Un vers
	-->

	<xslt:template match="osis:l">
		<span class='osisL'><xslt:apply-templates/></span><br/>
	</xslt:template>



	<!-- #######################################################################################################
	- - 
	- - 		Un début de verset
	-->

	<xslt:template match="osis:verse[@sID]">
		<a class='osisVerse' id='{@osisID}' name='{@osisID}'><xslt:value-of select="@n"/></a>
		<xslt:apply-templates/>
	</xslt:template>



	<!-- #######################################################################################################
	- - 
	- - 		Une note
	-->

	<!-- Dans le flux du texte, on ne place qu'un renvoi -->
	<xslt:template match="osis:note">
		<a class='osisNote' onmouseover="displayNote('{@osisID}')" onmouseout="hideNote('{@osisID}')">*<xslt:value-of select="@n"/></a>
	</xslt:template>

	<!-- Dans le pied de paragraphe, on place le contenu de la note -->
	<xslt:template match="osis:note" mode="notes">
		<span class='osisNote' id='{@osisID}'>
			<dfn class='osisNote'><xslt:value-of select="@n"/>:&#160;</dfn>
			<xslt:apply-templates/>
		</span>
	</xslt:template>



	<!-- #######################################################################################################
	- - 
	- - 		Un italique
	-->

	<xslt:template match="osis:hi">
		<em><xslt:apply-templates/></em>
	</xslt:template>



	<!-- #######################################################################################################
	- - 
	- - 		Une référence
	-->

	<xslt:template match="osis:reference">
		<xslt:choose>
			<xslt:when test='$BOOK'>
				<a class='osisReference' href="{substring-before(@osisRef,'.')}.html#{@osisRef}"><xslt:apply-templates/></a>
			</xslt:when>
			<xslt:otherwise>
				<a class='osisReference' href='#{@osisRef}'><xslt:apply-templates/></a>
			</xslt:otherwise>
		</xslt:choose>
	</xslt:template>



	<!-- #######################################################################################################
	- - 
	- - 		Une occurence de Dieu
	- - 		Il faudrait utiliser <abbr title="">
	-->

	<xslt:template match="osis:divineName">
		<xslt:apply-templates/>
	</xslt:template>



	<!-- #######################################################################################################
	- - 
	- - 		Une partie poétique
	-->

	<xslt:template match="osis:title[@canonical='true']">
		<em><xslt:apply-templates/></em>
	</xslt:template>



	<!-- #######################################################################################################
	- - 
	- - 		Une partie poétique
	-->

	<xslt:template match="osis:XX">
		<div class='osisBook'>
			<xslt:apply-templates/>
		</div>
	</xslt:template>



	<!-- #######################################################################################################
	- - 
	- - 		Une partie poétique
	-->

	<xslt:template match="osis:XX">
		<div class='osisBook'>
			<xslt:apply-templates/>
		</div>
	</xslt:template>



	<!-- #######################################################################################################
	- - 
	- - 		Éléments ignorés
	-->

	<xslt:template match="osis:NONE">
		<xslt:apply-templates/>
	</xslt:template>



	<!-- #######################################################################################################
	- - 
	- - 		Éléments supprimés
	-->

	<xslt:template match="osis:verse[@eID]|osis:title[@type='main' or @type='chapter']">
	</xslt:template>



	<!-- #######################################################################################################
	- - 
	- - 		Fallback
	-->

	<xslt:template match="osis:title">
		<xslt:message terminate="yes">Balise non traitée: <xslt:copy-of select="."/></xslt:message>
	</xslt:template>
	<xslt:template match="osis:*">
		<xslt:message terminate="yes">Balise non traitée: <xslt:value-of select="name()"/></xslt:message>
	</xslt:template>



</xslt:stylesheet>

