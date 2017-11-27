## -*- coffee -*-

<%! roots=True %>

<%inherit file="base2.mako"/>

<%block name="title">Orthogonal Projection</%block>

##

range = 10
if urlParams.range?
    range = parseFloat urlParams.range

vector1 = [1,0,0]
vector2 = [0,1,0]
vector  = [1, 1, 0]
numVecs = 2

if urlParams.u1?
    vector1 = urlParams.u1.split(",").map parseFloat
    numVecs = 1
if urlParams.u2?
    vector2 = urlParams.u2.split(",").map parseFloat
    numVecs = 2
if urlParams.vec?
    vector = urlParams.vec.split(",").map parseFloat

size = vector1.length
vector1[2] ?= 0
vector2[2] ?= 0

vectors = [vector1, vector2].slice(0, numVecs)

# decomposition into x_W and x_Wperp
decompProj = [1, 0, 0]
decompPerp = [0, 1, 0]

# summands in projection formula
summand1 = [0, 0, 0]
summand2 = [0, 0, 0]
summands = [summand1, summand2].slice(0, numVecs)

labels = ['u1', 'u2']
if urlParams.labels?
    labels = urlParams.labels.split ','
labels = labels.slice(0, numVecs)
vecLabel = urlParams.vecLabel ? 'x'

subName = if numVecs == 2 then 'W' else 'L'
if urlParams.subname
    subName = urlParams.subname

# Orthogonalize if necessary
# if numVecs == 2
#     dot = vector1[0]*vector2[0] + vector1[1]*vector2[1] + vector1[2]*vector2[2]
#     if dot != 0
#         norm = vector1[0]*vector1[0] + vector1[1]*vector1[1] + vector1[2]*vector1[2]
#         vector2[0] -= vector1[0] * dot / norm
#         vector2[1] -= vector1[1] * dot / norm
#         vector2[2] -= vector1[2] * dot / norm

dot = (vec1, vec2) -> vec1[0]*vec2[0] + vec1[1]*vec2[1] + vec1[2]*vec2[2]
norm1 = dot vector1, vector1
norm2 = dot vector2, vector2

mode = urlParams.mode ? 'full'
switch mode
    when 'full'
        showBasis = true
        showGrid = true
        showSummands = numVecs > 1
        showDecomp = true
        showProj = false
        showDistance = false
        showComplement = true
        constrainToW = false
    when 'decomp'
        showBasis = false
        showGrid = false
        showSummands = false
        showDecomp = true
        showProj = false
        showDistance = false
        showComplement = true
        constrainToW = false
    when 'basis'
        showBasis = true
        showGrid = true
        showSummands = numVecs > 1
        showDecomp = false
        showProj = false
        showDistance = false
        showComplement = false
        constrainToW = true
    when 'badbasis'
        showBasis = true
        showGrid = true
        showSummands = numVecs > 1
        showDecomp = false
        showProj = true
        showDistance = false
        showComplement = false
        constrainToW = true
    when 'distance'
        showBasis = false
        showGrid = false
        showSummands = false
        showDecomp = false
        showProj = false
        showDistance = true
        showComplement = true
        constrainToW = false
if urlParams.basis?
    showBasis = urlParams.basis != 'false'
if urlParams.grid?
    showGrid = urlParams.grid != 'false'
if urlParams.summands?
    showSummands = urlParams.summands != 'false'
if urlParams.decomp?
    showDecomp = urlParams.decomp != 'false'
if urlParams.distance?
    showDistance = urlParams.distance != 'false'
if urlParams.complement?
    showComplement = urlParams.complement != 'false'
if urlParams.constrain?
    constrainToW = urlParams.constrain != 'false'

