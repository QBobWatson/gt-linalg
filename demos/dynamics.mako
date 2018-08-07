## -*- coffee -*-

<%inherit file="base2.mako"/>

<%block name="title">Dynamics of a 2x2 matrix</%block>

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
#  * Multiply by inverse
#  * 3D version?

matrix = urlParams.get 'mat', 'matrix', [[ 1/2, 1/2],
                                         [-1/2, 1/2]]

duration = urlParams.get 'duration', 'float', 2.5
matName = urlParams.matname ? 'A'

######################################################################
# Test matrices

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

# Compute standard form of the matrix
[[a, b], [c, d]] = matrix
trace = a + d
determinant = a*d - b*c
discriminant = trace*trace - 4*determinant

# These are the parameters that are computed below
basis1 = []
basis2 = []
type = null
opts = {}
axisColors = [new Color("green").arr(1), new Color("violet").arr(1)]
eigenStr = ''

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
        eigenStr = "<p>The whole plane is the <span class=\"espace-1\">" +
                   "#{λ.toFixed 2}-eigenspace</span></p>"
        type = if λ > 1 then dynamics.Repel else dynamics.Attract
        opts =
            λ1: λ
            λ2: λ
    # Shear: put it in the form [λ, λ*a, 0, λ]
    else
        basis1 = normalize [b, λ-a]
        basis2 = normalize [a-λ, b]  # Anything linearly independent
        axisColors[1] = [0.5, 0.5, 0.5, 0.3]
        eigenStr = "<p>This is the <span class=\"espace-1\">" +
                   "#{λ.toFixed 2}-eigenspace</span></p>"
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
    axisColors = [[0.5, 0.5, 0.5, 0.3], [0.5, 0.5, 0.5, 0.3]]
    eigenStr = '<p>This matrix has no real eigenvectors.</p>'
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
    eigenStr = "<p>This is the <span class=\"espace-1\">" +
               "#{opts.λ1.toFixed 2}-eigenspace</span><br>" +
               "This is the <span class=\"espace-2\">" +
               "#{opts.λ2.toFixed 2}-eigenspace</span></p>"


vecColor = new Color("red")

new Demo2D {
    mathbox:
        element: document.getElementById "mathbox"
        size: aspect: 1
    vertical: 1
}, () ->
    window.controller = controller = new dynamics.Controller @mathbox,
        continuous: false
        axisOpts:
            width:   3
            opacity: 1.0
        axisColors: axisColors
        duration: duration

    controller.installCoords [basis1[0], basis2[0], basis1[1], basis2[1]]
    controller.install type, opts

    console.log "Type: ", controller.current.descr()
    console.log "Opts: ", opts

    vectorIn  = [.5, 0]
    vectorOut = [0, 0]

    ##################################################
    # Caption
    str  = '<p><span id="mat-here"></span>' +
           '<span id="mult-here"></span></p>'
    str += eigenStr
    @caption str

    matElt = document.getElementById 'mat-here'
    multElt = document.getElementById 'mult-here'
    str = "#{matName} = " + @texMatrix matrix
    katex.render str, matElt

    updateCaption = () =>
        str = '\\qquad ' + matName +
              @texVector(vectorIn, color: vecColor) +
              " = " +
              @texVector(vectorOut, color: vecColor.darken(.1))
        katex.render str, multElt

    ##################################################
    # Test vectors
    view = controller.view0

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

    computeOut = () ->
        m = matrix
        v = vectorIn
        vectorOut[0] = m[0][0] * v[0] + m[0][1] * v[1]
        vectorOut[1] = m[1][0] * v[0] + m[1][1] * v[1]
        updateCaption()
    computeOut()

    toggleVector = (val) =>
        @mathbox.select('.labeled').set 'visible', val
        drag.enabled = val
        if val
            multElt.classList.remove "hidden"
        else
            multElt.classList.add "hidden"

    drag = @draggable view,
        points:   [vectorIn]
        postDrag: computeOut

    params =
        Multiply:      controller.step
        "Un-multiply": controller.unStep
        "Test Vector": urlParams.get 'vec', 'bool', true
    gui = new dat.GUI
    gui.add(params, "Multiply")
    gui.add(params, "Un-multiply")
    gui.add(params, "Test Vector").onFinishChange toggleVector
    toggleVector params["Test Vector"]

