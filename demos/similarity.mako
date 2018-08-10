## -*- coffee -*-

<%inherit file="base_diptych.mako"/>

<%block name="title">Similar matrices</%block>

<%block name="inline_style">
${parent.inline_style()}
#captions3 {
  position:    absolute;
  left:        50%;
  top:         initial;
  transform:   translate(-50%, 0);
  bottom:      10px;
  z-index:     2;
}
</%block>

<%block name="label1">
<div id="captions1" class="overlay-text">
<p><span id="mat-here1"></span><span id="mult-here1"></span></p>
</div>
</%block>

<%block name="label2">
<div id="captions2" class="overlay-text">
<p><span id="mat-here2"></span><span id="mult-here2"></span></p>
</div>
</%block>

<%block name="body_html">
<div id="captions3" class="overlay-text">
<p>
    <span id="mat-here3"></span><br>
    <span id="sim-here"></span><br>
</p>
</div>
${parent.body_html()}
</%block>

##

##################################################
# Globals
vectorIn1  = urlParams.get 'x', 'float[]', [-1, 1, 3]
vectorOut1 = [0, 0, 0]
vectorIn2  = [-1, 1, 3]
vectorOut2 = [0, 0, 0]

labels = urlParams.get 'labels', 'str[]', ['v1', 'v2', 'v3']
AName = urlParams.AName ? 'A'
BName = urlParams.BName ? 'B'
CName = urlParams.CName ? 'C'

# A = CBC^(-1)
B = urlParams.get 'B', 'matrix', [[2, 0], [0, 3]]
C = urlParams.get 'C', 'matrix', [[2, 1], [1, 1]]

size = B.length
if size == 2
    vectorIn1[2] = 0
    vectorIn2[2] = 0
is3d = size == 3

# Make 3x3, make first coord = column
transpose = (mat) ->
    tmp = []
    for i in [0...3]
        tmp[i] = []
        for j in [0...3]
            tmp[i][j] = mat[j]?[i] ? 0
    tmp[2][2] = 1 if size == 2
    tmp
B = transpose B
C = transpose C

tB = new THREE.Matrix3()
tB.set B[0][0], B[1][0], B[2][0],
       B[0][1], B[1][1], B[2][1],
       B[0][2], B[1][2], B[2][2]
tB4 = new THREE.Matrix4()
tB4.set B[0][0], B[1][0], B[2][0], 0,
        B[0][1], B[1][1], B[2][1], 0,
        B[0][2], B[1][2], B[2][2], 0,
        0, 0, 0, 1
tB4inv = new THREE.Matrix4().getInverse tB4
tBinv = new THREE.Matrix3().getInverse tB4

tC = new THREE.Matrix3()
tC.set C[0][0], C[1][0], C[2][0],
       C[0][1], C[1][1], C[2][1],
       C[0][2], C[1][2], C[2][2]
# Can only take inverse of 4x4 matrix...
tC4 = new THREE.Matrix4()
tC4.set C[0][0], C[1][0], C[2][0], 0,
        C[0][1], C[1][1], C[2][1], 0,
        C[0][2], C[1][2], C[2][2], 0,
        0, 0, 0, 1
tCinv = new THREE.Matrix3().getInverse tC4
Cinv = tCinv.toArray()
Cinv = [[Cinv[0], Cinv[1], Cinv[2]],
        [Cinv[3], Cinv[4], Cinv[5]],
        [Cinv[6], Cinv[7], Cinv[8]]]

# threejs doesn't do this...
mult33 = (mat1, mat2) ->
    out = [[0,0,0], [0,0,0], [0,0,0]]
    out[0][0] = mat1[0][0]*mat2[0][0] + mat1[1][0]*mat2[0][1] + mat1[2][0]*mat2[0][2]
    out[1][0] = mat1[0][0]*mat2[1][0] + mat1[1][0]*mat2[1][1] + mat1[2][0]*mat2[1][2]
    out[2][0] = mat1[0][0]*mat2[2][0] + mat1[1][0]*mat2[2][1] + mat1[2][0]*mat2[2][2]
    out[0][1] = mat1[0][1]*mat2[0][0] + mat1[1][1]*mat2[0][1] + mat1[2][1]*mat2[0][2]
    out[1][1] = mat1[0][1]*mat2[1][0] + mat1[1][1]*mat2[1][1] + mat1[2][1]*mat2[1][2]
    out[2][1] = mat1[0][1]*mat2[2][0] + mat1[1][1]*mat2[2][1] + mat1[2][1]*mat2[2][2]
    out[0][2] = mat1[0][2]*mat2[0][0] + mat1[1][2]*mat2[0][1] + mat1[2][2]*mat2[0][2]
    out[1][2] = mat1[0][2]*mat2[1][0] + mat1[1][2]*mat2[1][1] + mat1[2][2]*mat2[1][2]
    out[2][2] = mat1[0][2]*mat2[2][0] + mat1[1][2]*mat2[2][1] + mat1[2][2]*mat2[2][2]
    out

A = mult33 mult33(C, B), Cinv

