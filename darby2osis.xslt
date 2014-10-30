<?xml version='1.0' encoding='UTF-8'?>

<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns="http://www.bibletechnologies.net/2003/OSIS/namespace"
	xmlns:osis="http://www.bibletechnologies.net/2003/OSIS/namespace">

	<xsl:output method="xml" encoding="UTF-8" omit-xml-declaration="no" indent="yes"/>

	<xsl:template match="/">
		<osis xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.bibletechnologies.net/2003/OSIS/namespace http://www.bibletechnologies.net/osisCore.2.1.1.xsd">
			<osisText osisIDWork="FreJND" osisRefWork="bible" xml:lang="fr" canonical="true">
				<header>
					<revisionDesc resp="skc"><date>2013.08.19</date>
						<p>New upstream reference (Bibliquest) and update from YD</p>
					</revisionDesc>
					<revisionDesc resp="skc"><date>2012.01.27</date>
						<p>New upstream reference (Bibliquest) and various corrections</p>
					</revisionDesc>
					<revisionDesc resp="skc"><date>2008.06.13</date>
						<p>Fixed encoding of .conf</p>
					</revisionDesc>
					<revisionDesc resp="skc"><date>2008.05.08</date>
						<p>Update configuration file</p>
					</revisionDesc>
					<revisionDesc resp="skc"><date>2008.03.30</date>
						<p>Correct notes generation and few typos</p>
					</revisionDesc>
					<revisionDesc resp="skc"><date>2008.01.16</date>
						<p>Text is in public domain. Build notes in the alphabetical order</p>
					</revisionDesc>
					<revisionDesc resp="skc"><date>2008.01.10</date>
						<p>Correct note references when in same book</p>
					</revisionDesc>
					<revisionDesc resp="skc"><date>2007.12.31</date>
						<p>Various corrections for notes</p>
					</revisionDesc>
					<revisionDesc resp="skc"><date>2007.12.29</date>
						<p>Mark references in notes</p>
					</revisionDesc>
					<revisionDesc resp="skc"><date>2007.12.29</date>
						<p>Corrected poetic imbrication</p>
					</revisionDesc>
					<revisionDesc resp="skc"><date>2007.09.19</date>
						<p>Compressed Sword module</p>
					</revisionDesc>
					<revisionDesc resp="skc"><date>2007.08.29</date>
						<p>New notes with bible references</p>
					</revisionDesc>
					<revisionDesc resp="skc"><date>2007.07.19</date>
						<p>New upstream version</p>
					</revisionDesc>
					<revisionDesc resp="skc"><date>2007.07.08</date>
						<p>Add clusters marks</p>
					</revisionDesc>
					<revisionDesc resp="skc"><date>2007.05.12</date>
						<p>Add paragraph</p>
					</revisionDesc>
					<revisionDesc resp="skc"><date>2007.04.27</date>
						<p>Add notes</p>
					</revisionDesc>
					<revisionDesc resp="skc"><date>2006.11.21</date>
						<p>Many corrections</p>
					</revisionDesc>
					<revisionDesc resp="skc"><date>2006.11.17</date>
						<p>With notes</p>
					</revisionDesc>
					<revisionDesc resp="skc"><date>2006.11.11</date>
						<p>Initial version</p>
					</revisionDesc>
					<work osisWork="FreJND">
						<title>Version John Neslon Darby</title>
						<type type="OSIS">Bible</type>
						<identifier type="OSIS">Bible.fr.JND.1975</identifier>
						<rights type="x-copyright">La Bonne Semence, 26000 Valence, France - Texte libre de droits</rights>
						<refSystem>Bible.JND</refSystem>
					</work>
					<work osisWork="bible">
						<type type="OSIS">Bible</type>
						<refSystem>Bible</refSystem>
					</work>
				</header>
				<div type="bookGroup">
					<title>Ancien Testament</title>
					<xsl:apply-templates select=".//osis:div[position()&lt;40]"/>
				</div>
				<div type="bookGroup">
					<title>Nouveau Testament</title>
					<xsl:apply-templates select=".//osis:div[position()&gt;39]"/>	
				</div>
			</osisText>
		</osis>
	</xsl:template>

	<xsl:template match="osis:div[@type='book']">
		<xsl:copy-of select="."/>
	</xsl:template>

</xsl:stylesheet>

