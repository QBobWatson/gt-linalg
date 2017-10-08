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

<xsl:param name="toc.level" select="2" />
<!-- <xsl:param name="html.knowl.example" select="'no'" /> -->

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

<!-- JDR: start ordered list at a different nmuber -->
<xsl:template match="ol">
    <xsl:param name="b-original" select="true()" />
    <xsl:element name="{local-name(.)}">
        <!-- label original -->
        <xsl:if test="$b-original">
            <xsl:attribute name="id">
                <xsl:apply-templates select="." mode="internal-id" />
            </xsl:attribute>
        </xsl:if>
        <xsl:if test="@cols">
            <xsl:attribute name="class">
                <!-- HTML-specific, but in mathbook-common.xsl -->
                <xsl:apply-templates select="." mode="number-cols-CSS-class" />
            </xsl:attribute>
        </xsl:if>
        <xsl:if test="@start">
            <xsl:attribute name="start">
                <xsl:value-of select="@start" />
            </xsl:attribute>
        </xsl:if>
        <xsl:attribute name="style">
            <xsl:text>list-style-type: </xsl:text>
                <xsl:apply-templates select="." mode="html-list-label" />
            <xsl:text>;</xsl:text>
        </xsl:attribute>
        <xsl:apply-templates select="li">
            <xsl:with-param name="b-original" select="$b-original" />
        </xsl:apply-templates>
    </xsl:element>
</xsl:template>

<!-- JDR: "answers" in examples not hidden -->
<xsl:template match="example/hint|example/answer|example/solution" mode="is-hidden">
    <xsl:text>false</xsl:text>
</xsl:template>

