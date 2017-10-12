## /* -*- javascript -*-

<%! draggable=True %>

<%inherit file="base.mako"/>

<%block name="title">Projection onto the xy-plane</%block>

## */

new Demo({
    viewRange: [[-10, 10], [-10, 10], [-10, 10]],
    caption: katex.renderToString(
        "A = \\begin{bmatrix} 1 & 0 & 0 \\\\ 0 & 1 & 0 \\\\ 0 & 0 & 0 \\end{bmatrix}")
        + '<span id="vectors-here"></span>',
//            + "\\qquad A\\color{#00ff00}{x} = \\color{#ffff00}{b}"),
    camera: {
        proxy:    true,
        position: [-1, 1.5, -2.5],
        lookAt:   [0, 0, 0],
        up:       [0, 1, 0]
    }
}, function() {

    var vector = [-1, 2, 3];
    var out = [-1, 2, 0];
    var vectors = [vector, out];

    // Labeled vectors
    this.view
        .array({
            channels: 3,
            width:    2,
            items:    2,
            data:     [[0, 0, 0], vector,
                       [0, 0, 0], out],
        })
        .array({
            id:       "colors",
            channels: 4,
            width:    2,
            data:     [[0, 1, 0, 1], [1, 1, 0, 1]],
        })
        .vector({
            points: "<<",
            colors: "<",
            color:  "white",
            end:    true,
            size:   5,
            width:  5,
        })
        .array({
            channels: 3,
            width:    2,
            expr: function(emit, i) {
                emit(vectors[i][0]/2, vectors[i][1]/2, vectors[i][2]/2);
            },
        })
        .text({
            live:  false,
            width: 2,
            data:  ['x', 'b'],
        })
        .label({
            outline: 0,
            colors:  "#colors",
            color:   "white",
            offset:  [0, 25],
            size:    15,
        })
    ;

    this.view
        .array({
            channels: 3,
            width:    2,
            items:    1,
            data:     vectors,
        })
        .line({
            color:   "white",
            opacity: 0.75,
            width:   1,
        })
    ;

    var vectorSpan = document.getElementById("vectors-here");

    function updateCaption() {
        katex.render(
            "\\qquad A\\color{#00ff00}{"
                + "\\begin{bmatrix}"
                + vector[0].toFixed(2) + "\\\\"
                + vector[1].toFixed(2) + "\\\\"
                + vector[2].toFixed(2)
                + "\\end{bmatrix}} = \\color{#ffff00}{"
                + "\\begin{bmatrix}"
                + out[0].toFixed(2) + "\\\\"
                + out[1].toFixed(2) + "\\\\"
                + "0.00"
                + "\\end{bmatrix}}",
            vectorSpan);
    }
    updateCaption();

    function onDrag(vec) {
        out[0] = vector[0];
        out[1] = vector[1];

        updateCaption();
    }

    // Make the vector draggable
    var draggable = new Draggable({
        view:    this.view,
        points:  [vector],
        size:    30,
        hiliteColor: [0, 1, 1, .75],
        onDrag:  onDrag,
    });

});
