## -*- coffee -*-

<%inherit file="base2.mako"/>

<%block name="title">Least Squares Solutions</%block>

##

range = urlParams.get 'range', 'float', 10

# Spanning vectors
vector1 = urlParams.get 'v1', 'float[]', [3,0,0]
vector2 = urlParams.get 'v2', 'float[]', [0,3,0]
vector3 = urlParams.get 'v3', 'float[]', [3,3,0]
# "b" vector: solving Ax=b
vector  = urlParams.get 'vec', 'float[]', [5,5,5]
size = vector1.length

surfaceColor  = new Color "violet"
spanVecColor  = new Color "orange"
linComboColor = new Color "green"
bColor        = new Color "red"
bHatColor     = new Color "blue"

numVecs = 2
if urlParams.v3?
    numVecs = 3
else if urlParams.v1? and not urlParams.v2?
    numVecs = 1

matrix = [vector1.slice(), vector2.slice(), vector3.slice()].slice(0, numVecs)
rref = [vector1.slice(), vector2.slice(), vector3.slice()].slice(0, numVecs)
[nulBasis, colBasis, Emat, solve] = rowReduce(rref)

vector1[2] ?= 0
vector2[2] ?= 0
vector3[2] ?= 0
vectors = [vector1, vector2, vector3].slice(0, numVecs)

# this is "x hat"
solution = [0, 0, 0].slice(0, numVecs)
# this is "b hat"
projection = [0, 0, 0]

labels = urlParams.get 'labels', 'str[]', ['v1', 'v2', 'v3']
labels = labels.slice(0, numVecs)
texLabels = (a.replace(/(\D+)/, '$1_') for a in labels)
vecLabel = urlParams.vecLabel ? 'b'

subName = urlParams.subname ? 'W'


window.demo = new (if size == 2 then Demo2D else Demo) {}, () ->
    window.mathbox = @mathbox

    view = @view
        axes:      false
        grid:      false
        viewRange: [[-range,range],[-range,range],[-range,range]].slice(0, size)

    clipCube = @clipCube view,
        draw:   true
        hilite: size == 3

    # Zero point
    view
        .array
            channels: 3
            width:    1
            live:     false
            data:     [[0,0,0]]
        .point
            color:    "black"
            size:     15
            zIndex:   3

    ##################################################
    # Compute and draw subspace and its complement
    subspace = @subspace
        vectors: vectors
        live:    false
        noPlane: size == 2
        color:   surfaceColor
        # Lines before planes for transparency
        lineOpts:
            zOrder: 0
        surfaceOpts:
            zOrder: 1
    subspace.draw clipCube.clipped

    @grid clipCube.clipped,
        vectors: vectors
        live: false
        lineOpts:
            color: surfaceColor
            opacity: .35

    ##################################################
    # Labeled vectors
    @labeledVectors view,
        name:       'basis'
        vectors:    vectors
        colors:     [spanVecColor.arr(.9),
                     spanVecColor.arr(.9),
                     spanVecColor.arr(.9)].slice(0, numVecs)
        labels:     labels
        live:       false
        vectorOpts: zIndex: 2
        labelOpts:  zIndex: 3

    @labeledPoints view,
        name:      'bandbhat'
        points:    [vector, projection]
        colors:    [bColor, bHatColor]
        labels:    [vecLabel, "#{vecLabel}_Col(A)"]
        live:      true
        pointOpts: zIndex: 4
        labelOpts: zIndex: 5

    view
        .array
            width:    2
            channels: 3
            data:     [vector, projection]
        .line
            color:  [0.5, 0.5, 0.5]
            width:  3

    ##################################################
    # Linear combination
    linCombo = @linearCombo view,
        coeffs:    solution
        coeffVars: [0, 1, 2]
        vectors:   vectors
        colors:    [linComboColor, linComboColor, linComboColor]
        lineOpts:  zIndex: 3

    ##################################################
    # Dragging and snapping
    tmpVec = new THREE.Vector3()
    nulSpace = @subspace vectors: nulBasis
    computeOut = () =>
        # Compute b hat
        tmpVec.set vector[0], vector[1], vector[2]
        subspace.project tmpVec, tmpVec
        projection[0] = tmpVec.x
        projection[1] = tmpVec.y
        projection[2] = tmpVec.z
        # Compute x hat
        particular = solve projection
        particular[2] ?= 0
        if numVecs > subspace.dim
            # Find the closest solution to the current solution
            tmpVec.set solution[0]-particular[0],
                       solution[1]-particular[1],
                       solution[2]-particular[2]
            nulSpace.project tmpVec, tmpVec
            solution[0] = tmpVec.x + particular[0]
            if numVecs >= 2
                solution[1] = tmpVec.y + particular[1]
            if numVecs >= 3
                solution[2] = tmpVec.z + particular[2]
        else
            solution[i] = particular[i] for i in [0...solution.length]
        updateCaptions()

    @draggable view,
        points:   [vector]
        #onDrag:   snap
        postDrag: computeOut

    ##################################################
    # Caption
    str =  '<p><span id="vectoreqn-here"></span></p>'
    str += '<p><span id="matrixeqn-here"></span></p>'
    @caption str
    vectorElt = document.getElementById 'vectoreqn-here'
    matrixElt = document.getElementById 'matrixeqn-here'

    updateCaptions = () =>
        a = solution[0].toFixed 2
        coeffColor = linComboColor
        str = "\\color{#{coeffColor.str()}}{#{a}}\\, " \
            + "\\color{#{spanVecColor.str()}}{#{texLabels[0]}}"
        if numVecs >= 2
            if solution[1] < 0
                sign = ''
            else
                sign = '+'
            a = solution[1].toFixed 2
            str += "#{sign}\\color{#{coeffColor.str()}}{#{a}}\\, " \
                +  "\\color{#{spanVecColor.str()}}{#{texLabels[1]}}"
        if numVecs >= 3
            if solution[2] < 0
                sign = ''
            else
                sign = '+'
            a = solution[2].toFixed 2
            str += "#{sign}\\color{#{coeffColor.str()}}{#{a}}\\, " \
                +  "\\color{#{spanVecColor.str()}}{#{texLabels[2]}}"
        str += "= \\color{#{bHatColor.str()}}{#{vecLabel}_{\\text{Col}(A)}}"
        katex.render str, vectorElt

        str  = "A \\color{#{coeffColor.str()}}{\\hat x} ="
        str += @texMatrix matrix
        str += @texVector solution, color: coeffColor
        str += '='
        str += @texVector projection, color: bHatColor
        str += "= \\color{#{bHatColor.str()}}{#{vecLabel}_{\\text{Col}(A)}}"
        katex.render str, matrixElt

    computeOut()
