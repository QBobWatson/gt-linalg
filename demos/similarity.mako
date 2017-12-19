## -*- coffee -*-

<%inherit file="base_diptych.mako"/>

<%block name="title">Similar matrices</%block>

<%block name="overlay_text">
<div class="overlay-text">
</div>
</%block>

<%block name="inline_style">
    ${parent.inline_style()}
    .matrix-powers {
        text-align: center;
        font-size: 150%;
    }
    .dots {
        text-align: center;
        font-size: 150%;
    }
    #mult-factor {
        text-align: center;
    }
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
vectorIn1  = urlParams.get 'x', 'float[]', [-1, 1, 3]
vectorOut1 = [0, 0, 0]
vectorIn2  = [-1, 1, 3]
vectorOut2 = [0, 0, 0]

labels = urlParams.get 'labels', 'str[]', ['v1', 'v2', 'v3']
AName = urlParams.AName ? 'A'
BName = urlParams.BName ? 'B'

# A = CBC^(-1)
B = urlParams.get 'B', 'matrix', [[2, 0], [0, 3]]
C = urlParams.get 'C', 'matrix', [[2, 1], [1, 1]]

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
tB4 = new THREE.Matrix4()
tB4.set B[0][0], B[1][0], B[2][0], 0,
        B[0][1], B[1][1], B[2][1], 0,
        B[0][2], B[1][2], B[2][2], 0,
        0, 0, 0, 1
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

# Random vectors
numVecs = 20
random = ([0, 0, 0] for [0...numVecs])
randomColors = ([0, 0, 0, 1] for [0...numVecs])
makeRandom = null
dynamicsMode = urlParams.dynamics ? 'off'

colors = [[1, 1, 0, 1], [.7, .7, 0, .7],
          [.7, 0, 0, .8], [0, .7, 0, .8], [0, .3, .9, .8],
          ][0...size+2]

updateCaption = null
resetMode = null
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

