## /* -*- javascript -*-

<%! draggable=True %>
<%! clip_shader=True %>
<%! demojs=False %>

<%inherit file="base.mako"/>

<%block name="title">The equation Ax=b</%block>

<%block name="inline_style">
html, body {
    margin: 0;
    height: 100%;
}
#mathbox1 {
    width:    100%;
    height:   100%;
    position: relative;
    z-index:  0;
}
#inset-container {
    width : 30%;
    position: absolute;
    bottom:   0px;
    right:    0px;
    z-index:  1;
}
#inset-container2 {
    position: absolute;
    left:   0px;
    top:    0px;
    transform: translateY(-100%);
    width:  100%;
    padding-bottom: 100%;
    border: 2px solid #cccccc;
    box-sizing: border-box;
}
#mathbox2 {
    position: absolute;
    width:    100%;
    height:   100%;
}
#caption {
    position: absolute;
    width:    50%;
    color:    white;
    padding:  10px;
}
</%block>

<%block name="body_html">
<div id="mathbox1">
    <div id="inset-container">
        <div id="inset-container2">
            <div id="mathbox2"></div>
        </div>
    </div>
    <div id="caption">
      <p><span id="the-equation"></span></p>
      <p>[Click and drag the vector head]</p>
    </div>
</div>
</%block>

## */

function decodeQS() {
    var decode, match, pl, query, search;
    pl = /\+/g;
    search = /([^&=]+)=?([^&]*)/g;
    decode = function(s) {
        return decodeURIComponent(s.replace(pl, " "));
    };
    query = window.location.search.substring(1);
    var urlParams = {};
    while (match = search.exec(query)) {
        urlParams[decode(match[1])] = decode(match[2]);
    }
    return urlParams;
}
var paramsQS = decodeQS();

var showSolns = "Show solution set";
var lockSolns = "Lock solution set";
var Params = function() {
    this[showSolns] = paramsQS.show ? true : false;
    this[lockSolns] = true;
    this.Axes = true;
    this['Homogeneous'] = function() {
        vector[0] = vector[1] = vector[2] = 0;
        vectorOut[0] = vectorOut[1] = 0;
        this[showSolns] = true;
        this[lockSolns] = true;
        mathbox1.select("#solnset").set("visible", true);
    };
};
var params = new Params();
var gui = new dat.GUI();

gui.add(params, 'Axes').onFinishChange(function(val) {
    mathbox1.select(".axes").set("visible", val);
});
gui.add(params, showSolns).listen().onFinishChange(function(val) {
    mathbox1.select("#solnset").set("visible", val);
});
gui.add(params, lockSolns).listen().onFinishChange(function(val) {
    if(params[showSolns]) {
        tmpVec.set.apply(tmpVec, vector);
        onDrag(tmpVec);
    }
});
gui.add(params, 'Homogeneous');

var mathbox1 = window.mathbox1 = mathBox({
    element: document.getElementById("mathbox1"),
    // size: { width: 800, heght: 800 },
    plugins: ['core', 'controls', 'cursor'],
    controls: { klass: THREE.OrbitControls },
    mathbox: {
        warmup: 10,
        splash: true,
        inspect: false,
    },
});
if (mathbox1.fallback) throw "WebGL not supported"
var three1 = mathbox1.three;
three1.renderer.setClearColor(new THREE.Color(0, 0, 0), 1);
var camera1 = mathbox1
    .camera({
        proxy:    true,
        position: [-3, 1.2, -1.5],
        lookAt:   [0, 0, 0],
        up:       [0, 1, 0],
    });
mathbox1.set('focus', 1.5);
var view1 = mathbox1
    .cartesian({
        range: [[-5,5], [-5,5], [-5,5]],
        scale: [-1, 1, 1],
        rotation: [-π/2, 0, 0],
    });
view1
    .axis({
        classes:  ['axes'],
        axis:     1,
        end:      true,
        width:    3,
        depth:    1,
        color:    'white',
        opacity:  0.75,
        zBias:    -1,
        size:     5,
    })
    .axis({
        classes:  ['axes'],
        axis:     2,
        end:      true,
        width:    3,
        depth:    1,
        color:    'white',
        opacity:  0.75,
        zBias:    -1,
        size:     5,
    })
    .axis({
        classes:  ['axes'],
        axis:     3,
        end:      true,
        width:    3,
        depth:    1,
        color:    'white',
        opacity:  0.75,
        zBias:    -1,
        size:     5,
    })
