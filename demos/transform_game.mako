## -*- coffee -*-

<%inherit file="base2.mako"/>

<%block name="title">Transformation challenges</%block>
<%block name="js">
    ${parent.js()}
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.2.1/jquery.min.js"></script>
</%block>

<%block name="inline_style">
#help-text {
    # text-align: center;
# }
.mathbox-overlays {
    pointer-events: auto;
}
#optimal {
    color: green
}
#non-optimal {
    color: yellow
}
#new_challenge_div, #picker_div, #challenge_div, #challenge_list {
    text-align: center
}

#button-table {
    margin: auto
}
#challenge_list {
    list-style: none;
    padding-left:0
}
button {
    padding: 0.5em;
    border-radius: 0;
    border: none;
    background-color: white
}
button:hover {
    background-color: LightBlue;
}
#new-challenge-btn {
    background-color: LightGreen;
}
#new-challenge-btn:hover {
    background-color: #33CC33;
}

</%block>

##

ortho = 10000

window.are_matrices_equal = (m1, m2) ->
    for i in [0...4]
        if Math.abs(window.matrix[i] - window.winning_matrix[i]) > 0.0001
            return false
    return true


window.multiply = (m1, m2) ->
    a = m1[0]*m2[0] + m1[1]*m2[2]
    b = m1[0]*m2[1] + m1[1]*m2[3]
    c = m1[2]*m2[0] + m1[3]*m2[2]
    d = m1[2]*m2[1] + m1[3]*m2[3]    
    [a, b, c, d]

window.matrix = [1,0,0,1]
window.tempmatrix = [1,0,0,1]
window.updateMatrix = (multiplier) =>
    @count += 1
    @matrix = @multiply(multiplier, @matrix)
    @hideTempImage()
    # @tempUpdateMatrix(multiplier)
    if @are_matrices_equal(@matrix, @winning_matrix)
        @announce_result()

window.tempUpdateMatrix = (multiplier) =>
    @tempmatrix = @multiply(multiplier, @matrix)
    # @tempmatrix = multiplier
    @mathbox.select("#temp_image").set('visible', true)
    @mathbox.select("#real_image").set('visible', false)

window.hideTempImage = () =>
    @mathbox.select("#temp_image").set('visible', false)
    @mathbox.select("#real_image").set('visible', true)

window.random_matrix = (word_length) ->
    generators = [@matrices['shear_left'],
                @matrices['shear_right'],
                @matrices['shear_up'],
                @matrices['shear_down'],
                @matrices['reflect_x_axis']]
    result = [1,0,0,1]
    for i in [1...word_length]
        idx = Math.floor((Math.random() * 5));
        result = @multiply(result, generators[idx])
        console.log result
    return result

window.startGame = (challenge) ->
    @count = 0
    @matrix = challenge.starting_matrix
    if @matrix == 'random'
        @matrix = @random_matrix(10)
    console.log @matrix
    @winning_matrix = challenge.winning_matrix
    @min_count = challenge.min_count
    $("#challenge_inst").html(challenge.message)
    $("#challenge_div").show()
    $("#picker_div").hide()
    $("#new_challenge_div").show()
    $("#button-table").find("tr").hide()
    for id in challenge.transformations
        $("#"+id).show()
    # $("#button-table tbody").children("tr").each(() -> 
    #     console.log this
    #     console.log challenge.transformations
    #     if this.attr('id') in challenge.transformations
    #         this.show()
    #     else
    #         this.hide()
    # )
    # console.log $("#button-table tbody")
    # console.log $("#button-table tbody").children("tr")

window.challenge_list_setup = () ->
    $("#picker_div").show()
    $("#challenge_div").hide()
    $("#new_challenge_div").hide()
    $("#result_div").hide()

window.announce_result = () ->
    $("#count").html("#{@count}")
    if @min_count == 'none'
        $("#optimal").hide()
        $("#non-optimal").hide() 
    else if @count > @min_count
        $("#optimal").hide()
        $("#non-optimal").show()
    else
        $("#non-optimal").hide()
        $("#optimal").show()
    $("#challenge_div").hide()
    $("#result_div").show()


window.matrices = {
        'h_scale_2': [2,0,0,1],
        'h_scale_half': [0.5,0,0,1],
        'scale_2': [2, 0, 0, 2],
        'scale_half' : [0.5, 0, 0, 0.5],
        'shear_left' : [1, -1, 0, 1],
        'shear_right' : [1, 1, 0, 1],
        'shear_up' : [1, 0, 1, 1],
        'shear_down' : [1, 0, -1, 1]
        'reflect_x_axis' : [1, 0, 0, -1]
        'rotate_45cc' : [1/Math.sqrt(2), -1/Math.sqrt(2),1/Math.sqrt(2),1/Math.sqrt(2)]
        'rotate_45c' : [1/Math.sqrt(2), 1/Math.sqrt(2),-1/Math.sqrt(2),1/Math.sqrt(2)]
    }  