if dynamicsMode != 'disabled'
    tmpVec2 = new THREE.Vector3()

    # Reference: circle or hyperbola
    reference = urlParams.reference ? null
    refData = null
    makeRefData = () ->
    switch reference
        when 'circle'
            makeRefData = () ->
                refData = ([Math.cos(2*π*i/50), Math.sin(2*π*i/50), 0] for i in [0..50])
            updateRefData = (mat) ->
                newData = []
                for vec in refData
                    tmpVec2.set.apply(tmpVec2, vec).applyMatrix3 mat
                    newData.push [tmpVec2.x, tmpVec2.y, tmpVec2.z]
                newData
            referenceItems = 1
        when 'hyperbola'
            makeRefData = () ->
                # Four lines, so four items
                refData = ([[2**(i/3),  2**(-i/3), 0], [-2**(i/3),  2**(-i/3), 0],
                            [2**(i/3), -2**(-i/3), 0], [-2**(i/3), -2**(-i/3), 0]] \
                           for i in [-25..25])
            # TODO: this only works when the product of the eigenvals is 1...
            updateRefData = (mat) ->
            referenceItems = 4
    makeRefData()

    # gui
    inFolder = gui?
    gui ?= new dat.GUI
    gui.closed = urlParams.closed?
    iteration = 0
    folder = gui.addFolder("Dynamics")
    folder.open() if dynamicsMode == 'on'
    params.Enable = dynamicsMode == 'on'
    params.Reset = () ->
        return unless params.Enable
        makeRandom()
        makeRefData()
        for demo in [demo1, demo2]
            demo.stopAll()
            demo.pointsData.set 'data', random
            if reference
                demo.refData.set 'data', refData
        iteration = 0
        resetMode()
        updateCaption()

    iterate = (mat, iter) ->
        for demo in [demo1, demo2]
            demo.stopAll()
            demo.pointsData.set 'data', random

        # Compute next points
        newRandom = []
        for vec in random
            tmpVec2.set.apply(tmpVec2, vec).applyMatrix3 mat
            newRandom.push [tmpVec2.x, tmpVec2.y, tmpVec2.z]
        if reference
            newData = updateRefData mat

        for demo in [demo1, demo2]
            demo.animate demo.pointsData,
                ease: 'linear'
                script:
                    0:   props: data: random
                    .75: props: data: newRandom
            if reference
                demo.animate demo.refData,
                    ease: 'linear'
                    script:
                        0:   props: data: refData
                        .75: props: data: newData

        random = newRandom
        if reference
            refData = newData

        if iter == 1
            document.getElementById('mult-factor').innerText =
                'Random vectors multiplied by'
        katex.render "#{BName}^{#{iter}} " +
            "\\quad\\text{resp.}\\quad #{AName}^{#{iter}}",
            document.getElementById('An-here')

    params.Iterate = () ->
        return unless params.Enable
        iteration++
        iterate(tB, iteration)
    params.UnIterate = () ->
        return unless params.Enable
        iteration--
        iterate(tBinv, iteration)

    folder.add(params, 'Enable').onFinishChange (val) ->
        dynamicsMode = if val then 'on' else 'off'
        resetMode()
        updateCaption()
    folder.add(params, 'Reset')
    folder.add(params, 'Iterate')
    folder.add(params, 'UnIterate')



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
        zeroPoints:    dynamicsMode == 'disabled'
        zeroThreshold: 0.3
        vectorOpts:    zIndex: 2
        labelOpts:     zIndex: 3
        zeroOpts:      zIndex: 3

    ##################################################
    # random points
    if dynamicsMode != 'disabled'
        makeRandom = () =>
            for vec in random
                vec[0] = Math.random() * @range * 2 - @range
                vec[1] = Math.random() * @range * 2 - @range
                if size == 3
                    vec[2] = Math.random() * @range * 2 - @range
            for col in randomColors
                col[0] = Math.random() * .5 + .5
                col[1] = Math.random() * .5 + .5
                col[2] = Math.random() * .5 + .5
            switch reference
                # Put points on the reference line
                when 'circle'
                    for i in [0...5]
                        θ = Math.random() * 2*π
                        random[i][0] = Math.cos(θ)
                        random[i][1] = Math.sin(θ)
                when 'hyperbola'
                    for i in [0...5]
                        x = Math.random() * (@range - 1/@range) + 1/@range
                        sign1 = if Math.random() > 0.5 then 1 else -1
                        sign2 = if Math.random() > 0.5 then 1 else -1
                        random[i][0] = sign1*x
                        random[i][1] = sign2/x
        makeRandom()
        view
            .array
                channels: 4
                width:    randomColors.length
                data:     randomColors
        @pointsData = view
            .array
                channels: 3
                width:    random.length
                data:     random
        @points = view
            .point
                colors:   "<<"
                color:    "white"
                size:     20
                zIndex:   3

        if reference
            @refData = view
                .array
                    channels: 3
                    width:    refData.length
                    data:     refData
                    items:    referenceItems
                    live:     true
            @reference = view
                .line
                    color:   "rgb(0, 80, 255)"
                    width:   4
                    opacity: .75
                    zBias:   2
                    closed:  true

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
        return unless snap
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
    resetMode = () =>
        if dynamicsMode == 'on'
            # Don't update caption on drag in dynamics mode
            updateCaption = () ->
            str = '<p class="dots">'
            for col in randomColors
                hexColor = "#" + new THREE.Color(col[0], col[1], col[2]).getHexString()
                str += """
                    <span style="color:#{hexColor}">&#x25cf;</span>
                """
            str += '</p>'
            document.getElementsByClassName('overlay-text')[0].innerHTML = str + '''
                <p id="mult-factor">Original random vectors</p>
                <p class="matrix-powers">
                    <span id="An-here"></span>
                </p>
                '''
            for demo in [demo1, demo2]
                demo.points.set 'visible', true
                if reference
                    demo.reference.set 'visible', true
                demo.mathbox.select('.labeled').set 'visible', false
        else
            document.getElementsByClassName('overlay-text')[0].innerHTML = '''
                <p><span id="mats-here"></span></p>
                <p><span id="eq1-here"></span> (B-coordinates)</p>
                <p><span id="eq2-here"></span></p>
                '''
            matsElt = document.getElementById 'mats-here'
            eq1Elt  = document.getElementById 'eq1-here'
            eq2Elt  = document.getElementById 'eq2-here'

            str  = @texMatrix A,    {rows: size, cols: size}
            str += '='
            str += @texMatrix C,    {rows: size, cols: size}
            str += @texMatrix B,    {rows: size, cols: size}
            str += @texMatrix Cinv, {rows: size, cols: size}
            katex.render str, matsElt

            updateCaption = () =>
                str  = @texMatrix B, {rows: size, cols: size}
                str += @texVector vectorIn1, {dim: size, color: "#ffff00"}
                str += '='
                str += @texVector vectorOut1, {dim: size, color: "#888800"}
                katex.render str, eq1Elt
                str  = @texMatrix A, {rows: size, cols: size}
                str += @texVector vectorIn2, {dim: size, color: "#ff00ff"}
                str += '='
                str += @texVector vectorOut2, {dim: size, color: "#880088"}
                katex.render str, eq2Elt
            if dynamicsMode != 'disabled'
                for demo in [demo1, demo2]
                    demo.points.set 'visible', false
                    if reference
                        demo.reference.set 'visible', false
                    demo.mathbox.select('.labeled').set 'visible', true


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
    colors2[0] = [ 1, 0,  1,  1]
    colors2[1] = [.7, 0, .7, .7]
    labeled = @labeledVectors view,
        vectors:       [vectorIn2, vectorOut2, Ce1, Ce2, Ce3][0...size+2]
        colors:        colors2
        labels:        ['x', AName + 'x'].concat(labels)[0...size+2]
        live:          true
        zeroPoints:    dynamicsMode == 'disabled'
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
                          [[-r2, 0], [0, -r2], [r2, 0], [0, r2]] \
                      else \
                          [[-r2, 0, 0], [0, -r2, 0], [0, 0, -r2],
                           [ r2, 0, 0], [0,  r2, 0], [0, 0,  r2]]
        .line
            color:    "white"
            colors:   "<<"
            width:    3
            opacity:  1
            zBias:    1

    ##################################################
    # random points
    if dynamicsMode != 'disabled'
        @transformed
            .array
                channels: 4
                width:    randomColors.length
                data:     randomColors
        @pointsData = @transformed
            .array
                channels: 3
                width:    random.length
                data:     random
        @points = @transformed
            .point
                colors:   "<<"
                color:    "white"
                size:     20
                zIndex:   3

        if reference
            @refData = @transformed
                .array
                    channels: 3
                    width:    refData.length
                    data:     refData
                    items:    referenceItems
                    live:     true
            @reference = @transformed
                .line
                    color:   "rgb(0, 80, 255)"
                    width:   4
                    opacity: .75
                    zBias:   2
                    closed:  true

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

    @draggable view,
        points:   [vectorIn2]
        onDrag:   onDrag
        postDrag: computeIn

groupControls demo1, demo2

resetMode()
computeOut()