;

var visible_threshold = 0.1;
var vector = [-1, 2, 3];
if(paramsQS.x)
    vector = paramsQS.x.split(",").map(parseFloat);
// Labeled vector
view1
    .array({
        channels: 3,
        width:    1,
        items:    2,
        data:     [[0, 0, 0], vector],
    })
    .vector({
        color:  "rgb(0,255,0)",
        end:    true,
        size:   5,
        width:  5,
    }, {
        visible: function() {
            return vector[0]*vector[0]
                + vector[1]*vector[1]
                + vector[2]*vector[2] >= visible_threshold;
        }
    })
    .array({
        channels: 3,
        width:    1,
        expr: function(emit) {
            emit(vector[0]/2, vector[1]/2, vector[2]/2);
        },
    })
    .text({
        live:  false,
        width: 1,
        data:  ['x'],
    })
    .label({
        outline: 2,
        background: "black",
        color:   "rgb(0,255,0)",
        offset:  [0, 25],
        size:    15,
        zIndex: 3,
    })
;
// Point at zero
view1
    .array({
        channels: 3,
        width:    1,
        data:     [[0,0,0]],
        live:     false,
    })
    .point({
        color:   "rgb(0,255,0)",
        size:    20,
    }, {
        visible: function() {
            return vector[0]*vector[0]
                + vector[1]*vector[1]
                + vector[2]*vector[2] < visible_threshold;
        }
    })
;

// Clip-to cube
var clipCubeMesh = (function() {
    var cubeMaterial = new THREE.MeshBasicMaterial();
    var wireframeColor = new THREE.Color(1, 1, 1);
    var geo = new THREE.BoxGeometry(2, 2, 2);
    var mesh = new THREE.Mesh(geo, cubeMaterial);
    var cube = new THREE.BoxHelper(mesh);
    cube.material.color = wireframeColor
    three1.scene.add(cube);
    return mesh;
})();
var clipped = view1;
clipped = clipped
    .shader({code: "#vertex-xyz"})
    .vertex({pass: "world"});
clipped = clipped
    .shader({code: "#fragment-clipping"})
    .fragment();

// Matrix to multiply
var A = new THREE.Matrix3();
A.set( 1, -1,  2,
      -2,  2, -4,
       0,  0,  0);

var equation = katex.renderToString(
    "A = \\begin{bmatrix}"
        + A.elements[0] + "&" + A.elements[3] + "&" + A.elements[6] + "\\\\"
        + A.elements[1] + "&" + A.elements[4] + "&" + A.elements[7]
        + "\\end{bmatrix}");
document.getElementById("the-equation").innerHTML = equation
    + '&nbsp;&nbsp; <span id="vectors-here"></span>';

var vectorSpan = document.getElementById("vectors-here");

// Orthogonal basis of null space
var ortho1 = new THREE.Vector3(1,  1,  0);
var ortho2 = new THREE.Vector3(1, -1, -1);
// Perpendicular vector
var ortho3 = new THREE.Vector3();
ortho3.crossVectors(ortho1, ortho2);

// Solution set
clipped
    .matrix({
        channels: 3,
        live:     true,
        width:    2,
        height:   2,
        expr: function (emit, i, j) {
            if(i == 0) i = -1;
            if(j == 0) j = -1;
            i *= 30; j *= 30;
            emit(vector[0] + ortho1.x * i + ortho2.x * j,
                 vector[1] + ortho1.y * i + ortho2.y * j,
                 vector[2] + ortho1.z * i + ortho2.z * j);
        }
    });
var surface = clipped
    .surface({
        id:      "solnset",
        color:   "rgb(128,0,0)",
        opacity: 0.5,
        stroke:  "solid",
        lineX:   true,
        lineY:   true,
        width:   5,
        visible: params[showSolns],
    });