# Coordinate vectors
e1 = [1, 0, 0]
e2 = [0, 1, 0]
e3 = [0, 0, 1]
Ce1 = C[0]
Ce2 = C[1]
Ce3 = C[2]

bColor     = new Color "yellow"
bxBColor   = bColor.darken .2
xColor     = new Color "violet"
aXColor    = xColor.darken .2
axis1Color = new Color "red"
axis2Color = new Color "blue"
axis3Color = new Color "green"

colors = [bColor.arr(1), bxBColor.arr(.7),
          axis1Color.arr(.8), axis2Color.arr(.8), axis3Color.arr(.8),
          ][0...size+2]
updateCaption = null
computeOut = null

##################################################
# gui
gui = null
snap = false
params = {}
if urlParams.snap != 'disabled'
    gui = true
    params["Snap axes"] = urlParams.snap != 'off'
    gui = new dat.GUI
    gui.closed = urlParams.closed?
    gui.add(params, "Snap axes").onFinishChange (val) ->
        snap = val
    snap = params["Snap axes"]


##################################################################
# Demos

window.demo1 = new (if size == 3 then Demo else Demo2D) {
    mathbox: element: document.getElementById "mathbox1"
}, () ->
    window.mathbox1 = @mathbox

    ##################################################
    # view, axes
    @range = @urlParams.get 'range1', 'float', 5
    r = @range
    view = @view
        name:      'view1'
        viewRange: [[-r,r], [-r,r], [-r,r]][0...size]
        axes:      false
        grid:      false

    ##################################################
    # labeled vectors
    labeled = @labeledVectors view,
        vectors:       [vectorIn1, vectorOut1, e1, e2, e3][0...size+2]
        colors:        colors
        labels:        ['[x]_B', BName + '[x]_B', 'e1', 'e2', 'e3'][0...size+2]
        live:          true
        zeroPoints:    true
        zeroThreshold: 0.3
        vectorOpts:    zIndex: 2
        labelOpts:
            zIndex:     3
            outline:    1
            background: "white"
        zeroOpts:      zIndex: 3

    ##################################################
    # Clip cube
    clipCube = @clipCube view,
        draw:   true
        hilite: size == 3

    ##################################################
    # Grid
    clipCube.clipped
        .area
            width:    11
            height:   11
            channels: size
            rangeX:   [-r, r]
            rangeY:   [-r, r]
        .surface
            color:    [0.5, 0.5, 0.5, 0.5]
            opacity:  0.5
            lineX:    true
            lineY:    true
            fill:     false
            zBias:    0
        .array
            channels: 4
            width:    2
            items:    size
            data:     [[colors[2], colors[3], colors[4]][0...size],
                       [colors[2], colors[3], colors[4]][0...size]]
        .array
            width:    2
            items:    size
            channels: size
            data:     if size == 2 then \
                          [[-r, 0], [0, -r], [r, 0], [0, r]] \
                      else \
                          [[-r, 0, 0], [0, -r, 0], [0, 0, -r],
                           [ r, 0, 0], [0,  r, 0], [0, 0,  r]]
        .line
            color:    "white"
            colors:   "<<"
            width:    2
            opacity:  1
            zBias:    1

    ##################################################
    # Dragging
    tmpVec = new THREE.Vector3()

    computeOut = () =>
        tmpVec.set.apply(tmpVec, vectorIn1).applyMatrix3 tB
        vectorOut1[0] = tmpVec.x
        vectorOut1[1] = tmpVec.y
        vectorOut1[2] = tmpVec.z
        tmpVec.applyMatrix3 tC
        vectorOut2[0] = tmpVec.x
        vectorOut2[1] = tmpVec.y
        vectorOut2[2] = tmpVec.z
        tmpVec.set.apply(tmpVec, vectorIn1).applyMatrix3 tC
        vectorIn2[0] = tmpVec.x
        vectorIn2[1] = tmpVec.y
        vectorIn2[2] = tmpVec.z
        updateCaption()

    snapThreshold = 1.0 * @range / 10.0
    snapped = new THREE.Vector3()
    diff = new THREE.Vector3()
    subspace1 = @subspace vectors: [e1]
    subspace2 = @subspace vectors: [e2]
    subspace3 = @subspace vectors: [e3]
    subspaces = [subspace1, subspace2, subspace3]

    # Snap to coordinate axes
    onDrag = (vec) =>
        return unless snap
        for subspace in subspaces
            subspace.project vec, snapped
            diff.copy(vec).sub snapped
            if diff.lengthSq() <= snapThreshold
                vec.copy snapped

    @drag = @draggable view,
        points:   [vectorIn1]
        onDrag:   onDrag
        postDrag: computeOut

    ##################################################
    # Captions
    mat1Elt = document.getElementById 'mat-here1'
    mat2Elt = document.getElementById 'mat-here2'
    mat3Elt = document.getElementById 'mat-here3'

    katex.render("#{BName} = " + @texMatrix(B, {rows: size, cols: size}), mat1Elt)
    katex.render("#{AName} = " + @texMatrix(A, {rows: size, cols: size}), mat2Elt)
    katex.render("#{CName} = " + @texMatrix(C, {rows: size, cols: size}), mat3Elt)

    elt = document.getElementById "sim-here"
    katex.render("#{AName} = #{CName}#{BName}#{CName}^{-1} " +
                 "\\quad \\color{#{xColor.str()}}{x} = " +
                 "#{CName}\\color{#{bColor.str()}}{[x]_{\\mathcal B}}", elt)

    eq1Elt = document.getElementById 'mult-here1'
    eq2Elt = document.getElementById 'mult-here2'

    updateCaption = () =>
        str  = "\\qquad #{BName}"
        str += @texVector vectorIn1, {dim: size, color: bColor}
        str += '='
        str += @texVector vectorOut1, {dim: size, color: bxBColor}
        katex.render str, eq1Elt
        str  = "\\qquad #{AName}"
        str += @texVector vectorIn2, {dim: size, color: xColor}
        str += '='
        str += @texVector vectorOut2, {dim: size, color: aXColor}
        katex.render str, eq2Elt