window.demo = new (if size == 2 then Demo2D else Demo) {}, () ->
    window.mathbox = @mathbox

    params =
        'Show Basis':    showBasis
        'Show Grid':     showGrid
        'Show Decomp':   showDecomp
        'Show Distance': showDistance
        'Show Summands': showSummands
    gui = new dat.GUI()
    gui.closed = @urlParams.closed?
    gui.add(params, 'Show Basis').onFinishChange (val) ->
        showBasis = val
        mathbox.select('.basis').set 'visible', val
    gui.add(params, 'Show Grid').onFinishChange (val) ->
        showBasis = val
        mathbox.select('#vecgrid').set 'visible', val
    gui.add(params, 'Show Decomp').onFinishChange (val) ->
        showDecomp = val
        mathbox.select('.decomp').set 'visible', val
    gui.add(params, 'Show Distance').onFinishChange (val) ->
        showDistance = val
        mathbox.select('.distance').set 'visible', val
    gui.add(params, 'Show Summands').onFinishChange (val) ->
        showSummands = val
        mathbox.select('.summands').set 'visible', val

    view = @view
        axes:  false
        grid:  false
        range: [[-range,range],[-range,range],[-range,range]].slice(0, size)

    clipCube = @clipCube view,
        draw:   true
        hilite: size == 3

    ##################################################
    # Compute and draw subspace and its complement
    subspace = @subspace
        vectors: vectors
        live:    false
        noPlane: size == 2
        # Lines before planes for transparency
        lineOpts:
            zOrder: 0
        surfaceOpts:
            zOrder: 1
    subspace.draw clipCube.clipped

    @grid clipCube.clipped,
        vectors: vectors
        live: false
    mathbox.select('#vecgrid').set 'visible', showGrid

    if showComplement
        complement = @subspace
            vectors: subspace.complementFull(size == 2)
            name:    'complement'
            color:   0x00aaaa
            noPlane: size == 2
            live:    false
            # Lines before planes for transparency
            lineOpts:
                zOrder: 0
            surfaceOpts:
                zOrder: 1
        complement.draw clipCube.clipped

    ##################################################
    # Labeled vectors
    @labeledVectors view,
        vectors:    [vector]
        colors:     [[1, 1, 1, 1]]
        labels:     [vecLabel]
        live:       true
        vectorOpts: zIndex: 4
        labelOpts:  zIndex: 5

    @labeledVectors view,
        name:       'basis'
        vectors:    vectors
        colors:     [[0.8, .5, 0, .7], [0.8, 0, .5, .7]].slice(0, numVecs)
        labels:     labels
        live:       false
        vectorOpts: zIndex: 2
        labelOpts:  zIndex: 3

    @labeledVectors view,
        name:       'summands'
        vectors:    summands
        colors:     [[0.3020,0.6863,0.2902, .9], [0.2157,0.4941,0.7216, .9]].slice(0, numVecs)
        labels:     null
        live:       true
        vectorOpts: zIndex: 3

    @labeledVectors view,
        name:       'decomp'
        vectors:    [decompProj, vector]
        origins:    [[0, 0, 0], decompProj]
        colors:     [[1, 0.3, .3, 1], [0, .8, .8, 1]]
        labels:     ["#{vecLabel}_#{subName}", "#{vecLabel}_#{subName}\u27C2"]
        live:       true
        vectorOpts: zIndex: 4
        labelOpts:  zIndex: 5

    if showProj
        @labeledVectors view,
            name:       'proj'
            vectors:    [decompProj]
            colors:     [[1, 0.3, .3, 1]]
            labels:     ['?']
            live:       true
            vectorOpts: zIndex: 4
            labelOpts:  zIndex: 5
        view
            .array
                width:    2
                channels: 3
                items:    4
                data:
                    [[summands[0], summands[1], summands[0], summands[1]],
                     [vector, vector, decompProj, decompProj]]
            .array
                width:    2
                channels: 4
                items:    4
                data:
                    [[[1, 1, 1, .7],              [1, 1, 1, .7],
                      [0.2157,0.4941,0.7216, .7], [0.3020,0.6863,0.2902, .7]],
                     [[1, 1, 1, .7],              [1, 1, 1, .7],
                      [0.2157,0.4941,0.7216, .7], [0.3020,0.6863,0.2902, .7]]]
            .line
                width:  2
                points: "<<"
                color:  "white"
                colors: "<"

    decompLabels = ['x_W', "1.0"]
    @labeledVectors view,
        name:       'distance'
        vectors:    [decompProj, vector]
        origins:    [[0, 0, 0], decompProj]
        colors:     [[1, 0.3, .3, 1], [0, .8, .8, 1]]
        labels:     decompLabels
        live:       true
        labelsLive: true
        vectorOpts: {zIndex: 4, end: false}
        labelOpts:  zIndex: 5

    view
        .array
            width:    1
            channels: 3
            data:     [decompProj]
        .point
            size:     15
            color:    [1, 0.3, 0.3]
            classes:  ['distance']
        .text
            live:  false
            width: 1
            data:  ['closest']
        .label
            classes: ['distance']
            color:   [1, 0.3, 0.3]
            outline:    2
            background: "black"
            size:       15
            offset:     [0, -25]

    mathbox.select('.basis').set 'visible', showBasis
    mathbox.select('.decomp').set 'visible', showDecomp
    mathbox.select('.distance').set 'visible', showDistance
    mathbox.select('.summands').set 'visible', showSummands

    ##################################################
    # Dragging and snapping
    snap = (vec) =>
        if constrainToW
            subspace.project vec, vec

    coeffs = [0, 0]
    computeOut = () ->
        dot1 = dot vector, vector1
        coeffs[0] = dot1 / norm1
        decompProj[0] = vector1[0] * coeffs[0]
        decompProj[1] = vector1[1] * coeffs[0]
        decompProj[2] = vector1[2] * coeffs[0]
        summand1[0] = decompProj[0]
        summand1[1] = decompProj[1]
        summand1[2] = decompProj[2]
        if numVecs > 1
            dot2 = dot vector, vector2
            coeffs[1] = dot2 / norm2
            summand2[0] = vector2[0] * coeffs[1]
            summand2[1] = vector2[1] * coeffs[1]
            summand2[2] = vector2[2] * coeffs[1]
            decompProj[0] += summand2[0]
            decompProj[1] += summand2[1]
            decompProj[2] += summand2[2]
        decompPerp[0] = vector[0] - decompProj[0]
        decompPerp[1] = vector[1] - decompProj[1]
        decompPerp[2] = vector[2] - decompProj[2]
        decompLabels[1] = Math.sqrt(dot(decompPerp, decompPerp)).toFixed 2
        updateCaptions()

    @draggable view,
        points:   [vector]
        onDrag:   snap
        postDrag: computeOut

    ##################################################
    # Caption

    hexColorProj   = "#" + new THREE.Color(1, .3, .3).getHexString()
    hexColorPerp   = "#" + new THREE.Color(0, .8, .8).getHexString()
    hexColorBasis1 = "#" + new THREE.Color(.8, .5, 0).getHexString()
    hexColorBasis2 = "#" + new THREE.Color(.8, 0, .5).getHexString()
    hexColorSummand1 = '#' + new THREE.Color(0.3020,0.6863,0.2902).getHexString()
    hexColorSummand2 = '#' + new THREE.Color(0.2157,0.4941,0.7216).getHexString()

    switch mode
        when 'full'
            @caption '<p><span id="sum-here"></span></p>'
            sumElt = document.getElementById 'sum-here'
            updateCaptions = () =>
                str = "\\text{proj}_{#{subName}}(#{vecLabel}) =" \
                    + "\\color{#{hexColorProj}}{#{vecLabel}_{#{subName}}} = "
                str += @texVector decompProj, color: hexColorProj
                str += '='
                str += @texCombo vectors, coeffs,
                    colors:      [hexColorSummand1, hexColorSummand2].slice(0, numVecs)
                    coeffColors: [hexColorSummand1, hexColorSummand2].slice(0, numVecs)
                katex.render str, sumElt
        when 'decomp'
            @caption '<p><span id="decomp-here"></span></p>'
            decompElt = document.getElementById 'decomp-here'
            updateCaptions = () =>
                str  = @texVector vector
                str += '='
                str += @texVector decompProj, color: hexColorProj
                str += '+'
                str += @texVector decompPerp, color: hexColorPerp
                katex.render str, decompElt
        when 'distance'
            @caption '<p><span id="sum-here"></span></p>' \
                + '<p><span id="dist-here"></span></p>'
            sumElt = document.getElementById 'sum-here'
            distElt = document.getElementById 'dist-here'
            updateCaptions = () =>
                str = "\\color{#{hexColorProj}}{#{vecLabel}_{#{subName}}} = "
                str += @texVector decompProj, color: hexColorProj
                str += '='
                str += @texCombo vectors, coeffs,
                    colors: [hexColorBasis1, hexColorBasis2].slice(0, numVecs)
                katex.render str, sumElt
                str =  "\\|\\color{#{hexColorPerp}}{x_{W^\\perp}}\\| ="
                str += "\\left\\|"
                str += @texVector vector
                str += '-'
                str += @texVector decompProj, color: hexColorProj
                str += "\\right\\|"
                str += '=' + decompLabels[1]
                katex.render str, distElt
        when 'basis'
            @caption '<p><span id="combo-here"></span></p>' \
                + '<p><span id="basis-here"></span></p>'
            comboElt = document.getElementById 'combo-here'
            basisElt = document.getElementById 'basis-here'
            updateCaptions = () =>
                str = "x = \\text{proj}_{#{subName}}(#{vecLabel}) ="
                str += @texVector vector
                str += '='
                str += @texCombo vectors, coeffs,
                    colors:      [hexColorSummand1, hexColorSummand2].slice(0, numVecs)
                    coeffColors: [hexColorSummand1, hexColorSummand2].slice(0, numVecs)
                katex.render str, comboElt
                str = '[x]_{\\mathcal B} = '
                str += '\\big('
                str += "#{coeffs[0].toFixed 2},\\;#{coeffs[1].toFixed 2}"
                str += '\\big)'
                katex.render str, basisElt
        when 'badbasis'
            @caption '<p><span id="combo-here"></span></p>' \
                + '<p><span id="basis-here"></span></p>'
            comboElt = document.getElementById 'combo-here'
            updateCaptions = () =>
                str  = 'x = '
                str += @texVector vector
                str += "\\neq"
                str += @texCombo vectors, coeffs,
                    colors:      [hexColorSummand1, hexColorSummand2].slice(0, numVecs)
                    coeffColors: [hexColorSummand1, hexColorSummand2].slice(0, numVecs)
                str += '='
                str += @texVector decompProj, color: hexColorProj
                katex.render str, comboElt

    # Project if necessary
    if constrainToW
        tmpVec = new THREE.Vector3 vector[0], vector[1], vector[2]
        subspace.project tmpVec, tmpVec
        vector[0] = tmpVec.x
        vector[1] = tmpVec.y
        vector[2] = tmpVec.z

    computeOut()

