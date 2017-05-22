<?xml version='1.0'?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:import href="../../lib/mathbook/xsl/mathbook-html.xsl" />

<!-- Mathbook Javascript header -->
<xsl:template name="mathbook-js">
    <!-- condition first on toc present? -->
    <script src="static/js/jquery.sticky.js" ></script>
    <script src="static/js/jquery.espy.min.js"></script>
    <script src="static/js/Mathbook.js"></script>
</xsl:template>

<!-- CSS header -->
<xsl:template name="css">
    <link href="static/css/mathbook-gt.css" rel="stylesheet" type="text/css" />
    <link href="static/css/mathbook-add-on.css" rel="stylesheet" type="text/css" />
    <xsl:call-template name="external-css">
        <xsl:with-param name="css-list" select="normalize-space($html.css.extra)" />
    </xsl:call-template>
</xsl:template>

</xsl:stylesheet>
