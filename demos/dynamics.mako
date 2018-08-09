## -*- coffee -*-

<%inherit file="base2.mako"/>

<%block name="title">Matrix Dynamics</%block>

<%block name="inline_style">
${parent.inline_style()}
html, body {
    margin:           0;
    height:           100%;
    background-color: white;
    overflow-x:       hidden;
}
#mathbox {
    width:       100%;
    height:      100%;
}
.espace-1 {
    color: var(--palette-green);
}
.espace-2 {
    color: var(--palette-violet);
}
.espace-3 {
    color: var(--palette-brown);
}
.overlay-text {
    z-index: 1;
}
#mult-here.hidden {
    display: none;
}
</%block>

<%block name="body_html">
<%block name="overlay_text"/>
<div id="mathbox">
</div>
</%block>

<%block name="js">
    ${parent.js()}
    <script src="${"js/dynamics.js" | vers}"></script>
</%block>

##

# TODO:
#  * Similarity diptych

######################################################################
# * URL parameters:
#
# + matrix: a 2x2 matrix.  If this is a 3D demo, this is the 2x2 part of a
#   block diagonal form.
# + eigenz: for 3D, this is the (real) third eigenvalue
# + v1, v2, v3: for 3D, this is the basis with respect to the block-diagonal
#   matrix is specified.
# + vec: display test vector
# + path: display test path
#
# + duration: animation time
# + matname: matrix name
# + testmat, flow: for testing

matrix = urlParams.get 'mat', 'matrix', [[ 1/2, 1/2],
                                         [-1/2, 1/2]]

duration = urlParams.get 'duration', 'float', 2.5
matName = urlParams.matname ? 'A'

size = if urlParams.eigenz? then 3 else 2
eigenz = urlParams.get 'eigenz', 'float', 1
v1 = urlParams.get 'v1', 'float[]', [1,0,0]
v2 = urlParams.get 'v2', 'float[]', [0,1,0]
v3 = urlParams.get 'v3', 'float[]', [0,0,1]


######################################################################
# * Test matrices

testMatrices =
    Shear:         [[2/3,   1/3 ], [-1/3,  4/3 ]]
    ScaleOutShear: [[5/3,   1/3 ], [-1/3,  7/3 ]]
    ScaleInShear:  [[1/3,   1/6 ], [-1/6,  2/3 ]]
    Circle:        [[1/3,  -1/3 ], [ 5/6,  2/3 ]]
    SpiralIn:      [[1/3,  -1/3 ], [ 5/6,  2/3 ]]
    SpiralOut:     [[2/3,  -2/3 ], [ 5/3,  4/3 ]]
    AttractLine:   [[5/6,   1/6 ], [ 1/3,  2/3 ]]
    RepelLine:     [[4/3,  -1/3 ], [-2/3,  5/3 ]]
    Attract:       [[7/18, -1/18], [-1/9,  4/9 ]]
    Repel:         [[8/3,   1/3 ], [ 2/3,  7/3 ]]
    Hyperbolas:    [[8/9,  -5/9 ], [-10/9, 13/9]]

for row in testMatrices.Circle
    row[0] *= Math.sqrt 2
    row[1] *= Math.sqrt 2

if urlParams.testmat?
    matrix = testMatrices[urlParams.testmat]


######################################################################
# * Compute standard form of the 2x2 block matrix

[[a, b], [c, d]] = matrix
trace = a + d
determinant = a*d - b*c
discriminant = trace*trace - 4*determinant

# These are the parameters that are computed below
basis1 = []
basis2 = []
type = null
opts = {}
axisColors = [new Color("green") .arr(1),
              new Color("violet").arr(1),
              new Color("brown") .arr(1)]
eigenStrs = []

almostZero = (x) -> Math.abs(x) < 1e-5

normalize = (b) ->
    n = Math.sqrt(b[0]*b[0] + b[1]*b[1])
    [b[0]/n, b[1]/n]


if almostZero determinant
    throw "Can't handle non-invertible matrix"

