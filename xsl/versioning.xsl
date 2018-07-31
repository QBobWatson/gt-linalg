<?xml version="1.0" ?>

<xsl:stylesheet
    version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="xml" encoding="utf-8"/>

  <xsl:param name="version" select="'default'"/>

  <!-- Identity transform -->
  <xsl:template match="/ | @* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()" />
    </xsl:copy>
  </xsl:template>

  <!-- Kill nodes with restricted versions -->
  <xsl:template match="restrict-version">
    <xsl:if test="contains(@versions, $version)">
      <xsl:copy-of select="* | text()"/>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
