## -*- coffee -*-

<%inherit file="base2.mako"/>

<%block name="title">Empty axes</%block>

##

new Demo {}, () ->
    view = @view()
    window.mathbox = @mathbox

    @caption "Test caption"

    cube = @clipCube view,
        draw:    true
        color:   new THREE.Color .75, .75, .75
        hilite:  true

    cube.clipped
        .matrix
            channels: 3
            width:    2
            height:   2
            data: [[[-20, -20, -18], [-20, 20, 18]],
                   [[20, -20, -18], [20, 20, 18]]]
        .surface
            color:   0x880000
            opacity: 0.5
            stroke:  "solid"