# One real eigenvalue
if almostZero discriminant
    λ = trace / 2
    if λ < 0
        throw "Can't handle negative real eigenvalues"
    # Diagonalizable iff it's a scalar matrix
    if almostZero(b) and almostZero(c)
        basis1 = [1, 0]
        basis2 = [0, 1]
        axisColors[1] = axisColors[0]
        eigenStrs.push "The whole plane is the <span class=\"espace-1\">" +
                       "#{λ.toFixed 2}-eigenspace.</span>"
        type = if λ > 1 then dynamics.Repel else dynamics.Attract
        opts =
            λ1: λ
            λ2: λ
    # Shear: put it in the form [λ, λ*a, 0, λ]
    else
        if almostZero b
            basis1 = normalize [λ-d, c]
        else
            basis1 = normalize [b, λ-a]
        basis2 = [basis1[1], -basis1[0]]  # Anything linearly independent
        axisColors[1] = [0.5, 0.5, 0.5, 0.3]
        eigenStrs.push "This is the <span class=\"espace-1\">" +
                       "#{λ.toFixed 2}-eigenspace.</span>"
        # (matrix - λ) * basis2 = (λ * translate) basis1
        v = [(a-λ)*basis2[0] + b*basis2[1], c*basis2[0] + (d-λ)*basis2[1]]
        if almostZero basis1[0]
            opts.translate = v[1] / (λ*basis1[1])
        else
            opts.translate = v[0] / (λ*basis1[0])
        if almostZero (λ-1)
            type = dynamics.Shear
        else
            if λ > 1
                type = dynamics.ScaleOutShear
            else
                type = dynamics.ScaleInShear
            opts.scale = λ

# Rotation-scaling matrix
else if discriminant < 0
    Reλ = trace / 2
    Imλ = Math.sqrt(-discriminant) / 2
    basis1 = [b/Imλ, (Reλ-a)/Imλ]
    basis2 = [0, 1]
    axisColors[0] = [0.5, 0.5, 0.5, 0.3]
    axisColors[1] = [0.5, 0.5, 0.5, 0.3]
    str  = 'This matrix has complex eigenvalues '
    str += katex.renderToString "\\lambda = #{Reλ.toFixed 2}\\pm #{Imλ.toFixed 2}i"
    str += '.'
    eigenStrs.push str
    opts =
        θ:     Math.atan2 -Imλ, Reλ
        scale: Math.sqrt determinant
        dist:  'cont'

    if almostZero(opts.scale-1)
        type = dynamics.Circle
    else
        if opts.scale > 1
            type = dynamics.SpiralOut
        else
            type = dynamics.SpiralIn

# Diagonalizable real matrix
else if discriminant > 0
    δ = Math.sqrt discriminant
    # λ1 < λ2
    λ1 = (trace - δ) / 2
    λ2 = (trace + δ) / 2
    if almostZero b
        if almostZero c
            # Already diagonal
            if almostZero (a-λ1)
                basis1 = [1, 0]
                basis2 = [0, 1]
            else
                basis2 = [1, 0]
                basis1 = [0, 1]
        else
            basis1 = normalize [λ1-d, c]
            basis2 = normalize [λ2-d, c]
    else
        basis1 = normalize [b, λ1-a]
        basis2 = normalize [b, λ2-a]
    if λ1 < 0 or λ2 < 0
        throw "Can't handle negative real eigenvalues"
    opts =
        λ1: λ1
        λ2: λ2
    swap = () ->
        [opts.λ2, opts.λ1] = [opts.λ1, opts.λ2]
        [basis2, basis1] = [basis1, basis2]
    if almostZero(λ1-1)
        type = dynamics.RepelLine
    else if almostZero(λ2-1)
        type = dynamics.AttractLine
        swap()
    else if λ1 < 1 and λ2 < 1
        type = dynamics.Attract
        swap()
    else if λ1 < 1 and λ2 > 1
        type = dynamics.Hyperbolas
    else if λ1 > 1 and λ2 > 1
        type = dynamics.Repel
    eigenStrs.push "This is the <span class=\"espace-1\">" +
                   "#{opts.λ1.toFixed 2}-eigenspace.</span>"
    eigenStrs.push "This is the <span class=\"espace-2\">" +
                   "#{opts.λ2.toFixed 2}-eigenspace.</span>"

v1p = [
    v1[0]*basis1[0] + v2[0]*basis1[1],
    v1[1]*basis1[0] + v2[1]*basis1[1],
    v1[2]*basis1[0] + v2[2]*basis1[1],
]
v2p = [
    v1[0]*basis2[0] + v2[0]*basis2[1],
    v1[1]*basis2[0] + v2[1]*basis2[1],
    v1[2]*basis2[0] + v2[2]*basis2[1],
]
v1 = v1p
v2 = v2p
# Now the matrix is block-diagonal in standard form wrt v1, v2, v3

if size == 3
    eigenStrs.push "This is the <span class=\"espace-3\">" +
                   "#{eigenz.toFixed 2}-eigenspace.</span>"
eigenStr = eigenStrs.join "<br>"


######################################################################
# * Demo

vecColor = new Color("red")

