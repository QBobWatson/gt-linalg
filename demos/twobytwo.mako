## -*- coffee -*-

<%inherit file="base2.mako"/>

<%block name="title">2x2 Matrix Transformations</%block>

<%block name="inline_style">
#help-text {
    text-align: center;
}
</%block>

##

ortho = 10000

color1 = new Color "green"
color2 = new Color "red"

window.demo = new Demo2D {
    preload:
        image: 'img/' + (urlParams.pic ? "theo2.jpg")
    ortho: ortho
    camera:
        position: [1.1, 0, ortho]
        lookAt:   [1.1, 0, 0]
    vertical: 2.2
}, () ->
    window.mathbox = @mathbox

    ##################################################
    # Demo parameters
    matrix = @urlParams.get 'mat', 'float[]', [1,0,0,1]
    numTransforms = @urlParams.get 'num', 'int', 3

    ##################################################
    # gui
    inverse = null

    updateCaption = () =>
        str = @texMatrix [[matrix[0], matrix[2]], [matrix[1], matrix[3]]]
        str += @texVector inVec, color: color1
        str += '=' + @texVector outVec, color: color2
        katex.render str, eqnElt

    computeMatrix = (first) =>
        if not first
            mat = [1,0,0,1]
            for params in paramses
                mult = params.matrix
                a = mult[0]*mat[0] + mult[1]*mat[2]
                b = mult[0]*mat[1] + mult[1]*mat[3]
                c = mult[2]*mat[0] + mult[3]*mat[2]
                d = mult[2]*mat[1] + mult[3]*mat[3]
                mat = [a, b, c, d]
            matrix[0] = mat[0]
            matrix[1] = mat[1]
            matrix[2] = mat[2]
            matrix[3] = mat[3]
        # Compute inverse
        det = matrix[0] * matrix[3] - matrix[1] * matrix[2]
        if det*det < 0.00001
            inverse = null
            drag2.enabled = false
        else
            inverse = [ matrix[3] / det, -matrix[1] / det,
                       -matrix[2] / det,  matrix[0] / det]
            drag2.enabled = true
        computeOut()
        updateCaption()

    class Params
        constructor: () ->
            @xscale = 1.0
            @yscale = 1.0
            @xshear = 0.0
            @yshear = 0.0
            @rotate = 0.0
            @matrix = [1,0,0,1]
        doScale: () =>
            @rotate = @xshear = @yshear = 0.0
            @matrix = [@xscale, 0, 0, @yscale]
            computeMatrix()
        doXShear: () =>
            @xscale = @yscale = 1.0
            @rotate = @yshear = 0.0
            @matrix = [1, @xshear, 0, 1]
            computeMatrix()
        doYShear: () =>
            @xscale = @yscale = 1.0
            @rotate = @xshear = 0.0
            @matrix = [1, 0, @yshear, 1]
            computeMatrix()
        doRotate: () =>
            @xscale = @yscale = 1.0
            @xshear = @yshear = 0.0
            c = Math.cos @rotate
            s = Math.sin @rotate
            @matrix = [c, -s, s, c]
            computeMatrix()

    paramses = []
    gui = new dat.GUI()
    gui.closed = @urlParams.closed?
    for i in [0...numTransforms]
        folder = gui.addFolder("Transform #{i+1}")
        params = new Params()
        folder.open() if i == 0
        folder.add(params, 'xscale', -2, 2).step(0.05).onChange(params.doScale).listen()
        folder.add(params, 'yscale', -2, 2).step(0.05).onChange(params.doScale).listen()
        folder.add(params, 'rotate', -π, π).step(0.1*π)
            .onChange(params.doRotate).listen()
        folder.add(params, 'xshear', -2, 2).step(0.05).onChange(params.doXShear).listen()
        folder.add(params, 'yshear', -2, 2).step(0.05).onChange(params.doYShear).listen()
        paramses.push params

    ##################################################
    # views
    gridOpts =
        color:   'white'
        opacity: 0.25
        width:   1
        zOrder:  1
        zIndex:  1
    axisOpts =
        color:   'white'
        opacity: 0.6
        zIndex:  1
        zOrder:  1
        size:    3

    view1 = @view
        name:       'view1'
        gridOpts:   gridOpts
        axisOpts:   axisOpts
        axisLabels: false
    view1
        .image image: @image
        .matrix
            width:    2
            height:   2
            channels: 2
            data:     [[[-10, -10], [10, -10]],
                       [[-10,  10], [10,  10]]]
        .surface
            color:  'white'
            points: '<'
            map:    '<<'
            fill:   true
            zOrder: 0

    view2 = @view
        name:     'view2'
        viewOpts: position: [2.2, 0, 0]
        gridOpts: gridOpts
        axisOpts:   axisOpts
        axisLabels: false

    clipCube = @clipCube view2,
        draw:   false
        hilite: false
        range:  10.0
        pass:   'view'
    clipCube.clipped
        .transform {},
            matrix: () -> [matrix[0], matrix[1], 0, 0, matrix[2], matrix[3], 0, 0,
                           0, 0, 1, 0, 0, 0, 0, 1]
        .image image: @image
        .matrix
            width:    2
            height:   2
            channels: 2
            data:     [[[-10, -10], [10, -10]],
                       [[-10,  10], [10,  10]]]
        .surface
            color:  'white'
            points: '<'
            map:    '<<'
            fill:   true
            zOrder: 0

    ##################################################
    # vectors
    computeOut = () ->
        outVec[0] = matrix[0] * inVec[0] + matrix[1] * inVec[1]
        outVec[1] = matrix[2] * inVec[0] + matrix[3] * inVec[1]
    computeIn = () ->
        if inverse?
            inVec[0] = inverse[0] * outVec[0] + inverse[1] * outVec[1]
            inVec[1] = inverse[2] * outVec[0] + inverse[3] * outVec[1]

    vectorOpts =
        size:   4
        width:  3
        zIndex: 2
    zeroOpts =
        zIndex: 2
        size:   15
    labelOpts =
        offset:     [0, 25]
        size:       15
        zIndex:     3
        outline:    0
        background: "white"
    hiliteOpts =
        zTest:   true
        zWrite:  true
        zOrder:  2
        opacity: 0.5

    inVec  = [2, 4, 0]
    @labeledVectors view1,
        name:          'labeled1'
        vectors:       [inVec]
        colors:        [color1.brighten .1]
        labels:        ['x']
        live:          true
        zeroPoints:    true
        zeroThreshold: 0.3
        vectorOpts:    vectorOpts
        labelOpts:     labelOpts
        zeroOpts:      zeroOpts

    @draggable view1,
        name:       'drag1'
        points:     [inVec]
        onDrag:     computeOut
        postDrag:   updateCaption
        hiliteOpts: hiliteOpts

    outVec = [2, 4, 0]
    @labeledVectors view2,
        name:          'labeled2'
        vectors:       [outVec]
        colors:        [color2.brighten .1]
        labels:        ['b']
        live:          true
        zeroPoints:    true
        zeroThreshold: 0.3
        vectorOpts:    vectorOpts
        labelOpts:     labelOpts
        zeroOpts:      zeroOpts

    drag2 = @draggable view2,
        name:       'drag2'
        points:     [outVec]
        onDrag:     computeIn
        postDrag:   updateCaption
        hiliteOpts: hiliteOpts

    ##################################################
    # captions
    @caption '''<p><span id="eqn-here"></span></p>
                <p id="help-text">[Click and drag the vector heads]</p>
             '''
    eqnElt = document.getElementById 'eqn-here'

    computeMatrix true
