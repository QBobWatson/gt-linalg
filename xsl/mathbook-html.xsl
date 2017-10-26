<?xml version='1.0'?>

<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "../../mathbook/xsl/entities.ent">
    %entities;
]>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:import href="../../mathbook/xsl/mathbook-html.xsl" />

<xsl:param name="html.css.extra">
  static/css/mathbook-gt-add-on.css
</xsl:param>

<xsl:param name="extra.mathjax">
  <xsl:text>MathJax.Ajax.config.path["Extra"] = "static/js";&#xa;</xsl:text>
  <xsl:text>MathJax.Hub.Config({&#xa;</xsl:text>
  <xsl:text>    extensions: ["[Extra]/spalign.js"],&#xa;</xsl:text>
  <xsl:text>});&#xa;</xsl:text>
</xsl:param>

<xsl:param name="toc.level" select="2" />
<!-- <xsl:param name="html.knowl.example" select="'no'" /> -->

<!-- Mathbook Javascript header -->
<xsl:template name="mathbook-js">
    <script src="static/js/jquery.sticky.js" ></script>
    <script src="static/js/GTMathbook.js"></script>
</xsl:template>

<!-- CSS header -->
<xsl:template name="css">
    <link href="static/css/mathbook-gt.css" rel="stylesheet" type="text/css" />
    <link href="static/css/mathbook-add-on.css"
          rel="stylesheet" type="text/css" />
    <xsl:call-template name="external-css">
        <xsl:with-param name="css-list" select="normalize-space($html.css.extra)" />
    </xsl:call-template>
</xsl:template>

<!-- Primary Navigation -->
<!-- ToC, Prev/Up/Next buttons  -->
<xsl:template match="*" mode="primary-navigation">
  <nav id="gt-navbar" class="navbar container" style="">
    <div class="dropdown">
      <div class="toc-border-container" id="toc">
        <div class="toc-contents">
          <xsl:apply-templates select="." mode="toc-items" />
        </div>
      </div>
    </div>
    <div class="navbar-top-buttons toolbar">
      <div class="toolbar-buttons-left">
        <!-- Toggle button -->
        <a class="toggle-button button toolbar-item"
           href="javascript:void(0)"></a>
        <!-- A page either has an/the index as    -->
        <!-- a child, and gets the "jump to" bar, -->
        <!-- or it deserves an index button       -->
        <xsl:choose>
          <xsl:when test="index-list">
            <div class="toolbar-item">
              <xsl:apply-templates select="." mode="index-jump-nav" />
            </div>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="." mode="index-button" />
          </xsl:otherwise>
        </xsl:choose>
      </div>
      <div class="toolbar-buttons-right">
        <!-- Each button gets an id for keypress recognition/action -->
        <xsl:apply-templates select="." mode="previous-button">
          <xsl:with-param name="id-label" select="'previousbutton'" />
        </xsl:apply-templates>
        <xsl:if test="$nav-upbutton='yes'">
          <xsl:apply-templates select="." mode="up-button">
            <xsl:with-param name="id-label" select="'upbutton'" />
          </xsl:apply-templates>
        </xsl:if>
        <xsl:apply-templates select="." mode="next-button">
          <xsl:with-param name="id-label" select="'nextbutton'" />
        </xsl:apply-templates>
      </div>
    </div>
    <div class="navbar-bottom-buttons toolbar">
      <a class="toggle-button button toolbar-item"
         href="javascript:void(0)"></a>
      <xsl:apply-templates select="." mode="previous-button">
        <xsl:with-param name="id-label" select="'previousbutton'" />
      </xsl:apply-templates>
      <xsl:if test="$nav-upbutton='yes'">
        <xsl:apply-templates select="." mode="up-button">
          <xsl:with-param name="id-label" select="'upbutton'" />
        </xsl:apply-templates>
      </xsl:if>
      <xsl:apply-templates select="." mode="next-button">
        <xsl:with-param name="id-label" select="'nextbutton'" />
      </xsl:apply-templates>
    </div>
  </nav>
</xsl:template>

<!-- JDR: no sidebars anymore -->
<xsl:template match="*" mode="sidebars">
</xsl:template>

<!-- JDR: "answers" in examples not hidden -->
<xsl:template match="example/hint|example/answer|example/solution" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>
<xsl:template match="specialcase/hint|specialcase/answer|specialcase/solution" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- JDR: "special case" is just a non-hidden example -->
<xsl:template match="specialcase" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- JDR: remarks are hidden -->
<xsl:template match="remark" mode="is-hidden">
    <xsl:text>true</xsl:text>
</xsl:template>

<xsl:template match="warning" mode="body-css-class">
    <xsl:text>warning-like</xsl:text>
</xsl:template>

<!-- JDR: mathbox support -->

<xsl:template match="mathbox" mode="panel-html-box">
    <xsl:apply-templates select="." />
</xsl:template>

