<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Interactive Row Reduction</title>
  <link rel="stylesheet" href="${"css/rrinter.css" | vers}">
  <meta name="viewport" content="initial-scale=1, maximum-scale=1">
  <style>
  body {
      background: #dddddd;
      text-align: center;
      min-height: 100vh;
      margin: 0;
  }
  #mathbox {
      width: 100%;
      height: 300px;
      margin: 0;
      border: 0;
      border-top: 1px solid #aaaaaa;
      border-bottom: 1px solid #aaaaaa;
      position: relative;
  }
  </style>
</head>
<body>
    <div class="page">
    <h1>Interactive Row Reduction</h1>
    <div id="mathbox">
        <div class="row-ref inactive">
            Matrix is in <i>row echelon form</i>.
        </div>
        <div class="row-rref inactive">
            Matrix is in <i>reduced row echelon form</i>.
        </div>
    </div>
    <div class="newmat">
        <div>
            <span>
                Enter a new matrix here.  Put one row on each line, and separate
                columns by commas.  You can use simple mathematical expressions
                for the matrix entries.
            </span><br>
            <textarea rows="5" cols="30"></textarea><br>
            <button class="ops-button">Use this matrix</button>
        </div>
    </div>
    <div class="centered" id="rrmat-ui">
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
            <div class="newmat-button">
                <button class="ops-button">Enter a new matrix</button>
            </div>
            <br>
            <div class="row-ops">
                <span class="ops-label row-swap">
                    <button class="ops-button">Swap rows</button>
                </span><span class="ops-control row-swap">
                    <span class="row-selector"></span> and
                    <span class="row-selector"></span>
                </span>
                <span class="ops-label row-mult">
                    <button class="ops-button">Multiply row</button>
                </span><span class="ops-control row-mult">
                    <span class="row-selector"></span> by
                    <input type="text">
                </span>
                <span class="ops-label row-rrep">
                    <button class="ops-button">Row replacement</button>
                </span><span class="ops-control row-rrep">
                    <span>Add</span><input type="text"> times
                    <span class="row-selector"></span>
                    to
                    <span class="row-selector"></span>
                </span>
            </div>
        </div>
        <div class="history">
        </div>
    </div>

    <script src="${"js/rrinter.js" | vers}"></script>
    <script>
    "use strict";

    DomReady.ready(function() {

        // TODO:
        //  * Test on other browsers

        // Install interactive code
        var mat = RRInter.install();
        if(!mat)
            return;

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

        var augment = parseInt(RRInter.urlParams.augment);
        if(isNaN(augment))
            augment = undefined;

        window.rrmat = new RRMatrix(
            mat.length, mat[0].length, view, mathbox, {
                defSpeed:   1.5,
                augmentCol: augment,
            });
        rrmat.setMatrix(mat);

        // Highlight pivots initially
        var slide = rrmat.highlightPivots();
        rrmat.state = slide.transform(rrmat.state);

        var onLoaded = function() {
            window.slideshow = rrmat.slideshow();
            RRInter.finalize();
        };

        if(rrmat.loaded)
            onLoaded();
        else
            rrmat.on('loaded', onLoaded);
    });

    </script>
    </div>
</body>
</html>
