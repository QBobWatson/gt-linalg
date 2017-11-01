## -*- coffee -*-

<%inherit file="base_diptych.mako"/>

<%block name="title">Similar matrices</%block>

<%block name="overlay_text">
<div class="overlay-text">
    <p><span id="mats-here"></span></p>
    <p><span id="eq1-here"></span> (B-coordinates)</p>
    <p><span id="eq2-here"></span></p>
</div>
</%block>

<%block name="label1">
<div class="mathbox-label">The B-coordinates</div>
</%block>

<%block name="label2">
<div class="mathbox-label">The usual coordinates</div>
</%block>


##

##################################################
# Globals
vectorIn1  = [-1, 1, 3]
vectorOut1 = [0, 0, 0]
vectorIn2  = [-1, 1, 3]
vectorOut2 = [0, 0, 0]

if urlParams.x?
    vectorIn1 = urlParams.x.split(",").map parseFloat

# A = CBC^(-1)
B = [[2, 0], [0, 3]]
C = [[2, 1], [1, 1]]

if urlParams.B?
    B = urlParams.B.split(":").map (s) -> s.split(",").map parseFloat
if urlParams.C?
    C = urlParams.C.split(":").map (s) -> s.split(",").map parseFloat

size = B.length
if size == 2
    vectorIn1[2] = 0
    vectorIn2[2] = 0

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
Cinv = [[Cinv[0], Cinv[3], Cinv[6]],
        [Cinv[1], Cinv[4], Cinv[7]],
        [Cinv[2], Cinv[5], Cinv[8]]]

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

colors = [[1, 1, 0, 1], [.7, .7, 0, .7],
          [.7, 0, 0, .8], [0, .7, 0, .8], [0, .3, .9, .8],
          ][0...size+2]

updateCaption = null

##################################################
# gui
snap = false
if urlParams.snap != 'disabled'
    params =
        "Snap axes": urlParams.snap != 'off'
    gui = new dat.GUI
    gui.closed = urlParams.closed?
    gui.add(params, "Snap axes").onFinishChange (val) ->
        snap = val
    snap = params["Snap axes"]


window.demo1 = new (if size == 3 then Demo else Demo2D) {
    mathbox: element: document.getElementById "mathbox1"
}, () ->
    window.mathbox1 = @mathbox

    ##################################################
    # view, axes
    @range = 5
    if @urlParams.range1?
        @range = parseFloat @urlParams.range1
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
        labels:        ['[x]_B', 'B[x]_B', 'e1', 'e2', 'e3'][0...size+2]
        live:          true
        zeroPoints:    true
        zeroThreshold: 0.3
        vectorOpts:    zIndex: 2
        labelOpts:     zIndex: 3
        zeroOpts:      zIndex: 3

    ##################################################
    # Clip cube
    clipCube = @clipCube view,
        draw:   true
        hilite: size == 3
        color:  new THREE.Color .75, .75, .75

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
            color:    "white"
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
            width:    3
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
        for subspace in subspaces
            subspace.project vec, snapped
            diff.copy(vec).sub snapped
            if diff.lengthSq() <= snapThreshold
                vec.copy snapped

    @draggable view,
        points:   [vectorIn1]
        onDrag:   onDrag
        postDrag: computeOut

    ##################################################
    # Captions
    matsElt = document.getElementById 'mats-here'
    eq1Elt  = document.getElementById 'eq1-here'
    eq2Elt  = document.getElementById 'eq2-here'

    str  = @texMatrix A,    {rows: size, cols: size, precision: -1}
    str += '='
    str += @texMatrix C,    {rows: size, cols: size, precision: -1}
    str += @texMatrix B,    {rows: size, cols: size, precision: -1}
    str += @texMatrix Cinv, {rows: size, cols: size, precision: -1}
    katex.render str, matsElt

    updateCaption = () =>
        str  = @texMatrix B, {rows: size, cols: size, precision: -1}
        str += @texVector vectorIn1, {dim: size, color: "#ffff00"}
        str += '='
        str += @texVector vectorOut1, {dim: size, color: "#888800"}
        katex.render str, eq1Elt
        str  = @texMatrix A, {rows: size, cols: size, precision: -1}
        str += @texVector vectorIn2, {dim: size, color: "#ff00ff"}
        str += '='
        str += @texVector vectorOut2, {dim: size, color: "#880088"}
        katex.render str, eq2Elt

    computeOut()


window.demo2 = new (if size == 3 then Demo else Demo2D) {
    mathbox: element: document.getElementById "mathbox2"
}, () ->
    window.mathbox2 = @mathbox

    ##################################################
    # view, axes
    @range = 5
    if @urlParams.range2?
        @range = parseFloat @urlParams.range2
    r = @range
    view = @view
        name:      'view2'
        viewRange: [[-r,r], [-r,r], [-r,r]][0...size]
        axes:      false
        grid:      false

    ##################################################
    # labeled vectors
    colors2 = colors.slice()
    colors2[0] = [ 1, 0,  1,  1]
    colors2[1] = [.7, 0, .7, .7]
    labeled = @labeledVectors view,
        vectors:       [vectorIn2, vectorOut2, Ce1, Ce2, Ce3][0...size+2]
        colors:        colors2
        labels:        ['x', 'Ax', 'v1', 'v2', 'v3'][0...size+2]
        live:          true
        zeroPoints:    true
        zeroThreshold: 0.3
        vectorOpts:    zIndex: 2
        labelOpts:     zIndex: 3
        zeroOpts:      zIndex: 3

    ##################################################
    # Clip cube
    clipCube = @clipCube view,
        draw:   true
        hilite: size == 3
        color:  new THREE.Color .75, .75, .75

    ##################################################
    # Grid
    clipCube.clipped
        .transform
            matrix: [C[0][0], C[1][0], C[2][0], 0,
                     C[0][1], C[1][1], C[2][1], 0,
                     C[0][2], C[1][2], C[2][2], 0,
                     0, 0, 0, 1]
        .area
            width:    51
            height:   51
            channels: size
            rangeX:   [-5*r, 5*r]
            rangeY:   [-5*r, 5*r]
        .surface
            color:    "white"
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
            width:    3
            opacity:  1
            zBias:    1

    ##################################################
    # Dragging
    tmpVec = new THREE.Vector3()
    computeOut = () ->
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
        for subspace in subspaces
            subspace.project vec, snapped
            diff.copy(vec).sub snapped
            if diff.lengthSq() <= snapThreshold
                vec.copy snapped

    @draggable view,
        points:   [vectorIn2]
        onDrag:   onDrag
        postDrag: computeOut

groupControls demo1, demo2
