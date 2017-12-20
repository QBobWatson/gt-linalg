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
tB4inv = new THREE.Matrix4().getInverse tB4
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


##################################################
# Dynamics
dynamicsMode = urlParams.dynamics ? 'off'

# Lots of different ways to interpolate.  Run in a shader for speed.

shaderCode = '''
#define M_PI 3.1415926535897932384626433832795

uniform float pos;
uniform mat4 start;
uniform mat4 end;
uniform float scale;
uniform int which;

vec4 animateLinear(vec4 xyzw) {
    vec4 endpos = end * xyzw;
    xyzw = start * xyzw;
    return pos * endpos + (1.0 - pos) * xyzw;
}

vec4 animateScaleSteps(vec4 xyzw) {
    vec4 startpos, endpos;
    float pos2;
    if(pos < 0.5) {
        startpos = start * xyzw;
        endpos = startpos;
        endpos.x *= end[0][0] / start[0][0];
        pos2 = pos * 2.0;
    } else {
        startpos = start * xyzw;
        startpos.x *= end[0][0] / start[0][0];
        endpos = end * xyzw;
        pos2 = (pos - 0.5) * 2.0;
    }
    return pos2 * endpos + (1.0 - pos2) * startpos;
}

vec4 animateExponential(vec4 xyzw) {
    vec4 endpos = end * xyzw;
    xyzw = start * xyzw;
    if(pos == 0.0)
        return xyzw;
    if(pos == 1.0)
        return endpos;
    // pos is in (0, 1)
    return pow(abs(xyzw), vec4(1.0 - pos)) * pow(abs(endpos), vec4(pos)) * sign(xyzw);
}

vec4 rotate(vec4 xyzw, float pos2) {
    float startangle = atan(start[0][1], start[0][0]);
    float endangle   = atan(end[0][1],   end[0][0]);
    // Go around the short way
    if(abs(endangle - startangle) > M_PI) {
        if(endangle > startangle)
            endangle -= 2.0*M_PI;
        else
            endangle += 2.0*M_PI;
    }
    endangle -= startangle;
    float angle = pos2 * endangle;
    float c = cos(angle);
    float s = sin(angle);
    return vec4(xyzw.x * c - xyzw.y * s, xyzw.x * s + xyzw.y * c, xyzw.z, xyzw.w);
}

vec4 animateRotation(vec4 xyzw) {
    if(pos == 0.0)
        return start * xyzw;
    return rotate(start * xyzw, pos);
}

vec4 animateRotateScale(vec4 xyzw) {
    if(pos == 0.0)
        return start * xyzw;
    if(pos < 0.5)
        return rotate(start * xyzw, pos * 2.0);
    float pos2 = (pos - 0.5) * 2.0;
    xyzw = end * xyzw;
    xyzw.xy *= ((1.0 - pos2) / scale + pos2 * 1.0);
    return xyzw;
}

vec4 animateSpiral(vec4 xyzw) {
    if(pos == 0.0)
        return start * xyzw;
    xyzw = rotate(start * xyzw, pos);
    xyzw.xy *= ((1.0 - pos) * 1.0 + pos * scale);
    return xyzw;
}

vec4 animate(vec4 xyzw, inout vec4 stpq) {
    if(which == 0)
        return animateLinear(xyzw);
    if(which == 1)
        return animateScaleSteps(xyzw);
    if(which == 2)
        return animateExponential(xyzw);
    if(which == 3)
        return animateRotation(xyzw);
    if(which == 4)
        return animateRotateScale(xyzw);
    if(which == 5)
        return animateSpiral(xyzw);
}
'''

shaders =
    linear:      0
    scaleSteps:  1
    exponential: 2
    rotation:    3
    rotateScale: 4
    spiral:      5


# Special-purpose animations run on the gpu
class ShaderAnimation extends Animation
    constructor: (opts) ->
        opts ?= {}
        @startTime = null
        @duration = opts.duration ? 1
        @startMat = new THREE.Matrix4()
        @endMat = new THREE.Matrix4()
        super
    install: (view, shader) =>
        @uniforms =
            start: { type: 'm4', value: @startMat }
            end:   { type: 'm4', value: @endMat }
            scale: { type: 'f',  value: 1 }
            which: { type: 'i',  value: shader }
        @animShader = view
            .shader { code: shaderCode, uniforms: @uniforms }, { pos: @pos }
        @vertex = view
            .vertex
                shader: @animShader
                pass:   'data'
    pos: (t) =>
        # Animation position, between 0 and 1
        if not @running
            return 0
        if @startTime == null
            # Just started
            @startTime = t
            return 0
        pos = (t - @startTime) / @duration
        if pos >= 1
            @done()
            return 0
        return pos
    setShader: (shader) =>
        @uniforms.which.value = shader
    resetMat: () =>
        @startMat.identity()
        @endMat.identity()
    updateMat: (newMat) =>
        @endMat.multiply newMat
    stop: () =>
        @startMat.copy @endMat
        @uniforms.scale.value = 1
        @startTime = null
        super
    done: () =>
        @startMat.copy @endMat
        @uniforms.scale.value = 1
        @startTime = null
        super


