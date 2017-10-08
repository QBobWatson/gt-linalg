## /* -*- javascript -*-

<%! draggable=True %>

<%inherit file="base.mako"/>

<%block name="title">A vector by coordinates</%block>

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
    axes: false,
//    caption: katex.renderToString("\\color{#00ff00}v = \\begin{bmatrix}a\\\\b\\\\c\\end{bmatrix}") + "<br><br>[click and drag the arrow head and tail]",
    caption: '<span id="vector-here"></span><br><br>[click and drag the arrow head and tail]',

}, function() {
    var self = this;

    var origin = [0,0,0];
    var origins = [origin];
    var vector = [5, 3, 4];
    var vectors = [vector];
    var color = [0, 1, 0, 1];
    var colors = [color];

    this.labeledVectors(vectors, colors, ['v'], {
        zeroPoints: true,
        origins: origins,
    });

    this.view
    // linear combination
        .array({
            channels: 3,
            width:    4,
            expr: function(emit, i) {
                switch(i) {
                case 0:
                    emit.apply(null, origin);
                    break;
                case 1:
                    emit(vector[0], origin[1], origin[2]);
                    break;
                case 2:
                    emit(vector[0], vector[1], origin[2]);
                    break;
                case 3:
                    emit.apply(null, vector);
                    break;
                }
            },
        })
        .line({
            classes: ["linear-combo"],
            color:   "yellow",
            opacity: 0.75,
            width:   4,
            zIndex:  1,
        })
    // labels
        .array({
            channels: 3,
            width:    3,
            expr: function(emit, i) {
                switch(i) {
                case 0:
                    emit((origin[0] + vector[0])/2, origin[1], origin[2]);
                    break;
                case 1:
                    emit(vector[0], (origin[1] + vector[1])/2, origin[2]);
                    break;
                case 2:
                    emit(vector[0], vector[1], (origin[2] + vector[2])/2);
                    break;
                }
            },
        })
        .text({
            live:  true,
            width: 3,
            expr: function(emit, i) {
                emit((vector[i] - origin[i]).toFixed(2));
            },
        })
        .label({
            outline: 0,
            color:  "yellow",
            offset:  [25, 0],
            size:    15,
        })
    ;

    // gui
    var Params = function() {
        this.a = vector[0];
        this.b = vector[1];
        this.c = vector[2];
    };
    var params = new Params();
    var gui = new dat.GUI();
    var a = gui.add(params, 'a', -10, 10).step(0.1).listen();
    var b = gui.add(params, 'b', -10, 10).step(0.1).listen();
    var c = gui.add(params, 'c', -10, 10).step(0.1).listen();

    var update = function() {
        vector[0] = params.a + origin[0];
        vector[1] = params.b + origin[1];
        vector[2] = params.c + origin[2];
        katex.render("\\color{#00ff00}v = \\begin{bmatrix}"
                     +params.a.toFixed(2)+"\\\\"
                     +params.b.toFixed(2)+"\\\\"
                     +params.c.toFixed(2)+"\\end{bmatrix}",
                     document.getElementById("vector-here"));
    };
    a.onChange(update);
    b.onChange(update);
    c.onChange(update);
    update();

    // Make the vectors draggable
    var drag = new Draggable({
        view:   this.view,
        points: [origin, vector],
        size:   30,
        hiliteColor: [0, 1, 1, .75],
        onDrag: function(vec) {
            if(drag.dragging == 0) {
                // dragging tail
                vector[0] = vec.x + params.a;
                vector[1] = vec.y + params.b;
                vector[2] = vec.z + params.c;
            } else {
                // dragging head
                vec.clampScalar(-10, 10);
                params.a = vec.x - origin[0];
                params.b = vec.y - origin[1];
                params.c = vec.z - origin[2];
                update();
            }
        },
    });

});

