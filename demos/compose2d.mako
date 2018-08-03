## -*- coffee -*-

<%inherit file="base2.mako"/>

<%block name="title">Composing 2x2 Transformations</%block>

##

ortho = 10000

color1 = new Color("green")
color2 = new Color("violet")
color3 = new Color("red")


window.demo = new Demo2D {
    ortho: ortho
    camera:
        position: [2.2, 0, ortho]
        lookAt:   [2.2, 0, 0]
    vertical: 3.0
}, () ->
    window.mathbox = @mathbox

    ##################################################
    # Demo parameters
    range = @urlParams.get 'range', 'float', 3

    transforms = @urlParams.get 'names', 'str[]', ['T', 'U']
    strip = (s) -> s.replace /^\s+|\s+$/g, ''
    names = (strip s for s in transforms)

    vector1 = @urlParams.get 'vec', 'float[]', [1, 2]
    vector2 = [0, 0]
    vector3 = [0, 0]

    matrix1 = @urlParams.get 'mat1', 'float[]', [1,0,0,1]
    matrix2 = @urlParams.get 'mat2', 'float[]', [1,0,0,1]
    matrix3 = [0,0,0,0]
    computeProduct = () =>
        matrix3[0] = matrix2[0]*matrix1[0] + matrix2[1]*matrix1[2]
        matrix3[1] = matrix2[0]*matrix1[1] + matrix2[1]*matrix1[3]
        matrix3[2] = matrix2[2]*matrix1[0] + matrix2[3]*matrix1[2]
        matrix3[3] = matrix2[2]*matrix1[1] + matrix2[3]*matrix1[3]
        computeOut()
    matrices = [matrix1, matrix2, matrix3]

    computeOut = () ->
        vector2[0] = matrix1[0] * vector1[0] + matrix1[1] * vector1[1]
        vector2[1] = matrix1[2] * vector1[0] + matrix1[3] * vector1[1]
        vector3[0] = matrix2[0] * vector2[0] + matrix2[1] * vector2[1]
        vector3[1] = matrix2[2] * vector2[0] + matrix2[3] * vector2[1]
        updateCaption()

    ##################################################
    # gui

    class Params
        constructor: (matrix, inverseName) ->
            @xscale = 1.0
            @yscale = 1.0
            @xshear = 0.0
            @yshear = 0.0
            @rotate = 0.0
            @matrix = matrix
            @[inverseName] = () =>
                det = @other[0] * @other[3] - @other[1] * @other[2]
                if Math.abs(det) < .00001
                    window.alert "Matrix is not invertible!"
                    return
                @xscale = @yscale = 1.0
                @xshear = @yshear = @rotate = 0.0
                @matrix[0] =  @other[3]/det
                @matrix[1] = -@other[1]/det
                @matrix[2] = -@other[2]/det
                @matrix[3] =  @other[0]/det
                computeProduct()
            @['show grid'] = false
        doScale: () =>
            @rotate = @xshear = @yshear = 0.0
            @matrix[0] = @xscale
            @matrix[1] = @matrix[2] = 0
            @matrix[3] = @yscale
            computeProduct()
        doXShear: () =>
            @xscale = @yscale = 1.0
            @rotate = @yshear = 0.0
            @matrix[0] = @matrix[3] = 1
            @matrix[1] = @xshear
            @matrix[2] = 0
            computeProduct()
        doYShear: () =>
            @xscale = @yscale = 1.0
            @rotate = @xshear = 0.0
            @matrix[0] = @matrix[3] = 1
            @matrix[1] = 0
            @matrix[2] = @yshear
            computeProduct()
        doRotate: () =>
            @xscale = @yscale = 1.0
            @xshear = @yshear = 0.0
            c = Math.cos @rotate
            s = Math.sin @rotate
            @matrix[0] = @matrix[3] = c
            @matrix[1] = -s
            @matrix[2] = s
            computeProduct()

    paramses = []
    gui = new dat.GUI()
    gui.closed = @urlParams.closed?
    folderNames = [transforms[1], transforms[0]]
    inverseNames = ["#{transforms[0]} inverse", "#{transforms[1]} inverse"]
    folders = []
    for i in [0...2]
        folder = gui.addFolder(folderNames[i])
        params = new Params(matrices[i], inverseNames[i])
        folder.open()
        folder.add(params, 'xscale', -2, 2).step(0.05).onChange(params.doScale).listen()
        folder.add(params, 'yscale', -2, 2).step(0.05).onChange(params.doScale).listen()
        folder.add(params, 'rotate', -π, π).step(0.1*π)
            .onChange(params.doRotate).listen()
        folder.add(params, 'xshear', -2, 2).step(0.05).onChange(params.doXShear).listen()
        folder.add(params, 'yshear', -2, 2).step(0.05).onChange(params.doYShear).listen()
        folder.add params, inverseNames[i]
        params['show grid'] = if urlParams["show#{i+1}"]? then true else false
        folder.add(params, 'show grid').onFinishChange do (i) -> (val) ->
            mathbox.select(".grid#{i+1}").set 'visible', val
        paramses.push params
        folders.push folder
    paramses[0].other = paramses[1].matrix
    paramses[1].other = paramses[0].matrix

    ##################################################
    # views
    view1 = @view
        name:       'view1'
        axisLabels: false
        grid:       false
        viewRange:  [[-range, range], [-range, range]]

    view2 = @view
        name:       'view2'
        axisLabels: false
        grid:       false
        viewOpts:   position: [2.2, 0, 0]
        viewRange:  [[-range, range], [-range, range]]

    view3 = @view
        name:       'view3'
        axisLabels: false
        grid:       false
        viewOpts:   position: [4.4, 0, 0]
        viewRange:  [[-range, range], [-range, range]]

    ##################################################
    # Clip cubes
    clipCube2 = @clipCube view2,
        draw:   false
        hilite: false
        range:  range
        pass:   'view'

    clipCube3 = @clipCube view3,
        draw:   false
        hilite: false
        range:  range
        pass:   'view'

    ##################################################
    # grids
    gridData = mathbox
        .area
            width:    11
            height:   11
            channels: 2
            rangeX:   [-range, range]
            rangeY:   [-range, range]

    makeSurface = (view, matrix, color, klass) ->
        view
            .transform {},
                matrix: () ->
                    return [matrix[0], matrix[1], 0, 0,
                            matrix[2], matrix[3], 0, 0,
                            0, 0, 1, 0,
                            0, 0, 0, 1]
            .surface
                color:   color.arr()
                points:  gridData
                fill:    false
                lineX:   true
                lineY:   true
                width:   2
                opacity: 0.5
                zOrder:  0
                classes: [klass]

    makeSurface view1,             [1,0,0,1], color1,             'grid1'
    makeSurface clipCube2.clipped, [1,0,0,1], color2,             'grid2'
    makeSurface clipCube2.clipped, matrix1,   color1.darken(.15), 'grid1'
    makeSurface clipCube3.clipped, matrix2,   color2.darken(.15), 'grid2'
    makeSurface clipCube3.clipped, matrix3,   color1.darken(.3),  'grid1'
    mathbox.select('.grid1').set 'visible', paramses[0]['show grid']
    mathbox.select('.grid2').set 'visible', paramses[1]['show grid']

    ##################################################
    # labeled vectors
    vectorOpts =
        size:   4
        width:  3
        zIndex: 2
    zeroOpts =
        zIndex: 2
        size:   15
    labelOpts =
        offset:  [0, 25]
        size:    15
        zIndex:  3
        outline: 0
    hiliteOpts =
        zTest:   true
        zWrite:  true
        zOrder:  2
        opacity: 0.5

    @labeledVectors view1,
        name:          'labeled1'
        vectors:       [vector1]
        colors:        [color1]
        labels:        ['x']
        live:          true
        zeroPoints:    true
        zeroThreshold: 0.3
        vectorOpts:    vectorOpts
        labelOpts:     labelOpts
        zeroOpts:      zeroOpts

    @labeledVectors view2,
        name:          'labeled2'
        vectors:       [vector2]
        colors:        [color2]
        labels:        ["#{names[1]}(x)"]
        live:          true
        zeroPoints:    true
        zeroThreshold: 0.3
        vectorOpts:    vectorOpts
        labelOpts:     labelOpts
        zeroOpts:      zeroOpts

    @labeledVectors view3,
        name:          'labeled3'
        vectors:       [vector3]
        colors:        [color3]
        labels:        ["#{names[0]}(#{names[1]}(x))"]
        live:          true
        zeroPoints:    true
        zeroThreshold: 0.3
        vectorOpts:    vectorOpts
        labelOpts:     labelOpts
        zeroOpts:      zeroOpts

    ##################################################
    # dragging the first vector
    @draggable view1,
        name:       'drag1'
        points:     [vector1]
        postDrag:   computeOut
        hiliteOpts: hiliteOpts


    ##################################################
    # captions
    @caption '''<p><span id="matrix1-here"></span></p>
                <p><span id="matrix2-here"></span></p>
                <p><span id="matrix3-here"></span></p>
             '''
    matrix1Elt = document.getElementById 'matrix1-here'
    matrix2Elt = document.getElementById 'matrix2-here'
    matrix3Elt = document.getElementById 'matrix3-here'

    cols = (mat) ->
        [[mat[0], mat[2]], [mat[1], mat[3]]]

    updateCaption = () =>
        str  = "#{names[1]}(\\color{#{color1.str()}}{x}) = "
        str += @texMatrix cols(matrix1)
        str += @texVector vector1, color: color1.str()
        str += "="
        str += @texVector vector2, color: color2.str()
        katex.render str, matrix1Elt
        str  = "#{names[0]}(\\color{#{color2.str()}}{#{names[1]}(x)}) = "
        str += @texMatrix cols(matrix2)
        str += @texVector vector2, color: color2.str()
        str += "="
        str += @texVector vector3, color: color3.str()
        katex.render str, matrix2Elt
        str  = "#{names[0]}\\circ #{names[1]}(\\color{#{color1.str()}}{x}) = "
        str += @texMatrix cols(matrix3)
        str += @texVector vector1, color: color1.str()
        str += "="
        str += @texVector vector3, color: color3.str()
        katex.render str, matrix3Elt

    computeProduct()