var vectorOut = [5, 5];
var tmpVec = new THREE.Vector3();
var tmpVec2 = new THREE.Vector3();
function onDrag(vec) {
    if(params[showSolns] && params[lockSolns]) {
        vec.sub(tmpVec2.set.apply(tmpVec2, vector));
        // Snap to solution set
        tmpVec.copy(vec).projectOnVector(ortho3);
        vec.sub(tmpVec).add(tmpVec2);
    }

    tmpVec.copy(vec).applyMatrix3(A);
    vectorOut[0] = tmpVec.x;
    vectorOut[1] = tmpVec.y;

    katex.render(
        "\\qquad A\\color{#00ff00}{"
            + "\\begin{bmatrix}"
            + vector[0].toFixed(2) + "\\\\"
            + vector[1].toFixed(2) + "\\\\"
            + vector[2].toFixed(2)
            + "\\end{bmatrix}} = \\color{#ffff00}{"
            + "\\begin{bmatrix}"
            + vectorOut[0].toFixed(2) + "\\\\"
            + vectorOut[1].toFixed(2)
            + "\\end{bmatrix}}",
        vectorSpan);
}
tmpVec.set.apply(tmpVec, vector);
onDrag(tmpVec);

// Make the vectors draggable
var draggable = new Draggable({
    view:    view1,
    points:  [vector],
    size:    30,
    hiliteColor: [0, 1, 1, .75],
    onDrag:  onDrag,
    mathbox: mathbox1,
});


var mathbox2 = window.mathbox2 = mathBox({
    element: document.getElementById("mathbox2"),
    //size: { width: 800, heght: 800 },
    plugins: ['core'],
    mathbox: {
        warmup: 10,
        splash: true,
        inspect: false,
    },
});
var three2 = mathbox2.three;
three2.renderer.setClearColor(new THREE.Color(0, 0, 0), 1);
var camera2 = mathbox2
    .camera({
        proxy:    false,
        position: [0, 0, 1.8],
        lookAt:   [0, 0, 0],
        up:       [0, 1, 0],
    });
mathbox2.set('focus', 1.5);
var view2 = mathbox2
    .cartesian({
        range: [[-10,10], [-10,10]],
    });
view2
    .axis({
        classes:  ['axes'],
        axis:     1,
        end:      true,
        width:    3,
        depth:    1,
        color:    'white',
        opacity:  0.75,
        zBias:    -1,
        size:     5,
    })
    .axis({
        classes:  ['axes'],
        axis:     2,
        end:      true,
        width:    3,
        depth:    1,
        color:    'white',
        opacity:  0.75,
        zBias:    -1,
        size:     5,
    })
    .grid({
        classes:  ['axes', 'grid'],
        axes:     [1, 2],
        width:    1,
        depth:    1,
        color:    'white',
        opacity:  0.5,
    })
;


// Labeled vector
view2
    .array({
        channels: 2,
        width:    1,
        items:    2,
        data:     [[0, 0], vectorOut],
    })
    .vector({
        color:  "rgb(255,255,0)",
        end:    true,
        size:   3.5,
        width:  3.5,
        zIndex: 1,
    }, {
        visible: function() {
            return vectorOut[0]*vectorOut[0]
                + vectorOut[1]*vectorOut[1] >= visible_threshold;
        }
    })
    .array({
        channels: 2,
        width:    1,
        expr: function(emit) {
            emit(vectorOut[0]/2, vectorOut[1]/2);
        }
    })
    .text({
        live:  false,
        width: 1,
        data:  ['b'],
    })
    .label({
        outline: 2,
        color:   "rgb(255,255,0)",
        background: "black",
        offset:  [15, 5],
        size:    15,
    })
;
// Point at zero
view2
    .array({
        channels: 2,
        width:    1,
        data:     [[0,0]],
        live:     false,
    })
    .point({
        color:   "rgb(255,255,0)",
        size:    10,
        zIndex:  1,
    }, {
        visible: function() {
            return vectorOut[0]*vectorOut[0]
                + vectorOut[1]*vectorOut[1] < visible_threshold;
        }
    })
;
// Column span
view2
    .array({
        channels: 2,
        width:    2,
        data:     [[5, -10], [-5, 10]],
        live:     false,
    })
    .line({
        color: "rgb(200,0,0)",
    })
;

document.body.addEventListener('keypress', function (event) {
    if (event.charCode == 'f'.charCodeAt(0)) {
        if (screenfull.enabled) {
            screenfull.toggle();
        }
    }
});

