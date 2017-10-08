## /* -*- javascript -*-

<%! draggable=True %>
<%! datgui=False %>

<%inherit file="base.mako"/>

<%block name="title">Vector addition</%block>

## */

new Demo({
    mathbox: {
        plugins: ['core', 'controls'],
        controls: {
            klass: THREE.OrbitControls,
            parameters: {
                // noZoom: true,
            }
        },
        mathbox: {
            warmup: 10,
            splash: false,
            inspect: false,
        },
        splash: {fancy: true, color: "blue"},
    },
    camera: {
        proxy:     true,
        position: [-1.5, 1.5, -3],
        lookAt:   [0, 0, 0],
        up:       [0, 1, 0]
    },
    caption: katex.renderToString("\\color{#ff4dff}v + \\color{#00ff00}w")
        + "<br><br>[Drag the vector heads with the mouse to move them]",
    axes: false,

}, function() {
    var self = this;

    var vector1 = [3, -5,  4];
    var vector2 = [4, -1, -2];
    var vector3 = [vector1[0]+vector2[0], vector1[1]+vector2[1], vector1[2]+vector2[2]];
    var vectors = [vector1, vector2, vector3, vector3, vector3];
    var color1 = [1, .3, 1, 1];
    var color2 = [0, 1, 0, 1];
    var color3 = [1, 1, 0, 1];
    var colors = [color1, color2, color1, color2, color3];
    var origins = [[0, 0, 0], [0, 0, 0], vector2, vector1, [0, 0, 0]];

    this.labeledVectors(vectors, colors, ['v', 'w', 'v', 'w', 'v+w'], {
        origins: origins,
    });
    // Make the vectors draggable
    new Draggable({
        view:   this.view,
        points: [vector1, vector2],
        size:   30,
        hiliteColor: [0, 1, 1, .75],
        onDrag: function(vec) {
            vec.clampScalar(-10, 10);
            vector3[0] = vector1[0] + vector2[0];
            vector3[1] = vector1[1] + vector2[1];
            vector3[2] = vector1[2] + vector2[2];
        },
    });

});

