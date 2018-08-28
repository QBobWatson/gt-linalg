## -*- coffee -*-

<%inherit file="base2.mako"/>

<%block name="title">Two Planes Intersecting</%block>

##

plane1Color = new Color "violet"
plane2Color = new Color "green"
lineColor   = new Color "red"

new Demo camera: position: [-1.3,3,1.5], () ->
    window.mathbox = @mathbox

    view = @view()

    clipCube = @clipCube view,
        draw:   true

    # Plane 1
    subspace1 = @subspace
        vectors: [[-1, 1, 0], [-1, 0, 1]]
        live:    false
        name:    "plane1"
        color:   plane1Color
    subspace1.draw clipCube.clipped.transform position: [1, 0, 0]

    # Plane 2
    subspace2 = @subspace
        vectors: [[1, 0 ,1], [0, 1, 0]]
        live:    false
        name:    "plane2"
        color:   plane2Color
    subspace2.draw clipCube.clipped

    # Line
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

    @caption '<p><span id="eqn1-here"></span><br><span id="eqn2-here"></span></p>'
    katex.render "\\color{#{plane1Color.str()}}{x+y+z=1}", document.getElementById 'eqn1-here'
    katex.render "\\color{#{plane2Color.str()}}{x \\phantom{+} \\phantom{y} - z = 0}", document.getElementById 'eqn2-here'
