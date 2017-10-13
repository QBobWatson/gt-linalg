## -*- coffee -*-

<%! datgui=False %>

<%inherit file="base2.mako"/>

<%block name="title">Two Planes Intersecting</%block>

##

new Demo camera: position: [-1.3,3,1.5], ()->
    view = @view()

    # Plane 1
    view
        .matrix
            channels: 3
            live:     false
            width:    21
            height:   21
            expr: (emit, i, j) ->
                i -= 10
                j -= 10
                emit i, j, 1-i-j
        .surface
            color:   "rgb(128,0,0)"
            opacity: 0.75
            stroke:  "solid"
            lineX:   true
            lineY:   true
            width:   3
            fill:    false
        .surface
            color:   "rgb(128,0,0)"
            opacity: 0.5
            stroke:  "solid"
    # Plane 2
        .matrix
            channels: 3
            live:     false
            width:    21
            height:   21
            expr: (emit, i, j) ->
                i -= 10
                j -= 10
                emit(i, j, i)
        .surface
            color:   "rgb(0,128,0)"
            opacity: 0.75
            stroke:  "solid"
            lineX:   true
            lineY:   true
            width:   3
            fill:    false
        .surface
            color:   "rgb(0,128,0)"
            opacity: 0.5
            stroke:  "solid"

    # Intersection
        .array
            channels: 3
            live:     false
            width:    2
            data:     [[11/2, -10, 11/2], [-9/2, 10, -9/2]]
        .line
            color:   "rgb(200,200,0)"
            opacity: 1.0
            stroke:  "solid"
            width:   4
            zIndex:  2

    @caption '<p><span id="eqn1-here"></span><br><span id="eqn2-here"></span></p>'
    katex.render "\\color{red}{x+y+z=1}", document.getElementById 'eqn1-here'
    katex.render "\\color{green}{x-z=0}", document.getElementById 'eqn2-here'
