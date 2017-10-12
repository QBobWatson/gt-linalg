## -*- coffee -*-

<%inherit file="base2.mako"/>

<%block name="title">A Plane</%block>

##

new Demo {}, () ->
    window.mathbox = @mathbox

    updateCaption = () =>
        katex.render """(x,\\,y,\\,z) = (1-y-z,\\,y,\\,z)
                          = (#{(1-params.y-params.z).toFixed(2)},\\,
                             #{params.y.toFixed(2)},\\,
                             #{params.z.toFixed(2)})
                     """, @vecElt

    # gui
    params =
        y: 0.0
        z: 0.0
    gui = new dat.GUI()
    gui.add(params, 'y', -10, 10).step(0.1).onChange updateCaption
    gui.add(params, 'z', -10, 10).step(0.1).onChange updateCaption

    # Plane
    view = @view()
    view
        .matrix
            channels: 3
            live:     false
            width:    21
            height:   21
            expr: (emit, i, j) ->
                i -= 10
                j -= 10
                emit(1-i-j, i, j)
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
    # Parameterized point
        .array
            channels: 3
            width:    1
            expr: (emit) ->
                emit 1 - params.y - params.z, params.y, params.z
        .point
            color:  "rgb(0,200,0)"
            size:   15
            zTest:      false
            zWrite:     false
        .format
            expr: (x, y, z) ->
                "(" + x.toPrecision(2) + ", " \
                    + y.toPrecision(2) + ", " \
                    + z.toPrecision(2) + ")"
        .label
            outline:    2
            background: "black"
            color:      "white"
            offset:     [0,20]
            size:       20
            zTest:      false
            zWrite:     false

    # Caption
    @caption '''<p><span id="eqn-here"></span></p>
                <p><span id="vec-here"></span></p>
             '''
    katex.render "\\color{red}{x+y+z=1}", document.getElementById 'eqn-here'
    @vecElt = document.getElementById 'vec-here'
    updateCaption()
