## -*- coffee -*-

<%inherit file="base2.mako"/>

<%block name="title">Dynamics of a 2x2 matrix</%block>

##

new Demo2D {}, () ->
    dynamics.mathbox = window.mathbox = @mathbox

    # Un-transformed view
    dynamics.view0 = @view
        grid: false
        axes: false

    # Transformed view
    dynamics.view = view0.transform matrix: [1,-1, 0, 0,
                                            -1, 1, 0, 0,
                                             0, 0, 1, 0,
                                             0, 0, 0, 1]

    cube = @clipCube view0,
        hilite: false
        draw:   false

