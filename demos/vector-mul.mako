## /* -*- javascript -*-

<%! draggable=True %>

<%inherit file="base.mako"/>

<%block name="title">Vector multiplication</%block>

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
    caption: "[Drag the vector head with the mouse to move it]",
    axes: false,

}, function() {
    var self = this;

    var vector1 = [3, -5, 4];
    var vector2 = [3*1.5, -5*1.5, 4*1.5];
    var color1 = [1, .3, 1, 1];
    var color2 = [1, 1, 0, 1];

    this.labeledVectors([vector1], [color1], ['v'], {
        vectorWidth: 10,
    });

    this.labeledVectors([vector2], [color2], ['v'], {
        prefix: 'scaled-',
        zeroPoints: true,
    });

    mathbox.select("#scaled-text").set('live', true);
    mathbox.select("#scaled-text").bind('data', function() {
        return [params.c.toFixed(2) + 'v'];
    });

    // Make the vectors draggable
    new Draggable({
        view:   this.view,
        points: [vector1],
        size:   30,
        hiliteColor: [0, 1, 1, .75],
        onDrag: function(vec) {
            vec.clampScalar(-10, 10);
            vector2[0] = vector1[0] * params.c;
            vector2[1] = vector1[1] * params.c;
            vector2[2] = vector1[2] * params.c;
            self.zeroPoints.set(
                'visible', (vector2[0] == 0 && vector2[1] == 0 && vector2[2] == 0));
        },
    });

    // gui
    var Params = function() {
        this.c = 1.5;
    };
    var params = new Params();
    var gui = new dat.GUI();
    gui.add(params, 'c', -10, 10).step(0.1).onChange(function() {
        vector2[0] = vector1[0] * params.c;
        vector2[1] = vector1[1] * params.c;
        vector2[2] = vector1[2] * params.c;
        self.zeroPoints.set(
            'visible', (vector2[0] == 0 && vector2[1] == 0 && vector2[2] == 0));
    });
});

