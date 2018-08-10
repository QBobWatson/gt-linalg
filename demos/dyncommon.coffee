## -*- coding: utf-8 -*-

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

######################################################################
# * Compute standard form of the 2x2 block matrix

almostZero = (x) -> Math.abs(x) < 1e-5

normalize = (b) ->
    n = Math.sqrt(b[0]*b[0] + b[1]*b[1])
    [b[0]/n, b[1]/n]

mv3v2 = (v1, v2, b) -> [
        v1[0]*b[0] + v2[0]*b[1],
        v1[1]*b[0] + v2[1]*b[1],
        v1[2]*b[0] + v2[2]*b[1],
    ]

matrixInfo = (matrix) ->
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
        str += katex.renderToString "\\lambda = #{Reλ.toFixed 2}\\pm #{Imλ.toFixed 2}i."
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
        λ1 = (trace - δ) / 2
        λ2 = (trace + δ) / 2
        negate1 = false
        negate2 = false
        if λ1 < 0
            λ1 *= -1
            negate1 = true
        if λ2 < 0
            λ2 *= -1
            negate2 = true
        if λ1 >= λ2
            [λ2, λ1] = [λ1, λ2]
            [negate2, negate1] = [negate1, negate2]
        opts =
            λ1: λ1
            λ2: λ2
            negate1: negate1
            negate2: negate2
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
        swap = () ->
            [opts.negate2, opts.negate1] = [opts.negate1, opts.negate2]
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
        λ1p = opts.λ1 * (if opts.negate1 then -1 else 1)
        λ2p = opts.λ2 * (if opts.negate2 then -1 else 1)
        eigenStrs.push "This is the <span class=\"espace-1\">" +
                       "#{λ1p.toFixed 2}-eigenspace.</span>"
        eigenStrs.push "This is the <span class=\"espace-2\">" +
                       "#{λ2p.toFixed 2}-eigenspace.</span>"

    basis1:     basis1
    basis2:     basis2
    type:       type
    typeOpts:   opts
    axisColors: axisColors
    eigenStrs:  eigenStrs


######################################################################
# * Demo

dynamicsDemo = (controller, opts) ->
    dynView    = opts.dynView
    params     = opts.params
    eigenStr   = opts.eigenStr
    matName    = opts.matName    ? 'A'
    vecName    = opts.vecName    ? 'x'
    size       = opts.size       ? 2
    eigenz     = opts.eigenz     ? 1
    suffix     = opts.suffix     ? ''
    element    = opts.element    ? document.getElementById "mathbox"
    captionElt = opts.captionElt ? document.getElementById "caption"
    vecColor   = opts.vecColor   ? new Color("red")
    dragHook   = opts.dragHook   ? () ->

    vectorIn  = opts.vectorIn?.slice() ? [.5, 0, 0]
    vectorOut = [0, 0, 0]

    demo = window.demo = new (if size == 3 then Demo else Demo2D) {
        mathbox:
            element: element
            size: aspect: 1
        vertical: 1.05
    }, () ->
        view = @view
            viewRange: [[-1, 1], [-1, 1], [-1, 1]]
            axes:      false
            grid:      false
        clipCube = @clipCube view,
            draw:   size == 3
            hilite: false

        dynView.updateView @mathbox, clipCube.clipped

        @dynView = dynView
        @controller = controller

        ##################################################
        # Caption
        te = dynView.matrixOrigCoords.elements
        if size == 2
            displayMat = [[te[0], te[1]], [te[4], te[5]]]
        else if size == 3
            displayMat = [[te[0], te[1], te[2]],
                          [te[4], te[5], te[6]],
                          [te[8], te[9], te[10]]]

        str  = "<p><span id=\"mat-here#{suffix}\"></span>" +
               "<span id=\"mult-here#{suffix}\"></span></p>"
        str += eigenStr
        captionElt.innerHTML = str

        matElt = document.getElementById "mat-here#{suffix}"
        multElt = document.getElementById "mult-here#{suffix}"
        str = "#{matName} = " + @texMatrix displayMat
        katex.render str, matElt

        updateCaption = () =>
            vin  = vectorIn.slice  0, size
            vout = vectorOut.slice 0, size
            str = '\\qquad ' + matName +
                  @texVector((x*10 for x in vin), color: vecColor) +
                  " = " +
                  @texVector((x*10 for x in vout), color: vecColor.darken(.1))
            katex.render str, multElt

        ##################################################
        # Test vector
        viewT = dynView.view

        labeled = @labeledVectors view,
            vectors:       [vectorIn, vectorOut]
            colors:        [vecColor, vecColor.darken(.1)]
            labels:        [vecName, matName + vecName]
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
            subspace = @subspace vectors: [dynView.v1, dynView.v2]
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
                dragHook vectorIn

        computeOut = () ->
            return unless params["Test vector"]
            [vectorOut[0], vectorOut[1], vectorOut[2]] = vectorIn
            dynView.matrixOrigCoords.applyToVector3Array vectorOut
            updateCaption()

        @setVec = (vec) ->
            [vectorIn[0], vectorIn[1], vectorIn[2]] = vec
            computeOut()
            computePath()

        @toggleVector = (val) =>
            drag.enabled = params["Test vector"] or params["Show path"]
            if val
                labeled.show()
                computeOut()
                multElt.classList.remove "hidden"
            else
                labeled.hide()
                multElt.classList.add "hidden"
        @toggleVector params["Test vector"]

        ##################################################
        # Test path
        path = ([0,0,0] for [0..100])
        computePath = () =>
            return unless params["Show path"]
            vec = vectorIn.slice()
            dynView.coordMatInv.applyToVector3Array vec
            controller.current.makePath vec, path
        viewT.array
            channels: 3
            width:    path.length
            live:     true
            data:     path
        pathElt = viewT.line
            color:    new Color("orange").arr()
            width:    5
            opacity:  1
            zBias:    0
            zIndex:   4

        @togglePath = (val) =>
            computePath() if val
            pathElt.set 'visible', val
            drag.enabled = params["Test vector"] or params["Show path"]
        @togglePath params["Show path"]


