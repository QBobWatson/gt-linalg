<%! mathbox=True %>
<%! katex=True %>
<%! domready=True %>
<%! datgui=True %>
<%! screenfull=True %>
<%! demojs=True %>

<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="initial-scale=1, maximum-scale=1">
  <title><%block name="title">Demo</%block></title>

  ## CSS
  % if self.attr.mathbox:
      <link rel="stylesheet" href="mathbox/mathbox.css">
  % endif
  % if self.attr.katex:
      <link rel="stylesheet"
            href="https://cdnjs.cloudflare.com/ajax/libs/KaTeX/0.5.1/katex.min.css">
  % endif
  <%block name="extra_css"/>

  <style>
      <%block name="inline_style"/>
  </style>

  <link rel="stylesheet" href="css/demo.css">

</head>
<body>
    <%block name="body_html"/>

    ## JS
    % if self.attr.mathbox:
        <script src="mathbox/mathbox-bundle.js"></script>
    % endif
    % if self.attr.katex:
        <script src="https://cdnjs.cloudflare.com/ajax/libs/KaTeX/0.5.1/katex.min.js">
        </script>
    % endif
    % if self.attr.domready:
        <script src="lib/domready.js"></script>
    % endif
    % if self.attr.demojs:
        <script src="js/demo2.js"></script>
    % endif
    % if self.attr.datgui:
        <script src="lib/dat.gui.min.js"></script>
    % endif
    % if self.attr.screenfull:
        <script src="lib/screenfull.min.js"></script>
    % endif

    <script type="text/javascript">
        "use strict";
        DomReady.ready(function() {

        <%block name="content" filter="coffee">
            ${next.body()}
        </%block>

        });
    </script>
</body>
</html>

