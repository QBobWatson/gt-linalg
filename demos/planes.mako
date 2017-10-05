## /* -*- javascript -*-

<%! datgui=False %>

<%inherit file="base.mako"/>

<%block name="title">Two Planes Intersecting</%block>

## */

new Demo({
    camera: {
        proxy:     true,
        position: [1.5, 1.5, -3],
        lookAt:   [0, 0, 0],
        up:       [0, 1, 0]
    },
    caption: katex.renderToString("\\color{red}{x + y + z = 1}")
        + "<br>" + katex.renderToString("\\color{green}{x - z = 0}")
}, function() {

    // Plane 1
    this.view
        .matrix({
            channels: 3,
            live:     false,
            width:    21,
            height:   21,
            expr: function (emit, i, j) {
                i -= 10;  j -= 10;
                emit(i, j, 1-i-j);
            }
        })
        .surface({
            color:   "rgb(128,0,0)",
            opacity: 0.75,
            stroke:  "solid",
            lineX:   true,
            lineY:   true,
            width:   3,
            fill:    false,
        })
        .surface({
            color:   "rgb(128,0,0)",
            opacity: 0.5,
            stroke:  "solid",
        })
    // Plane 2
        .matrix({
            channels: 3,
            live:     false,
            width:    21,
            height:   21,
            expr: function (emit, i, j) {
                i -= 10;  j -= 10;
                emit(i, j, i);
            }
        })
        .surface({
            color:   "rgb(0,128,0)",
            opacity: 0.75,
            stroke:  "solid",
            lineX:   true,
            lineY:   true,
            width:   3,
            fill:    false,
        })
        .surface({
            color:   "rgb(0,128,0)",
            opacity: 0.5,
            stroke:  "solid",
        })

    // Intersection
        .array({
            channels: 3,
            live:     false,
            width:    2,
            data:     [[11/2, -10, 11/2], [-9/2, 10, -9/2]],
        })
        .line({
            color:   "rgb(200,200,0)",
            opacity: 1.0,
            stroke:  "solid",
            width:   4,
            zIndex:  2
        })
    ;

});
