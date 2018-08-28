## -*- coffee -*-

<%inherit file="base2.mako"/>

<%block name="title">Parametric Form</%block>

##

plane1Color = new Color "violet"
plane2Color = new Color "green"
lineColor   = new Color "yellow"
pointColor  = new Color "red"

new Demo camera: position: [-1.3,3,1.5], () ->
    window.mathbox = @mathbox

    view = @view()

    updateCaption = () =>
        str = "(x, y, z) = (t, 1-2t, t) = \\color{#{pointColor.str()}}{"
        str += "({#{params.z.toFixed 2}},\\," \
            +  " {#{(1-2*params.z).toFixed 2}},\\," \
            +  " {#{params.z.toFixed 2}})}"
        katex.render str, @vecElt

    # gui
    params = z: 0.0
    gui = new dat.GUI()
    gui.add(params, 'z', -4.5, 5.5).step(0.1).onChange updateCaption

    clipCube = @clipCube view,
        draw:   true

    # Plane 1
    subspace1 = @subspace
        vectors: [[-1, 1, 0], [-1, 0, 1]]
        color: plane1Color
        live: false
        name: "plane1"
    subspace1.draw clipCube.clipped.transform position: [1, 0, 0]

    # Plane 2
    subspace2 = @subspace
        vectors: [[1, 0 ,1], [0, 1, 0]]
        color: plane2Color
        live: false
        name: "plane2"
    subspace2.draw clipCube.clipped

    # Intersection
    subspace3 = @subspace
        vectors: [[1, -2, 1]]
        color:   lineColor
        lineOpts:
            opacity: 1.0
            width:   4
            zIndex:  3
        name: "line"
        live: false
    subspace3.draw clipCube.clipped.transform position: [0, 1, 0]

    # Parameterized point
    view
        .array
            channels: 3
            width:    1
            expr: (emit) ->
                emit params.z, 1 - 2*params.z, params.z
        .point
            color:  pointColor.arr()
            size:   15
            zIndex: 3
            zTest:  false
        .format
            expr: (x, y, z) ->
                "(" + x.toPrecision(2) + ", " \
                    + y.toPrecision(2) + ", " \
                    + z.toPrecision(2) + ")"
        .label
            outline:    0
            color:      pointColor.arr()
            offset:     [0,20]
            size:       13
            zIndex:     3

    # Caption
    @caption '''<p><span id="eqn1-here"></span><br>
                   <span id="eqn2-here"></span></p>
                <p><span id="vec-here"></span></p>
             '''
    katex.render "\\color{#{plane1Color.str()}}{x + y + z = 1}",
                 document.getElementById 'eqn1-here'
    katex.render "\\color{#{plane2Color.str()}}{x \\phantom{+} \\phantom{y} - z = 0}",
                 document.getElementById 'eqn2-here'
    @vecElt = document.getElementById 'vec-here'
    updateCaption()

