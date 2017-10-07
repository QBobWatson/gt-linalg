## -*- javascript, coding: utf-8 -*-

## /*
<%! datgui=False %>
<%! screenfull=False %>
<%! demojs=False %>

<%inherit file="base.mako"/>

<%block name="extra_css">
    <link rel="stylesheet" href="css/rrmat.css">
    <link rel="stylesheet" href="css/slideshow.css">
</%block>

<%block name="inline_style">
  body {
      text-align: center;
      margin: 0;
      background: white;
  }

  #mathbox {
      width: 800px;
      height: 300px;
      margin: 0;
      border: 0;
      position: relative;
      display: inline-block;
  }

  .centered {
      width: 800px;
      display: inline-block;
  }

  .my-turn {
      width: 30%;
      text-align: center;
  }
</%block>

<%block name="extra_script">
  <script src="js/rrmat.js"></script>
</%block>

<%block name="body_html">
    <div id="mathbox"></div>
    <div class="centered">
        <div class="slideshow rrmat">
            <div class="controls">
                <span class="control-button">
                    <span class="icon-arrow prev-button inactive">
                        <span></span><span></span>
                    </span>
                </span>
                <span class="control-button">
                    <span class="icon-repeat reload-button inactive">
                        <span></span><span></span><span></span><span></span>
                    </span>
                </span>
                <span class="control-button" id="next-button">
                    <span class="icon-arrow next-button">
                        <span></span><span></span></span>
                </span><br>
                <span class="pages"></span>
            </div>
            <div class="caption"><%block name="first_caption"/></div>
        </div>
        <div class="my-turn">
            <button class="slideshow-button">
                Let me take it from here.
            </button>
        </div>
    </div>
</%block>

## */

DomReady.ready(function() {
    var ortho = 10000;
    var width = 800;
    var height = 300;

    var mathbox = window.mathbox = mathBox({
        element: document.getElementById("mathbox"),
        size: { width: width, height: height },
        plugins: ['core'],
        mathbox: {
            warmup: 2,
            splash: true,
            inspect: false,
        },
        splash: {fancy: true, color: "blue"},
        camera: {
            near: ortho / 4,
            far: ortho * 4,
            lookAt: -width/4,
        },
    });
    if (mathbox.fallback) throw "WebGL not supported"
    var three = mathbox.three;
    three.renderer.setClearColor(new THREE.Color(0xFFFFFF), 1.0);
    // Place camera
    var camera = mathbox
        .camera({
            proxy: false,
            position: [0, 0, ortho],
            fov: Math.atan(height/ortho) * 360 / π,
            lookAt: [width/4,0,0],
        });
    // 2D cartesian
    var view = mathbox
        .cartesian({
            range: [[-width/2, width/2], [-height/2, height/2], [-50,50]],
            scale: [width, height, 100],
        });
    // Calibrate focus distance for units
    mathbox.set('focus', ortho);

    window.rrmat = new RRMatrix(3, 4, view, mathbox,
                                {augmentCol: 2, startAugmented: true});

    function blink(color, entries, times) {
        if(!times) {times = 2;}
        var arr = [], last, delay = 0;
        for(var i = 0; i < times; ++i) {
            arr.push({color: color,
                      transform: "scale(2,2)",
                      entries:   entries,
                      duration:  0.4,
                      delay:     delay});
            delay += 0.4;
            last = {color:     "black",
                    transform: "",
                    entries:   entries,
                    duration:  0.4,
                    delay:     delay};
            delay += 0.4;
            arr.push(last);
        }
        delete last.color;
        return arr;
    }
    window.blink = blink;

    ${next.body()}

    document.querySelector(".my-turn button").onclick = function() {
        // Encode matrix
        var mat = slideshow.states[0].matrix;
        var i, j, rows = [];
        for(i = 0; i < mat.length; ++i) {
            var row = [];
            for(j = 0; j < mat[0].length; ++j) {
                var entry = mat[i][j];
                var num, den;
                [num, den] = RRMatrix.approxFraction(entry);
                row.push(num + (den != 1 ? "%2F" + den : ""));
            }
            rows.push(row.join(","));
        }
        var matval = rows.join(":");
        // Encode row operations
        // Traverse slide tree recursively
        var getOps = function(slide) {
            if(slide.slides) {
                // Has children slides
                var ret = [];
                for(var i = 0; i < slide.slides.length; ++i)
                    ret = ret.concat(getOps(slide.slides[i]));
                return ret
            }
            // No children slides
            if(slide.data.shortOp)
                return [slide.data.shortOp];
            return [];
        }
        var ops = [];
        for(i = 0; i < slideshow.currentSlideNum; ++i)
            ops = ops.concat(getOps(slideshow.slides[i]));
        var opsval = ops.join(",");

        window.open("rrinter.html?mat=" + matval + "&ops="
                    + opsval + "&cur=" + ops.length);
    }
});

