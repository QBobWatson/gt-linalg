## -*- coffee -*-

<%inherit file="base2.mako"/>

<%block name="title">Two Planes Intersecting</%block>

##

new Demo camera: position: [-1.3,3,1.5], () ->
    window.mathbox = @mathbox

    view = @view()

    clipCube = @clipCube view,
        draw:   true
        color:  new THREE.Color .75, .75, .75

    # Plane 1
    subspace1 = @subspace
        vectors: [[-1, 1, 0], [-1, 0, 1]]
        live: false
        name: "plane1"
    subspace1.draw clipCube.clipped.transform position: [1, 0, 0]

    # Plane 2
    subspace2 = @subspace
        vectors: [[1, 0 ,1], [0, 1, 0]]
        surfaceOpts: color: "rgb(0, 128, 0)"
        live: false
        name: "plane2"
    subspace2.draw clipCube.clipped

    # Line
    subspace3 = @subspace
        vectors: [[1, -2, 1]]
        lineOpts:
            color:   "rgb(200, 200, 0)"
            opacity: 1.0
            width:   4
            zIndex:  3
        name: "line"
        live: false
    subspace3.draw clipCube.clipped.transform position: [0, 1, 0]

    @caption '<p><span id="eqn1-here"></span><br><span id="eqn2-here"></span></p>'
    katex.render "\\color{red}{x+y+z=1}", document.getElementById 'eqn1-here'
    katex.render "\\color{green}{x-z=0}", document.getElementById 'eqn2-here'