window.demo = new (if size == 3 then Demo else Demo2D) {
    mathbox:
        element: document.getElementById "mathbox"
        size: aspect: 1
    vertical: 1.1
}, () ->
    window.controller = controller = new dynamics.Controller @mathbox,
        continuous: false
        flow: urlParams.get 'flow', 'bool', false
        axisOpts:
            width:   if size == 3 then 5 else 3
            opacity: 1.0
        axisColors: axisColors
        refColor: new Color("blue").arr()
        duration: duration
        is3D: size == 3
        clipCube: (view) => @clipCube view,
            draw:   size == 3
            hilite: false
    if size == 2
        controller.installCoords v1, v2
    else
        controller.installCoords v1, v2, v3
        opts.scaleZ = eigenz
    controller.install type, opts

    console.log "Type: ", controller.current.descr()
    console.log "Opts: ", opts

    vectorIn  = [.5, 0, 0]
    vectorOut = [0, 0, 0]

    ##################################################
    # Caption
    te = controller.matrixOrigCoords.elements
    if size == 2
        displayMat = [[te[0], te[1]], [te[4], te[5]]]
    else if size == 3
        displayMat = [[te[0], te[1], te[2]],
                      [te[4], te[5], te[6]],
                      [te[8], te[9], te[10]]]

    str  = '<p><span id="mat-here"></span>' +
           '<span id="mult-here"></span></p>'
    str += eigenStr
    @caption str

    matElt = document.getElementById 'mat-here'
    multElt = document.getElementById 'mult-here'
    str = "#{matName} = " + @texMatrix displayMat
    katex.render str, matElt

    updateCaption = () =>
        vin  = vectorIn.slice  0, size
        controller.coordMatInv.applyToVector3Array vin # DEL
        vout = vectorOut.slice 0, size
        str = '\\qquad ' + matName +
              @texVector((x*10 for x in vin), color: vecColor) +
              " = " +
              @texVector((x*10 for x in vout), color: vecColor.darken(.1))
        katex.render str, multElt

    params =
        Multiply:      controller.step
        "Un-multiply": controller.unStep
        "Test vector": urlParams.get 'vec', 'bool', true
        "Show path":   urlParams.get 'path', 'bool', true
    gui = new dat.GUI
    gui.add(params, "Multiply")
    gui.add(params, "Un-multiply")

    ##################################################
    # Test vector
    view  = controller.viewBase
    viewT = controller.view

    @labeledVectors view,
        vectors:       [vectorIn, vectorOut]
        colors:        [vecColor, vecColor.darken(.1)]
        labels:        ['x', matName + 'x']
        live:          true
        zeroPoints:    false
        zeroThreshold: 0.3
        vectorOpts:    zIndex: 4
        labelOpts:     zIndex: 5
        zeroOpts:      zIndex: 5

    if size == 2
        snap = () ->
    else if size == 3
        # Snap to base plane
        subspace = @subspace vectors: [v1, v2]
        snapped = new THREE.Vector3()
        diff = new THREE.Vector3()
        snap = (vec) ->
            subspace.project vec, snapped
            diff.copy(vec).sub snapped
            if diff.lengthSq() <= 0.01
                vec.copy snapped

    drag = @draggable view,
        points: [vectorIn]
        onDrag: snap
        postDrag: () ->
            computeOut()
            computePath()

    computeOut = () ->
        return unless params["Test vector"]
        [vectorOut[0], vectorOut[1], vectorOut[2]] = vectorIn
        controller.matrixOrigCoords.applyToVector3Array vectorOut
        updateCaption()

    toggleVector = (val) =>
        @mathbox.select('.labeled').set 'visible', val
        drag.enabled = params["Test vector"] or params["Show path"]
        if val
            computeOut()
            multElt.classList.remove "hidden"
        else
            multElt.classList.add "hidden"
    gui.add(params, "Test vector").onFinishChange toggleVector
    toggleVector params["Test vector"]

    ##################################################
    # Test path
    path = ([0,0,0] for [0..100])
    computePath = () =>
        return unless params["Show path"]
        vec = vectorIn.slice()
        controller.coordMatInv.applyToVector3Array vec
        controller.current.makePath vec, path
    viewT.array
        channels: 3
        width:    path.length
        live:     true
        data:     path
    viewT.line
        classes:  ["test-path"]
        color:    new Color("orange").arr()
        width:    5
        opacity:  1
        zBias:    0
        zIndex:   4

    togglePath = (val) =>
        computePath() if val
        @mathbox.select('.test-path').set 'visible', val
        drag.enabled = params["Test vector"] or params["Show path"]
    gui.add(params, "Show path").onFinishChange togglePath
    togglePath params["Show path"]

    if controller.flow
        controller.start 55
