## -*- coffee -*-

<%inherit file="base2.mako"/>

<%block name="title">A Plane</%block>

##

pointColor   = new Color "red"
surfaceColor = new Color "violet"

plainPlane = @urlParams.plainplane?

new Demo {}, () ->
    window.mathbox = @mathbox

    coeffs = @urlParams.get 'coeffs', 'str[]', ['y', 'z']
    cf = (i) -> params[coeffs[i]]

    if plainPlane
        updateCaption = () ->
    else
        updateCaption = () =>
            katex.render """(x,\\,y,\\,z)
                              = (1-#{coeffs[0]}-#{coeffs[1]},\\,#{coeffs[0]},\\,#{coeffs[1]})
                              = \\color{#{pointColor.str()}}{({#{(1-cf(0)-cf(1)).toFixed(2)}},\\,
                                 {#{cf(0).toFixed(2)}},\\,
                                 {#{cf(1).toFixed(2)}})}
                         """, @vecElt

    vectors = [[-1, 1, 0], [-1, 0, 1]]

    if not plainPlane
        # gui
        params = {}
        params[coeffs[0]] = 0.0
        params[coeffs[1]] = 0.0
        gui = new dat.GUI()
        gui.add(params, coeffs[0], -10, 10).step(0.1).onChange updateCaption
        gui.add(params, coeffs[1], -10, 10).step(0.1).onChange updateCaption

    view = @view()

    # Plane
    clipCube = @clipCube view,
        draw:   true
        hilite: false
    trans = clipCube.clipped.transform position: [1, 0, 0]

    subspace = @subspace
        vectors: vectors
        live:    false
        color:   surfaceColor
    subspace.draw trans

    @grid trans,
        vectors: vectors
        lineOpts: color: surfaceColor

    if not plainPlane
        # Parameterized point
        view
            .array
                channels: 3
                width:    1
                expr: (emit) ->
                    emit 1 - cf(0) - cf(1), cf(0), cf(1)
            .point
                color:  pointColor.arr()
                size:   15
                zTest:  false
                zWrite: false
            .format
                expr: (x, y, z) ->
                    "(" + x.toPrecision(2) + ", " \
                        + y.toPrecision(2) + ", " \
                        + z.toPrecision(2) + ")"
            .label
                color:      pointColor.arr()
                offset:     [0,20]
                size:       13
                outline:    0
                zTest:      false
                zWrite:     false

    # Caption
    if plainPlane
        @caption '''<p><span id="eqn-here"></span></p>'''
    else
        @caption '''<p><span id="eqn-here"></span></p>
                    <p><span id="vec-here"></span></p>
                 '''
        @vecElt = document.getElementById 'vec-here'
    katex.render "\\color{#{surfaceColor.str()}}{x+y+z=1}",
        document.getElementById 'eqn-here'
    updateCaption()