<xsl:template match="mathbox">
    <xsl:variable name="height">
      <xsl:choose>
        <xsl:when test="@height">
          <xsl:value-of select="@height"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>300px</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:element name="div">
        <xsl:attribute name="id">
            <xsl:apply-templates select="." mode="internal-id" />
        </xsl:attribute>
        <xsl:attribute name="class">
            <xsl:text>mathbox</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="style">
            <xsl:text>height:</xsl:text>
            <xsl:value-of select="$height" />
            <xsl:text>;</xsl:text>
        </xsl:attribute>

        <xsl:element name="iframe">
          <xsl:attribute name="src">
            <xsl:value-of select="@source"/>
          </xsl:attribute>
        </xsl:element>
    </xsl:element>

    <xsl:element name="div">
      <xsl:attribute name="class">
        <xsl:text>mathbox-link</xsl:text>
      </xsl:attribute>
      <xsl:element name="a">
        <xsl:attribute name="href">
          <xsl:value-of select="@source"/>
        </xsl:attribute>
        <xsl:attribute name="target">
          <xsl:text>_blank</xsl:text>
        </xsl:attribute>
        <xsl:text>Click to view in a new window</xsl:text>
      </xsl:element>
    </xsl:element>
</xsl:template>

<xsl:template match="*" mode="get-hide-type">
    <xsl:value-of select="@hide-type"/>
</xsl:template>

<!-- Warnings hide type by default -->
<xsl:template match="warning" mode="get-hide-type">
    <xsl:choose>
        <xsl:when test="@hide-type">
            <xsl:value-of select="@hide-type"/>
        </xsl:when>
        <xsl:otherwise>
            <xsl:text>true</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>


<!-- JDR: simpler numbering of some elements -->
<xsl:template match="*" mode="heading-simple-nonumber">
    <xsl:param name="important"/>
    <xsl:variable name="hide-type">
        <xsl:apply-templates select="." mode="get-hide-type"/>
    </xsl:variable>
    <xsl:if test="title or $hide-type != 'true'">
        <xsl:element name="h5">
            <xsl:attribute name="class">
                <xsl:text>heading</xsl:text>
                <xsl:if test="$important">
                   <xsl:text> important</xsl:text>
                </xsl:if>
            </xsl:attribute>
            <xsl:if test="$important">
                <xsl:element name="img">
                    <xsl:attribute name="src">
                        <xsl:text>static/images/important.svg</xsl:text>
                    </xsl:attribute>
                    <xsl:attribute name="class">
                        <xsl:text>important</xsl:text>
                    </xsl:attribute>
                </xsl:element>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="$hide-type = 'true'">
                    <span class="title">
                        <xsl:apply-templates select="." mode="title-full" />
                    </span>
                </xsl:when>
                <xsl:otherwise>
                    <span class="type">
                        <xsl:apply-templates select="." mode="type-name" />
                    </span>
                    <xsl:if test="title">
                        <span class="title">
                            <xsl:text>(</xsl:text>
                            <xsl:apply-templates select="." mode="title-full" />
                            <xsl:text>)</xsl:text>
                        </span>
                    </xsl:if>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
    </xsl:if>
</xsl:template>

<!-- JDR: customize heading-full -->
<xsl:template match="*" mode="heading-full">
    <xsl:param name="important"/>
    <xsl:element name="h5">
        <xsl:attribute name="class">
            <xsl:text>heading</xsl:text>
            <xsl:if test="$important">
               <xsl:text> important</xsl:text>
            </xsl:if>
        </xsl:attribute>
        <xsl:if test="$important">
            <xsl:element name="img">
                <xsl:attribute name="src">
                    <xsl:text>static/images/important.svg</xsl:text>
                </xsl:attribute>
                <xsl:attribute name="class">
                    <xsl:text>important</xsl:text>
                </xsl:attribute>
            </xsl:element>
        </xsl:if>
        <xsl:variable name="the-number">
            <xsl:apply-templates select="." mode="number" />
        </xsl:variable>
        <span class="type">
            <xsl:apply-templates select="." mode="type-name" />
        </span>
        <xsl:if test="not($the-number='')">
            <span class="codenumber">
                <xsl:value-of select="$the-number" />
            </span>
        </xsl:if>
        <xsl:if test="title">
            <span class="title">
                <xsl:text>(</xsl:text>
                <xsl:apply-templates select="." mode="title-full" />
                <xsl:text>)</xsl:text>
            </span>
        </xsl:if>
    </xsl:element>
</xsl:template>

<xsl:template match="&DEFINITION-LIKE;|&REMARK-LIKE;" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-simple-nonumber" />
</xsl:template>

<xsl:template match="essential" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-simple-nonumber">
        <xsl:with-param name="important" select="true()"/>
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="essential" mode="heading-xref-knowl">
    <xsl:apply-templates select="." mode="heading-full">
        <xsl:with-param name="important" select="true()"/>
    </xsl:apply-templates>
</xsl:template>

<xsl:template match="&EXAMPLE-LIKE;|&PROJECT-LIKE;|list" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-simple-nonumber" />
</xsl:template>

<xsl:template match="&THEOREM-LIKE;|&AXIOM-LIKE;" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-simple-nonumber" />
</xsl:template>

<xsl:template match="exercise" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-simple-nonumber" />
</xsl:template>


</xsl:stylesheet>
