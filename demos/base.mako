<%! mathbox=True %>
<%! katex=True %>
<%! domready=True %>
<%! datgui=True %>
<%! screenfull=True %>
<%! draggable=False %>
<%! clip_shader=False %>
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
        <script src="js/demo.js"></script>
    % endif
    % if self.attr.datgui:
        <script src="lib/dat.gui.min.js"></script>
    % endif
    % if self.attr.screenfull:
        <script src="lib/screenfull.min.js"></script>
    % endif
    % if self.attr.draggable:
        <script src="js/draggable.js"></script>
    % endif

    <%block name="extra_script"/>
    % if self.attr.clip_shader:
        <script type="application/glsl" id="vertex-xyz">
        // Enable STPQ mapping
        #define POSITION_STPQ
        void getPosition(inout vec4 xyzw, inout vec4 stpq) {
            // Store XYZ per vertex in STPQ
            stpq = xyzw;
        }
        </script>

        <script type="application/glsl" id="fragment-clipping">
        // Enable STPQ mapping
        #define POSITION_STPQ
        vec4 getColor(vec4 rgba, inout vec4 stpq) {
            stpq = abs(stpq);

            // Discard pixels outside of clip box
            if(stpq.x > 1.0 || stpq.y > 1.0 || stpq.z > 1.0)
                discard;

            if(1.0 - stpq.x < 0.002 ||
               1.0 - stpq.y < 0.002 ||
               1.0 - stpq.z < 0.002) {
                rgba.xyz *= 10.0;
                rgba.w = 1.0;
            }

            return rgba;
        }
        </script>
    % endif

    <script type="text/javascript">
        "use strict";
        DomReady.ready(function() {

        ${next.body()}

        });
    </script>
</body>
</html>

