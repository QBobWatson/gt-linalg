## -*- coffee -*-

<%inherit file="base2.mako"/>

<%block name="title">2x2 Matrix Transformations</%block>

<%block name="inline_style">
#help-text {
    # text-align: center;
# }
.mathbox-overlays {
    pointer-events: auto;
}
</%block>

##

ortho = 10000

window.matrix = [1,0,0,1]
window.updateMatrix = (multiplier) =>
    console.log "Asdfads"
    console.log multiplier
    matrix = window.matrix
    a = multiplier[0]*matrix[0] + multiplier[1]*matrix[2]
    b = multiplier[0]*matrix[1] + multiplier[1]*matrix[3]
    c = multiplier[2]*matrix[0] + multiplier[3]*matrix[2]
    d = multiplier[2]*matrix[1] + multiplier[3]*matrix[3]
    console.log a, b, c, d
    window.matrix = [a, b, c, d]



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
    matrix = [1,0,0,1]
    future_matrix = matrix
    if @urlParams.mat?
        matrix = @urlParams.mat.split(",").map parseFloat
    numTransforms = 3
    if @urlParams.num?
        numTransforms = parseInt @urlParams.num

    ##################################################
    # gui
    inverse = null

    # updateCaption = () =>
    #     str = @texMatrix [[matrix[0], matrix[2]], [matrix[1], matrix[3]]]
    #     str += @texVector inVec, color: '#00ff00'
    #     str += '=' + @texVector outVec, color: '#ffff00'
    #     katex.render str, eqnElt

    # updateMatrix = (multiplier) =>
    #     console.log "Asdfads"
    #     a = multiplier[0]*matrix[0] + multiplier[1]*matrix[2]
    #     b = multiplier[0]*matrix[1] + multiplier[1]*matrix[3]
    #     c = multiplier[2]*matrix[0] + multiplier[3]*matrix[2]
    #     d = multiplier[2]*matrix[1] + multiplier[3]*matrix[3]
    #     matrix = [a, b, c, d]

    # computeMatrix = (first) =>
    #     if not first
    #         mat = [1,0,0,1]
    #         for params in paramses
    #             mult = params.matrix
    #             a = mult[0]*mat[0] + mult[1]*mat[2]
    #             b = mult[0]*mat[1] + mult[1]*mat[3]
    #             c = mult[2]*mat[0] + mult[3]*mat[2]
    #             d = mult[2]*mat[1] + mult[3]*mat[3]
    #             mat = [a, b, c, d]
    #         matrix[0] = mat[0]
    #         matrix[1] = mat[1]
    #         matrix[2] = mat[2]
    #         matrix[3] = mat[3]
        # Compute inverse
        # det = matrix[0] * matrix[3] - matrix[1] * matrix[2]
        # if det*det < 0.00001
        #     inverse = null
        #     drag2.enabled = false
        # else
        #     inverse = [ matrix[3] / det, -matrix[1] / det,
        #                -matrix[2] / det,  matrix[0] / det]
        #     drag2.enabled = true
        # computeOut()
        # updateCaption()

    # class Params
    #     constructor: () ->
    #         @xscale = 1.0
    #         @yscale = 1.0
    #         @xshear = 0.0
    #         @yshear = 0.0
    #         @rotate = 0.0
    #         @matrix = [1,0,0,1]
    #     doScale: () =>
    #         @rotate = @xshear = @yshear = 0.0
    #         @matrix = [@xscale, 0, 0, @yscale]
    #         computeMatrix()
    #     doXShear: () =>
    #         @xscale = @yscale = 1.0
    #         @rotate = @yshear = 0.0
    #         @matrix = [1, @xshear, 0, 1]
    #         computeMatrix()
    #     doYShear: () =>
    #         @xscale = @yscale = 1.0
    #         @rotate = @xshear = 0.0
    #         @matrix = [1, 0, @yshear, 1]
    #         computeMatrix()
    #     doRotate: () =>
    #         @xscale = @yscale = 1.0
    #         @xshear = @yshear = 0.0
    #         c = Math.cos @rotate
    #         s = Math.sin @rotate
    #         @matrix = [c, -s, s, c]
    #         computeMatrix()

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
            matrix: () -> [window.matrix[0], window.matrix[1], 0, 0, window.matrix[2], window.matrix[3], 0, 0,
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
    # captions
    @caption '''
    <p id="pick_inst"> Pick a challenge! </p>
    <ul id="challenge_list">
        <li><button>Challenge 1</button></li>
        <li><button>Challenge 2</button></li>
    </ul>
    <p id="challenge_inst"> </p>
    <table id="button_table">
        <tr>
            <td><button type="button" id="scale_2">Scale horizontally by 2</button></td>
            <td><button type="button" id="scale_half">Scale horizontally by 1/2</button></td>
        </tr>
        <tr>
            <td><button type="button" id="shear_left">Shear left by 1/2</button></td>
            <td><button type="button" id="shear_right">Shear right by 1/2</button></td>
        </tr>
        <tr>
            <td><button type="button" id="shear_up">Shear up by 1/2</button></td>
            <td><button type="button" id="shear_down">Shear down by 1/2</button></td>
        </tr>
        <tr>
            <td><button type="button" id="reflect_x_axis">Reflect about the x-axis</button></td>
            <td><button type="button">Reflect about the y-axis</button></td>
        </tr>
    </table>
                <p><span id="eqn-here"></span></p>
                <p id="help-text"></p>
             '''

    matrices = {
        'scale_2': [2, 0, 0, 1],
        'scale_half' : [0.5, 0, 0, 1],
        'shear_left' : [1, -0.5, 0, 1],
        'shear_right' : [1, 0.5, 0, 1],
        'shear_up' : [1, 0, 0.5, 1],
        'shear_down' : [1, 0, -0.5, 1]
        # 'reflect_x_axis' : [1, 0, 0, -1]
    }  

    challenges = [{
        message : 'Transform the distorted figure back to the original figure.',
        winning_matrix : [1, 0, 0, 1],
    }]

    for id, matrix of matrices
        (() -> 
            id2 = id
            button = document.getElementById id2
            button.addEventListener 'click', () -> window.updateMatrix(matrices[id2])
        )()
