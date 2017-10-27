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

window.are_matrices_equal = (m1, m2) ->
    for i in [0...4]
        if Math.abs(window.matrix[i] - window.winning_matrix[i]) > 0.0001
            return false
    return true



window.matrix = [1,0,0,1]
window.updateMatrix = (multiplier) =>
    @count += 1
    matrix = @matrix
    a = multiplier[0]*matrix[0] + multiplier[1]*matrix[2]
    b = multiplier[0]*matrix[1] + multiplier[1]*matrix[3]
    c = multiplier[2]*matrix[0] + multiplier[3]*matrix[2]
    d = multiplier[2]*matrix[1] + multiplier[3]*matrix[3]
    @matrix = [a, b, c, d]
    if @are_matrices_equal(@matrix, @winning_matrix)
        alert_str = "Congratulations, you completed the challege in #{@count} steps!"
        if @count > @min_count
            alert_str += "That's more than the optimal. Try again!"
        else
            alert_str += "That's the optimal number of moves!"
        setTimeout(() -> alert alert_str, 1000)
        @hide_buttons()
        @show_challenge_picker()

window.startGame = (challenge) ->
    @count = 0
    @matrix = challenge.starting_matrix
    @winning_matrix = challenge.winning_matrix
    @min_count = challenge.min_count
    par = document.getElementById 'challenge_inst'
    par.innerHTML = challenge.message
    @show_buttons()
    @hide_challenge_picker()

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
    <div id="picker_div">
    <p id="pick_inst"> Pick a challenge! </p>
    <ul id="challenge_list">
        <li><button id="ch1">Challenge 1</button></li>
        <li><button id="ch2">Challenge 2</button></li>
    </ul>
    </div>
    <div id="challenge_div">
    <p id="challenge_inst"> </p>
    <table id="button_table">
        <tr>
            <td><button type="button" id="shear_left">Shear left</button></td>
            <td><button type="button" id="shear_right">Shear right</button></td>
        </tr>
        <tr>
            <td><button type="button" id="shear_up">Shear up</button></td>
            <td><button type="button" id="shear_down">Shear down</button></td>
        </tr>

    </table>
    <p>(Reload to choose another challenge...)</p>
    </div>
             '''

    matrices = {
        # 'scale_2': [2, 0, 0, 1],
        # 'scale_half' : [0.5, 0, 0, 1],
        'shear_left' : [1, -1, 0, 1],
        'shear_right' : [1, 1, 0, 1],
        'shear_up' : [1, 0, 1, 1],
        'shear_down' : [1, 0, -1, 1]
        # 'reflect_x_axis' : [1, 0, 0, -1]
    }  

    challenges = [{
        message : 'Transform the distorted figure back to the original figure.',
        starting_matrix : [5, 4, 6, 5],
        winning_matrix : [1, 0, 0, 1],
        min_count : 6
    }, {
        message : 'Rotate the figure by 90 degrees counterclockwise.',
        starting_matrix : [1, 0, 0, 1],
        winning_matrix : [0, -1, 1, 0],
        min_count : 3
    }]

    for i in [1...challenges.length+1]
        (() ->
            ii = i
            ch = challenges[ii-1]
            button = document.getElementById "ch#{ii}"
            button.addEventListener 'click', () -> window.startGame(ch)
        )()

    for id, matrix of matrices
        (() -> 
            id2 = id
            button = document.getElementById id2
            button.addEventListener 'click', () -> window.updateMatrix(matrices[id2])
        )()
    window.hide_buttons()


window.show_buttons = () -> 
    buttons = document.getElementById 'challenge_div'
    buttons.style.display = "block"

window.hide_buttons = () -> 
    buttons = document.getElementById 'challenge_div'
    buttons.style.display = "none"

window.show_challenge_picker = () ->
    picker_div = document.getElementById 'picker_div'
    picker_div.style.display = "block"

window.hide_challenge_picker = () ->
    picker_div = document.getElementById 'picker_div'
    picker_div.style.display = "none"


        # <tr>
        #     <td><button type="button" id="scale_2">Scale horizontally by 2</button></td>
        #     <td><button type="button" id="scale_half">Scale horizontally by 1/2</button></td>
        # </tr>

        # <tr>
        #     <td><button type="button" id="reflect_x_axis">Reflect about the x-axis</button></td>
        #     <td><button type="button">Reflect about the y-axis</button></td>
        # </tr>