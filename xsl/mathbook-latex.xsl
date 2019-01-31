<?xml version='1.0'?>

<!DOCTYPE xsl:stylesheet [
    <!ENTITY % entities SYSTEM "../../mathbook/xsl/entities.ent">
    %entities;
]>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:import href="../../mathbook/xsl/mathbook-latex.xsl" />

<xsl:param name="latex.font.size" select="'12pt'" />

<xsl:param name="latex.preamble.early">
\usepackage{amsmath}
\usepackage{amssymb}
\usepackage{spalign}
\usepackage{longtable}
\usepackage{multicol}
</xsl:param>

<xsl:param name="latex.preamble.late">
\theoremstyle{definition}
\newtheorem{specialcase}[theorem]{Example}
\newtheorem{impnote}[theorem]{Important Note}
\newtheorem{essential}[theorem]{\color{red}Essential Definition}

\definecolor{bluebox}{rgb}{0.2157,0.55,0.88}
\newenvironment{bluebox}[1][]{%
  \par\vspace*{\topsep}\hbox to \linewidth\bgroup\hfil%
  \tikz\node[draw=bluebox,line width=.75mm,rounded corners, inner sep=2mm]%
  \bgroup\begin{minipage}{.95\linewidth}\begin{impnote}[#1]}
  {\end{impnote}\end{minipage}\egroup;\hfil\egroup\par\vspace*{\topsep}}

\newcounter{jdrthmtype}

\def\ifempty#1{\def\temp{#1}\ifx\temp\empty }

\newenvironment{oneoffthm}[3][]{%
  \addtocounter{jdrthmtype}{1}%
  \theoremstyle{#2}%
  \ifempty{#3}%
  \newenvironment{oneoff\thejdrthmtype}[1][]{}{}%
  \else%
  \newtheorem{oneoff\thejdrthmtype}[theorem]{#3}%
  \fi%
  \begin{oneoff\thejdrthmtype}[#1]}{%
  \end{oneoff\thejdrthmtype}}

\newenvironment{oneoffbluebox}[3][]{%
  \addtocounter{jdrthmtype}{1}%
  \theoremstyle{#2}%
  \ifempty{#3}%
  \newenvironment{oneoff\thejdrthmtype}[1][]{}{}%
  \else%
  \newtheorem{oneoff\thejdrthmtype}[theorem]{#3}%
  \fi%
  \par\vspace*{\topsep}\hbox to \linewidth\bgroup\hfil%
  \tikz\node[draw=bluebox,line width=.75mm,rounded corners, inner sep=2mm]%
  \bgroup\begin{minipage}{.95\linewidth}\begin{oneoff\thejdrthmtype}[#1]}%
  {\end{oneoff\thejdrthmtype}\end{minipage}\egroup;\hfil\egroup\par\vspace*{\topsep}}

% Hack to remove theorem numbering without disabling \label
\makeatletter
\def\thmhead@plain#1#2#3{%
  \thmname{#1}%
  \thmnote{ {\the\thm@notefont(#3)}}}
\let\thmhead\thmhead@plain
\makeatother

\graphicspath{{figure-images/}{.}}

\usepackage{macros}
\pdfverstrue
</xsl:param>

<xsl:param name="latex.online" select="'https://textbooks.math.gatech.edu/ila/'" />

<!-- This is almost the same as <me>, except it doesn't wrap the result in an
     equation* environtment.  Also, in "bare" mode, commands can be executed in
     a global context. -->
<xsl:template match="latex-code">
  <xsl:choose>
    <xsl:when test="@mode='inline'">
        <xsl:value-of select="text()" />
    </xsl:when>
    <xsl:when test="@mode='bare'">
        <xsl:value-of select="text()" />
    </xsl:when>
    <xsl:otherwise>
        <xsl:text>\par\vspace*{\abovedisplayskip}&#xa;</xsl:text>
        <xsl:text>\begin{center}</xsl:text>
        <xsl:value-of select="text()" />
        <xsl:text>\end{center}&#xa;</xsl:text>
        <xsl:text>\par\vspace*{\belowdisplayskip}&#xa;</xsl:text>
    </xsl:otherwise>
  </xsl:choose>
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
    <xsl:text>\framebox[.9\linewidth]{\href{</xsl:text>
    <xsl:value-of select="$latex.online" />
    <xsl:value-of select="@source"/>
    <xsl:text>}{Use this link to view the online demo}}</xsl:text>
</xsl:template>

<!-- Numbering overrides -->
<xsl:template match="part" mode="number-override">
  <xsl:param name="number" />
  <xsl:text>\setcounter{part}{</xsl:text>
  <xsl:value-of select="$number - 1"/>
  <xsl:text>}&#xa;</xsl:text>
</xsl:template>
<xsl:template match="chapter|appendix" mode="number-override">
  <xsl:param name="number" />
  <xsl:text>\setcounter{chapter}{</xsl:text>
  <xsl:value-of select="$number - 1"/>
  <xsl:text>}&#xa;</xsl:text>
</xsl:template>
<xsl:template match="section" mode="number-override">
  <xsl:param name="number" />
  <xsl:text>\setcounter{section}{</xsl:text>
  <xsl:value-of select="$number - 1"/>
  <xsl:text>}&#xa;</xsl:text>
</xsl:template>
<xsl:template match="subsection" mode="number-override">
  <xsl:param name="number" />
  <xsl:text>\setcounter{subsection}{</xsl:text>
  <xsl:value-of select="$number - 1"/>
  <xsl:text>}&#xa;</xsl:text>
</xsl:template>
<xsl:template match="subsubsection" mode="number-override">
  <xsl:param name="number" />
  <xsl:text>\setcounter{subsubsection}{</xsl:text>
  <xsl:value-of select="$number - 1"/>
  <xsl:text>}&#xa;</xsl:text>
</xsl:template>

</xsl:stylesheet>