<!-- JDR: allow images with natural width, including in sidebyside panels -->
<xsl:template match="image|video|jsxgraph" mode="get-width-percentage">
    <xsl:choose>
         <!-- check for @width on the image itself -->
         <!-- a good place to check author input   -->
        <xsl:when test="@width">
            <xsl:variable name="normalized-width" select="normalize-space(@width)" />
            <xsl:choose>
                <xsl:when test="not(substring($normalized-width, string-length($normalized-width)) = '%')">
                    <xsl:message>MBX:ERROR:   a "width" attribute should be given as a percentage (such as "40%", not as "<xsl:value-of select="$normalized-width" />"</xsl:message>
                    <xsl:apply-templates select="." mode="location-report" />
                    <!-- replace by 100% -->
                    <xsl:text>100%</xsl:text>
                </xsl:when>
                <!-- test for stray spaces? -->
                <xsl:otherwise>
                    <xsl:value-of select="$normalized-width" />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:when>
        <!-- perhaps an author-specific default width for images -->
        <xsl:when test="self::image and $docinfo/defaults/image-width">
            <xsl:value-of select="normalize-space($docinfo/defaults/image-width)" />
        </xsl:when>
        <!-- what else to do? Author will figure it out if too extreme -->
        <xsl:otherwise>
            <xsl:text>auto</xsl:text>
        </xsl:otherwise>
    </xsl:choose>
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

<!-- JDR: simpler numbering of some elements -->
<xsl:template match="*" mode="heading-simple-number">
    <h5 class="heading">
        <span class="type">
            <xsl:apply-templates select="." mode="type-name" />
        </span>
        <xsl:variable name="the-number">
            <xsl:apply-templates select="." mode="serial-number" />
        </xsl:variable>
        <xsl:if test="not($the-number='')">
            <span class="codenumber">
                <xsl:value-of select="$the-number" />
            </span>
        </xsl:if>
        <xsl:if test="title">
            <span class="title">
                <xsl:apply-templates select="." mode="title-full" />
            </span>
        </xsl:if>
    </h5>
</xsl:template>

<xsl:template match="&DEFINITION-LIKE;|&REMARK-LIKE;" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-simple-number" />
</xsl:template>

<xsl:template match="&EXAMPLE-LIKE;|&PROJECT-LIKE;|list" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-simple-number" />
</xsl:template>

<xsl:template match="&THEOREM-LIKE;|&AXIOM-LIKE;" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-simple-number" />
</xsl:template>

<xsl:template match="exercise" mode="heading-birth">
    <xsl:apply-templates select="." mode="heading-simple-number" />
</xsl:template>

<xsl:template match="paragraphs" mode="body-css-class">
    <xsl:text>paragraphs</xsl:text>
    <xsl:choose>
      <xsl:when test="@class">
        <xsl:text> </xsl:text>
        <xsl:value-of select="@class"/>
      </xsl:when>
    </xsl:choose>
</xsl:template>

<xsl:template match="caption">
    <xsl:param name="width" />
    <xsl:param name="margins" />
    <figcaption>
        <!-- $width and $margins are sentinels for -->
        <!-- sidebyside width control attributes   -->
        <xsl:if test="$width or $margins">
            <xsl:call-template name="sbs-caption-attributes">
                <xsl:with-param name="width" select="$width" />
                <xsl:with-param name="margins" select="$margins" />
            </xsl:call-template>
        </xsl:if>
        <span class="heading">
            <xsl:apply-templates select="parent::*" mode="type-name"/>
        </span>
        <span class="codenumber">
            <xsl:apply-templates select="parent::*" mode="serial-number"/>
        </span>
        <xsl:apply-templates />
    </figcaption>
</xsl:template>

<!-- JDR: mathbook gives no way to customize this at all.  Hence we have to
     copy/paste this whole thing every time it's changed upstream. -->

<xsl:param name="extra.mathjax">
  <xsl:text>MathJax.Ajax.config.path["Extra"] = "static/js";&#xa;</xsl:text>
  <xsl:text>MathJax.Hub.Config({&#xa;</xsl:text>
  <xsl:text>    extensions: ["[Extra]/spalign.js"],&#xa;</xsl:text>
  <xsl:text>});&#xa;</xsl:text>
</xsl:param>

<xsl:template name="mathjax">
    <!-- mathjax configuration -->
    <xsl:element name="script">
        <xsl:attribute name="type">
            <xsl:text>text/x-mathjax-config</xsl:text>
        </xsl:attribute>
        <xsl:text>&#xa;</xsl:text>
        <!-- // contrib directory for accessibility menu, moot after v2.6+ -->
        <!-- MathJax.Ajax.config.path["Contrib"] = "<some-url>";           -->

        <!-- JDR: Added the line below -->
        <xsl:value-of select="$extra.mathjax" />

        <xsl:text>MathJax.Hub.Config({&#xa;</xsl:text>
        <xsl:text>    tex2jax: {&#xa;</xsl:text>
        <xsl:text>        inlineMath: [['\\(','\\)']],&#xa;</xsl:text>
        <xsl:text>    },&#xa;</xsl:text>
        <xsl:text>    TeX: {&#xa;</xsl:text>
        <xsl:text>        extensions: ["extpfeil.js", "autobold.js", "https://aimath.org/mathbook/mathjaxknowl.js", ],&#xa;</xsl:text>
        <xsl:text>        // scrolling to fragment identifiers is controlled by other Javascript&#xa;</xsl:text>
        <xsl:text>        positionToHash: false,&#xa;</xsl:text>
        <xsl:text>        equationNumbers: { autoNumber: "none",&#xa;</xsl:text>
        <xsl:text>                           useLabelIds: true,&#xa;</xsl:text>
        <xsl:text>                           // JS comment, XML CDATA protect XHTML quality of file&#xa;</xsl:text>
        <xsl:text>                           // if removed in XSL, use entities&#xa;</xsl:text>
        <xsl:text>                           //&lt;![CDATA[&#xa;</xsl:text>
        <xsl:text>                           formatID: function (n) {return String(n).replace(/[:'"&lt;&gt;&amp;]/g,"")},&#xa;</xsl:text>
        <xsl:text>                           //]]&gt;&#xa;</xsl:text>
        <xsl:text>                         },&#xa;</xsl:text>
        <xsl:text>        TagSide: "right",&#xa;</xsl:text>
        <xsl:text>        TagIndent: ".8em",&#xa;</xsl:text>
        <xsl:text>    },&#xa;</xsl:text>
        <!-- key needs quotes since it is not a valid identifier by itself-->
        <xsl:text>    // HTML-CSS output Jax to be dropped for MathJax 3.0&#xa;</xsl:text>
        <xsl:text>    "HTML-CSS": {&#xa;</xsl:text>
        <xsl:text>        scale: 88,&#xa;</xsl:text>
        <xsl:text>        mtextFontInherit: true,&#xa;</xsl:text>
        <xsl:text>    },&#xa;</xsl:text>
        <xsl:text>    CommonHTML: {&#xa;</xsl:text>
        <xsl:text>        scale: 88,&#xa;</xsl:text>
        <xsl:text>        mtextFontInherit: true,&#xa;</xsl:text>
        <xsl:text>    },&#xa;</xsl:text>
        <!-- optional presentation mode gets clickable, large math -->
        <xsl:if test="$b-html-presentation">
            <xsl:text>    menuSettings:{&#xa;</xsl:text>
            <xsl:text>      zoom:"Click",&#xa;</xsl:text>
            <xsl:text>      zscale:"300%"&#xa;</xsl:text>
            <xsl:text>    },&#xa;</xsl:text>
        </xsl:if>
        <!-- close of MathJax.Hub.Config -->
        <xsl:text>});&#xa;</xsl:text>
        <!-- optional beveled fraction support -->
        <xsl:if test="//m[contains(text(),'sfrac')] or //md[contains(text(),'sfrac')] or //me[contains(text(),'sfrac')] or //mrow[contains(text(),'sfrac')]">
            <xsl:text>/* support for the sfrac command in MathJax (Beveled fraction) */&#xa;</xsl:text>
            <xsl:text>/* see: https://github.com/mathjax/MathJax-docs/wiki/Beveled-fraction-like-sfrac,-nicefrac-bfrac */&#xa;</xsl:text>
            <xsl:text>MathJax.Hub.Register.StartupHook("TeX Jax Ready",function () {&#xa;</xsl:text>
            <xsl:text>  var MML = MathJax.ElementJax.mml,&#xa;</xsl:text>
            <xsl:text>      TEX = MathJax.InputJax.TeX;&#xa;</xsl:text>
            <xsl:text>  TEX.Definitions.macros.sfrac = "myBevelFraction";&#xa;</xsl:text>
            <xsl:text>  TEX.Parse.Augment({&#xa;</xsl:text>
            <xsl:text>    myBevelFraction: function (name) {&#xa;</xsl:text>
            <xsl:text>      var num = this.ParseArg(name),&#xa;</xsl:text>
            <xsl:text>          den = this.ParseArg(name);&#xa;</xsl:text>
            <xsl:text>      this.Push(MML.mfrac(num,den).With({bevelled: true}));&#xa;</xsl:text>
            <xsl:text>    }&#xa;</xsl:text>
            <xsl:text>  });&#xa;</xsl:text>
            <xsl:text>});&#xa;</xsl:text>
        </xsl:if>
    </xsl:element>
    <!-- mathjax javascript -->
    <xsl:element name="script">
        <xsl:attribute name="type">
            <xsl:text>text/javascript</xsl:text>
        </xsl:attribute>
        <xsl:attribute name="src">
            <xsl:text>https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.1/MathJax.js?config=TeX-AMS_CHTML-full</xsl:text>
        </xsl:attribute>
    </xsl:element>
</xsl:template>

</xsl:stylesheet>