window.demo2 = new (if size == 3 then Demo else Demo2D) {
    mathbox: element: document.getElementById "mathbox2"
}, () ->
    window.mathbox2 = @mathbox

    ##################################################
    # view, axes
    @range = @urlParams.get 'range2', 'float', 5
    r = @range
    view = @view
        name:      'view2'
        viewRange: [[-r,r], [-r,r], [-r,r]][0...size]
        axes:      false
        grid:      false

    ##################################################
    # labeled vectors
    colors2 = colors.slice()
    colors2[0] = xColor.arr 1
    colors2[1] = aXColor.arr .7
    labeled = @labeledVectors view,
        vectors:       [vectorIn2, vectorOut2, Ce1, Ce2, Ce3][0...size+2]
        colors:        colors2
        labels:        ['x', AName + 'x'].concat(labels)[0...size+2]
        live:          true
        zeroPoints:    true
        zeroThreshold: 0.3
        vectorOpts:    zIndex: 2
        labelOpts:
            zIndex: 3
            outline:    1
            background: "white"
        zeroOpts:      zIndex: 3

    ##################################################
    # Clip cube
    clipCube = @clipCube view,
        draw:   true
        hilite: size == 3

    ##################################################
    # Grid
    @transformed = clipCube.clipped
        .transform
            matrix: [C[0][0], C[1][0], C[2][0], 0,
                     C[0][1], C[1][1], C[2][1], 0,
                     C[0][2], C[1][2], C[2][2], 0,
                     0, 0, 0, 1]
    r2 = demo1.range * 5
    @transformed
        .area
            width:    51
            height:   51
            channels: size
            rangeX:   [-r2, r2]
            rangeY:   [-r2, r2]
        .surface
            color:    [0.5, 0.5, 0.5, 0.5]
            opacity:  0.5
            lineX:    true
            lineY:    true
            fill:     false
            zBias:    0
        .array
            channels: 4
            width:    2
            items:    size
            data:     [[colors[2], colors[3], colors[4]][0...size],
                       [colors[2], colors[3], colors[4]][0...size]]
        .array
            width:    2
            items:    size
            channels: size
            data:     if size == 2 then \
                          [[-r2, 0], [0, -r2], [r2, 0], [0, r2]] \
                      else \
                          [[-r2, 0, 0], [0, -r2, 0], [0, 0, -r2],
                           [ r2, 0, 0], [0,  r2, 0], [0, 0,  r2]]
        .line
            color:    "white"
            colors:   "<<"
            width:    2
            opacity:  1
            zBias:    1


    ##################################################
    # Dragging
    tmpVec = new THREE.Vector3()
    computeIn = () ->
        tmpVec.set.apply(tmpVec, vectorIn2).applyMatrix3 tCinv
        vectorIn1[0] = tmpVec.x
        vectorIn1[1] = tmpVec.y
        vectorIn1[2] = tmpVec.z
        tmpVec.applyMatrix3 tB
        vectorOut1[0] = tmpVec.x
        vectorOut1[1] = tmpVec.y
        vectorOut1[2] = tmpVec.z
        tmpVec.applyMatrix3 tC
        vectorOut2[0] = tmpVec.x
        vectorOut2[1] = tmpVec.y
        vectorOut2[2] = tmpVec.z
        updateCaption()

    snapThreshold = 1.0 * @range / 10.0
    snapped = new THREE.Vector3()
    diff = new THREE.Vector3()
    subspace1 = @subspace vectors: [Ce1]
    subspace2 = @subspace vectors: [Ce2]
    subspace3 = @subspace vectors: [Ce3]
    subspaces = [subspace1, subspace2, subspace3]

    # Snap to coordinate axes
    onDrag = (vec) =>
        return unless snap
        for subspace in subspaces
            subspace.project vec, snapped
            diff.copy(vec).sub snapped
            if diff.lengthSq() <= snapThreshold
                vec.copy snapped

    @drag = @draggable view,
        points:   [vectorIn2]
        onDrag:   onDrag
        postDrag: computeIn

groupControls demo1, demo2

computeOut()
