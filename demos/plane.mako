## /* -*- javascript -*-

<%inherit file="base.mako"/>

<%block name="title">A Plane</%block>

## */

new Demo({
    camera: {
        proxy:     true,
        position: [-1.5, 1.5, -3],
        lookAt:   [0, 0, 0],
        up:       [0, 1, 0]
    },
    caption: katex.renderToString("x + y + z = 1")
        + "<br>" + katex.renderToString("(x,\\,y,\\,z) = (1-y-z,\\,y,\\,z)"),
}, function() {

    // gui
    var Params = function() {
        this.y = 0.0;
        this.z = 0.0;
    };
    var params = new Params();
    var gui = new dat.GUI();
    gui.add(params, 'y', -10, 10).step(0.1);
    gui.add(params, 'z', -10, 10).step(0.1);

    // Plane
    this.view
        .matrix({
            channels: 3,
            live:     false,
            width:    21,
            height:   21,
            expr: function (emit, i, j) {
                i -= 10;  j -= 10;
                emit(1-i-j, i, j);
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
    // Parameterized point
        .array({
            channels: 3,
            width:    1,
            expr:     function(emit) {
                emit(1 - params.y - params.z, params.y, params.z);
            }
        })
        .point({
            color:  "rgb(0,200,0)",
            size:   15,
            zIndex: 2,
        })
        .format({
            expr: function(x, y, z) {
                return "(" + x.toPrecision(2) + ", "
                    + y.toPrecision(2) + ", "
                    + z.toPrecision(2) + ")";
            }
        })
        .label({
            outline: 2,
            background: "black",
            color:   "white",
            offset:  [0,20],
            size:    20,
            zIndex:  2
        })
    ;

});
