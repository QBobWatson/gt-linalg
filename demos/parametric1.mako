## -*- coffee -*-

<%inherit file="base2.mako"/>

<%block name="title">Parametric Form</%block>

##

plane1Color = new Color "violet"
plane2Color = new Color "green"
lineColor   = new Color "yellow"
pointColor  = new Color "red"

new Demo {camera: position: [1.5, 3, 1.5]}, () ->
    window.mathbox = @mathbox

    view = @view viewRange: [[-10, 10], [-10, 10], [-3, 3]]

    updateCaption = () =>
        str = "(x, y, z) = (1-5z,\\, {-1}-2z,\\, z) = \\color{#{pointColor.str()}}{"
        str += "({#{(1-5*params.z).toFixed 2}},\\," \
            +  " {#{(-1-2*params.z).toFixed 2}},\\," \
            +  " {#{params.z.toFixed 2}})}"
        katex.render str, @vecElt

    # gui
    params = z: 0.0
    gui = new dat.GUI()
    gui.add(params, 'z', -9/5, 11/5).step(0.1).onChange updateCaption

    clipCube = @clipCube view,
        draw:   true

    # Plane 1
    subspace1 = @subspace
        vectors: [[-1/2, 1, 0], [-6, 0, 1]]
        color: plane1Color
        live: false
        name: "plane1"
    subspace1.draw clipCube.clipped.transform position: [1/2, 0, 0]

    # Plane 2
    subspace2 = @subspace
        vectors: [[-2, 1, 0], [-9, 0, 1]]
        color: plane2Color
        live: false
        name: "plane2"
    subspace2.draw clipCube.clipped.transform position: [-1, 0, 0]

    # Intersection
    subspace3 = @subspace
        vectors: [[-5, -2, 1]]
        color:   lineColor
        lineOpts:
            opacity: 1.0
            width:   4
            zIndex:  3
        name: "line"
        live: false
    subspace3.draw clipCube.clipped.transform position: [1, -1, 0]

    # Parameterized point
    view
        .array
            channels: 3
            width:    1
            expr: (emit) ->
                emit 1 - 5*params.z, -1 - 2*params.z, params.z
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
    katex.render "\\color{#{plane1Color.str()}}{2x + \\phantom{2}y + 12z = 1}",
                 document.getElementById 'eqn1-here'
    katex.render "\\color{#{plane2Color.str()}}{\\phantom{2}x + 2y + \\phantom{1}9z = -1}",
                 document.getElementById 'eqn2-here'
    @vecElt = document.getElementById 'vec-here'
    updateCaption()