window.demo = new Demo2D {
    preload:
        image: 'img/' + (urlParams.pic ? "buzz.jpg")
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
            id: 'real_image'
            color:  'white'
            points: '<'
            map:    '<<'
            fill:   true
            zOrder: 0

    clipCube.clipped
        .transform {},
            matrix: () -> [window.tempmatrix[0], window.tempmatrix[1], 0, 0, window.tempmatrix[2], window.tempmatrix[3], 0, 0,
                           0, 0, 1, 0, 0, 0, 0, 1]
        .image image: @image
        .matrix
            width:    2
            height:   2
            channels: 2
            data:     [[[-10, -10], [10, -10]],
                       [[-10,  10], [10,  10]]]
        .surface
            id: 'temp_image'
            color:  'white'
            opacity: 0.5
            points: '<'
            map:    '<<'
            fill:   true
            zOrder: 0
            visible: false


    ##################################################
    # captions
    @caption '''
    <div id="picker_div">
    <p id="pick_inst"> Pick a challenge! </p>
    <hr>
    <ul id="challenge_list">
    </ul>
    </div>
    <div id="challenge_div">
    <p id="challenge_inst"> </p>
    <hr>
    <table id="button-table">
        <tr id="h-shears">
            <td><button type="button" id="shear_left">Shear left</button></td>
            <td><button type="button" id="shear_right">Shear right</button></td>
        </tr>
        <tr id="v-shears">
            <td><button type="button" id="shear_up">Shear up</button></td>
            <td><button type="button" id="shear_down">Shear down</button></td>
        </tr>
        <tr id="rotation">
            <td><button type="button" id="rotate_45cc">Rotate left by 45&deg;</button></td>
            <td><button type="button" id="rotate_45c">Rotate right by 45&deg;</button></td>
        </tr>
        <tr id="scale">
            <td><button type="button" id="scale_2">Scale by 2</button></td>
            <td><button type="button" id="scale_half">Scale by 1/2</button></td>
        </tr>
        <tr id="h_scale">
            <td><button type="button" id="h_scale_2">Scale by 2 horizontally</button></td>
            <td><button type="button" id="h_scale_half">Scale by 1/2 horizontally</button></td>
        </tr>
        <tr id="reflect">
            <td><button type="button" id="reflect_x_axis">Reflect about the x-axis</button></td>
        </tr>
    </table>
    </div>
    <div id="result_div">
        <p>Congratulations, you completed the challenge in <span id="count"></span> steps!</p>
        <p id="non-optimal">That's more than the optimal. Try again!</p>
        <p id="optimal" style="color:green">That's the optimal number of moves!</p>
    </div>
    <div id="new_challenge_div">
        <hr>
        <button id="new-challenge-btn">Pick another challenge</button>
    </div>
             '''



    challenges = [{
        name: "Zoom",
        message: "Transform the figure on the right to the one on the left",
        starting_matrix: [0,0.25,-0.25,0],
        winning_matrix: [1, 0, 0, 1],
        transformations: ["rotation", "scale"],
        min_count: 4
    }, {
        name: "Reflect",
        message: "Transform the figure on the right to the one on the left",
        starting_matrix: [0,1,1,0],
        winning_matrix: [1, 0, 0, 1],
        transformations: ["rotation", "reflect"],
        min_count: 3
    },{
        name: "Scale",
        message: "Transform the figure on the right to the one on the left",
        starting_matrix: [1,0,0,0.25],
        winning_matrix: [1, 0, 0, 1],
        transformations: ["rotation", "h_scale"],
        min_count: 6
    },
    {
        name: "Unwind",
        message : 'Transform the distorted figure back to the original figure.',
        starting_matrix : [5, 4, 6, 5],
        winning_matrix : [1, 0, 0, 1],
        transformations : ["h-shears", "v-shears"],
        min_count : 6
    }, {
        name: "Rotate",
        message : 'Rotate the figure back to its original position.',
        starting_matrix : [0, -1, 1, 0],
        winning_matrix : [1, 0, 0, 1],
        transformations : ["h-shears", "v-shears"],
        min_count : 3
    }, {
        name: "Random",
        message: "Transform the figure on the right to the one on the left",
        starting_matrix: 'random',
        winning_matrix: [1, 0, 0, 1],
        transformations: ["rotation", "h-shears", "v-shears", "reflect"],
        min_count: 'none'        
    }]

    for i in [1...challenges.length+1]
        (() ->
            ii = i
            ch = challenges[ii-1]
            $li = $("<li>")
            $ch = $("<button>", {id: "ch#{ii}"})
            $ch.click(() -> window.startGame(ch))
            $ch.html("Challenge #{ii}: " + ch.name)
            $li.append($ch)
            $("#challenge_list").append($li)
        )()

    for id, matrix of window.matrices
        (() -> 
            id2 = id
            $btn = $("#"+id2)
            $btn.click(() -> window.updateMatrix(window.matrices[id2]))
            $btn.mouseover(() -> window.tempUpdateMatrix(window.matrices[id2]))
            $btn.mouseleave(() -> window.hideTempImage())
        )()

    $("#new-challenge-btn").click(() -> window.challenge_list_setup())

    window.challenge_list_setup()

        # <tr>
        #     <td><button type="button" id="scale_2">Scale horizontally by 2</button></td>
        #     <td><button type="button" id="scale_half">Scale horizontally by 1/2</button></td>
        # </tr>

        # <tr>
        #     <td><button type="button" id="reflect_x_axis">Reflect about the x-axis</button></td>
        #     <td><button type="button">Reflect about the y-axis</button></td>
        # </tr>