class Dynamics
    constructor: (@range) ->
        # Vectors: array of numVecs x numVecs
        @numVecs = urlParams.get 'numvecs', 'int', 500*5*5
        @vecs = ([0, 0, 0] for [0...@numVecs])
        col = () -> Math.random() * .5 + .5
        @colors = ([col(), col(), col(), 1] for [0...@numVecs])
        @makeVecs()

        # For the caption
        @captionColors = ([col(), col(), col(), 1] for [0...15])

        # installed mathbox elements
        @points      = []
        @pointsData  = []
        @refDataElts = []
        @refLines    = []
        @animations  = []

        @tmpVec = new THREE.Vector3()
        # TODO
        @reference = null # = urlParams.reference ? null
        @refData = null

        # decide if this is a rotation-scaling matrix, a diagonalizable matrix,
        # or none of the above
        if B[0][0] == B[1][1] and B[1][0] == -B[0][1]
            @matType = 'rot-scale'
        else if B[0][1] == 0 and B[1][0] == 0
            @matType = 'diag'
        else
            @matType = 'none'
        @mat = tB4
        @matInv = tB4inv

        # gui
        gui ?= new dat.GUI
        gui.closed = urlParams.closed?
        @iteration = 0
        folder = gui.addFolder("Dynamics")
        folder.open() if dynamicsMode == 'on'
        params.Enable = dynamicsMode == 'on'
        params.Reset = @reset
        params.Iterate = () => @iterate(1)
        params.UnIterate = () => @iterate(-1)

        switch @matType
            when 'rot-scale'
                params.Motion = 'rotation'
                possible = ['linear', 'rotateScale']
                det = B[0][0]*B[1][1] + B[0][1] * B[0][1]
                if det == 1
                    possible[1] = 'rotation'
                else
                    params.Motion = 'spiral'
                    possible.push 'spiral'
            when 'diag'
                if B[0][0] == 1 or B[1][1] == 1
                    params.Motion = 'linear'
                    possible = false
                else if B[0][0] < 0 or B[1][1] < 0
                    params.Motion = 'scaleSteps'
                    possible = ['linear', 'scaleSteps']
                else
                    params.Motion = 'exponential'
                    possible = ['linear', 'scaleSteps', 'exponential']
            else
                params.Motion = 'linear'
                possible = false

        folder.add(params, 'Enable').onFinishChange (val) ->
            dynamicsMode = if val then 'on' else 'off'
            resetMode()
            updateCaption()
        if possible
            folder.add(params, 'Motion', possible).onFinishChange (val) =>
                for anim in @animations
                    anim.setShader shaders[val]
        folder.add(params, 'Reset')
        folder.add(params, 'Iterate')
        folder.add(params, 'UnIterate')

    install: (view) =>
        animation = new ShaderAnimation()
        animation.install view, shaders[params.Motion]
        @animations.push animation

        colors = view
            .array
                channels: 4
                width:    @numVecs
                data:     @colors
                live:     false
        pointsData = animation.vertex
            .array
                channels: 3
                width:    @numVecs
                data:     @vecs
                live:     false
        points = pointsData
            .point
                colors:   colors
                color:    "white"
                size:     10
                zIndex:   3
        @pointsData.push pointsData
        @points.push points

        # TODO
        if @reference
            refData = animation.vertex
                .array
                    channels: 3
                    width:    refData.length
                    data:     refData
                    items:    referenceItems
                    live:     true
            refLines = view
                .line
                    color:   "rgb(0, 80, 255)"
                    width:   4
                    opacity: .75
                    zBias:   2
                    closed:  true
            @refDataElts.push refData
            @refLines.push refLines

    show: () =>
        for elt in @points
            elt.set 'visible', true
        if @reference
            for elt in @refLines
                elt.set 'visible', true

    hide: () =>
        for elt in @points
            elt.set 'visible', false
        if @reference
            for elt in @refLines
                elt.set 'visible', false

    makeVecs: () =>
        r = 5*@range
        for i in [0...@numVecs]
            @vecs[i][0] = Math.random() * 2 * r - r
            @vecs[i][1] = Math.random() * 2 * r - r

    reset: () =>
        return unless params.Enable
        for anim in @animations
            anim.resetMat()
        @makeVecs()
        @makeRef()
        for demo in [demo1, demo2]
            demo.stopAll()
        @iteration = 0
        resetMode()
        updateCaption()

    iterate: (direction) =>
        iter = @iteration + direction
        mat = if direction > 0 then @mat else @matInv
        for demo in [demo1, demo2]
            demo.stopAll()

        # Animate
        for demo, i in [demo1, demo2]
            @animations[i].updateMat mat
            if @matType == 'rot-scale'
                me = mat.elements
                @animations[i].uniforms.scale.value = Math.sqrt(me[0]*me[0]+me[1]*me[1])
            demo.animate animation: @animations[i]
            # TODO
            if @reference
                demo.animate demo.refDataElts,
                    ease: 'linear'
                    script:
                        0:   props: data: refData
                        .75: props: data: newData

        document.getElementById('mult-factor').innerText =
            'Vectors multiplied by'
        katex.render "#{BName}^{#{iter}} " +
            "\\quad\\text{resp.}\\quad #{AName}^{#{iter}}",
            document.getElementById('An-here')

        @iteration = iter

    makeRef: () =>
        switch @reference
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

dynamics = null

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
    # Dynamics
    if dynamicsMode != 'disabled'
        dynamics = new Dynamics(@range)
        dynamics.install view

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
            for col in dynamics.captionColors
                hexColor = "#" + new THREE.Color(col[0], col[1], col[2]).getHexString()
                str += """
                    <span style="color:#{hexColor}">&#x25cf;</span>
                """
            str += '</p>'
            document.getElementsByClassName('overlay-text')[0].innerHTML = str + '''
                <p id="mult-factor">Original vectors</p>
                <p class="matrix-powers">
                    <span id="An-here"></span>
                </p>
                '''
            dynamics.show()
            for demo in [demo1, demo2]
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
            if dynamics
                dynamics.hide()
                for demo in [demo1, demo2]
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
    # Dynamics
    if dynamics
        dynamics.install @transformed

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
