## /* -*- javascript -*-

<%! clip_shader=True %>

<%inherit file="base.mako"/>

<%block name="title">Linearly dependent vectors</%block>

## */

var paramsQS = Demo.prototype.decodeQS();
var range = [[-10,10],[-10,10],[-10,10]];
if(paramsQS.range) {
    range = parseFloat(paramsQS.range);
    range = [[-range, range], [-range, range], [-range, range]];
}
var camera = [3, 1.5, -1.5];
if(paramsQS.camera) {
    camera = paramsQS.camera.split(",").map(parseFloat);
}

new Demo({
    camera: {
        proxy:     true,
        position: camera,
        lookAt:   [0, 0, 0],
        up:       [0, 1, 0]
    },
    grid: false,
    popup: true,
    caption: '&nbsp;',
    viewRange: range,

}, function() {
    var self = this;
    var zero_threshold = 0.00001;

    var vector1 = [1, 1, 1]
    var vector2 = [1, -1, 2];
    var vector3 = [3, 1, 4];
    var vectors = [vector1, vector2, vector3];
    var color1 = [1, .3, 1, 1];
    var color2 = [0, 1, 0, 1];
    var color3 = [1, 1, 0, 1];
    var colors = [color1, color2, color3];
    var target = [0, 0, 0];

    // gui
    var Params = function() {
        this.z = 1.0;
        this.Axes = false;
    };
    var params = new Params();
    var gui = new dat.GUI({width: 300});
    var doAxes = gui.add(params, 'Axes');

    var coeffs = {
    };
    var changeCoeffs = function() {
        coeffs.x = -2*params.z;
        coeffs.y = -params.z;
        coeffs.z = params.z;
    };
    changeCoeffs();

    gui.add(params, 'z', -10, 10).step(0.1).onChange(changeCoeffs);

    var updateAxes = function(val) {
        mathbox.select(".axes").set("visible", val);
    };
    updateAxes();
    doAxes.onFinishChange(updateAxes);

    var ortho1 = new THREE.Vector3(vector1[0],vector1[1],vector1[2]);
    var ortho2 = new THREE.Vector3(vector2[0],vector2[1],vector2[2]);
    var ortho = [ortho1, ortho2];
    var tColor1 = new THREE.Color(color1[0], color1[1], color1[2]);
    var tColor2 = new THREE.Color(color2[0], color2[1], color2[2]);
    var tColor3 = new THREE.Color(color3[0], color3[1], color3[2]);
    var tColors = [tColor1, tColor2, tColor3];

    var tVec1 = new THREE.Vector3(vector1[0], vector1[1], vector1[2]);
    var tVec2 = new THREE.Vector3(vector2[0], vector2[1], vector2[2]);
    var tVec3 = new THREE.Vector3(vector3[0], vector3[1], vector3[2]);

    this.labeledVectors(vectors, colors, null, {});
    mathbox.select("#vectors-drawn").set('zIndex', 2);
    mathbox.select("#vector-labels").set('zIndex', 2);

    mathbox.select("#target-vectors-drawn").set('zIndex', 2);
    mathbox.select("#target-vector-labels").set('zIndex', 2);

    this.view
        .array({
            id:       "lincombo",
            channels: 3,
            width:    2,
            items:    12,
            expr: function(emit, i) {
                var vec1 = [vector1[0]*coeffs.x,
                            vector1[1]*coeffs.x,
                            vector1[2]*coeffs.x];
                var vec2 = [vector2[0]*coeffs.y,
                            vector2[1]*coeffs.y,
                            vector2[2]*coeffs.y];
                var vec3 = [vector3[0]*coeffs.z,
                            vector3[1]*coeffs.z,
                            vector3[2]*coeffs.z];
                var vec12 = [vec1[0]+vec2[0], vec1[1]+vec2[1], vec1[2]+vec2[2]];
                var vec13 = [vec1[0]+vec3[0], vec1[1]+vec3[1], vec1[2]+vec3[2]];
                var vec23 = [vec2[0]+vec3[0], vec2[1]+vec3[1], vec2[2]+vec3[2]];
                var vec123 = [vec1[0] + vec2[0] + vec3[0],
                              vec1[1] + vec2[1] + vec3[1],
                              vec1[2] + vec2[2] + vec3[2]]
                if(i == 0) {
                    // starting points of lines
                    emit(0, 0, 0);
                    emit(0, 0, 0);
                    emit(0, 0, 0);
                    emit.apply(null, vec1);
                    emit.apply(null, vec1);
                    emit.apply(null, vec2);
                    emit.apply(null, vec2);
                    emit.apply(null, vec3);
                    emit.apply(null, vec3);
                    emit.apply(null, vec12);
                    emit.apply(null, vec13);
                    emit.apply(null, vec23);
                }
                else {
                    // ending points of lines
                    emit.apply(null, vec1);
                    emit.apply(null, vec2);
                    emit.apply(null, vec3);
                    emit.apply(null, vec12);
                    emit.apply(null, vec13);
                    emit.apply(null, vec12);
                    emit.apply(null, vec23);
                    emit.apply(null, vec13);
                    emit.apply(null, vec23);
                    emit.apply(null, vec123);
                    emit.apply(null, vec123);
                    emit.apply(null, vec123);
                }
            }
        })
        .array({
            id:       "lincombo-colors",
            channels: 4,
            width:    2,
            items:    12,
            data:     [color1, color2, color3, color2, color3, color1,
                       color3, color1, color2, color3, color2, color1,
                       color1, color2, color3, color2, color3, color1,
                       color3, color1, color2, color3, color2, color1],
        })
        .line({
            classes: ["linear-combo"],
            points:  "#lincombo",
            color:   "white",
            colors:  "#lincombo-colors",
            opacity: 0.75,
            width:   3,
            zIndex:  1,
        })
    ;

    this.view
        .array({
            channels: 3,
            width:    1,
            data:     [[0, 0, 0]],
        })
        .point({
            color:  "white",
            size:   20,
            zIndex: 3,
        })
        .text({
            live:  true,
            width: 1,
            expr: function(emit) {
                var ret = coeffs.x.toFixed(2) + "v1";
                var b = Math.abs(coeffs.y);
                var add = coeffs.y >= 0 ? "+" : "-";
                ret += add + b.toFixed(2) + "v2";
                var c = Math.abs(coeffs.z);
                var add = coeffs.z >= 0 ? "+" : "-";
                ret += add + c.toFixed(2) + "v3";
                emit(ret);
            },
        })
        .label({
            classes: ["linear-combo"],
            outline: 0,
            color:  "rgb(0,255,255)",
            offset:  [0, -25],
            size:    15,
            zIndex:  3,
        })
    ;

    // Spanning surface stuff
    var surfaceColor = new THREE.Color(0.5, 0, 0);
    var surfaceOpacity = 0.5;

    var clipped = this.clipCube({
        drawCube: true,
        wireframeColor: new THREE.Color(.75, .75, .75),
        material: new THREE.MeshBasicMaterial({
            color:       surfaceColor,
            opacity:     0.5,
            transparent: true,
            visible:     true,
            depthWrite:  false,
            depthTest:   true,
        }),
    });

    clipped
        .matrix({
            channels: 3,
            live:     false,
            width:    2,
            height:   2,
            expr: function (emit, i, j) {
                if(i == 0) i = -1;
                if(j == 0) j = -1;
                i *= 30; j *= 30;
                emit(ortho1.x * i + ortho2.x * j,
                     ortho1.y * i + ortho2.y * j,
                     ortho1.z * i + ortho2.z * j);
            },
        })
        .surface({
            color:   surfaceColor,
            opacity: surfaceOpacity,
            stroke:  "solid",
            width:   5,
        })
    ;

    var colorize = function(col, text) {
        return "\\color{#" + col.getHexString() + "}{" + text + "}";
    };

    var eqn = "x" + colorize(tColor1, this.render_vec(vector1));
    eqn    += "+ y" + colorize(tColor2, this.render_vec(vector2));
    eqn    += "+ z" + colorize(tColor3, this.render_vec(vector3));

    eqn += "= " + this.render_vec([0,0,0]);

    this.label.innerHTML = katex.renderToString(eqn);
});

