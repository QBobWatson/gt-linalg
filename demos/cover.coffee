# TODO:
#  * Speed based on deltaAngle?

######################################################################
# Shaders

easeCode = \
    """
    #define M_PI 3.1415926535897932384626433832795

    float easeInOutSine(float pos) {
        return 0.5 * (1.0 - cos(M_PI * pos));
    }
    """

rotateShader = easeCode + \
    """
    uniform float deltaAngle;
    uniform float scale;
    uniform float time;

    vec4 getTimingsSample(vec4 xyzw);
    vec4 getPointSample(vec4 xyzw);

    vec4 rotate(vec4 xyzw) {
        vec4 timings = getTimingsSample(xyzw);
        vec4 point = getPointSample(xyzw);
        float start = timings.x;
        float duration = timings.y;
        if(time < start) {
            return vec4(point.xy, 0.0, 0.0);
        }
        float pos = min((time - start) / duration, 1.0);
        pos = easeInOutSine(pos);
        float c = cos(deltaAngle * pos);
        float s = sin(deltaAngle * pos);
        point.xy = vec2(point.x * c - point.y * s, point.x * s + point.y * c)
            * pow(scale, pos);
        return vec4(point.xy, 0.0, 0.0);
    }
    """

diagShader = easeCode + \
    """
    uniform float scaleX;
    uniform float scaleY;
    uniform float time;

    vec4 getTimingsSample(vec4 xyzw);
    vec4 getPointSample(vec4 xyzw);

    vec4 rotate(vec4 xyzw) {
        vec4 timings = getTimingsSample(xyzw);
        vec4 point = getPointSample(xyzw);
        float start = timings.x;
        float duration = timings.y;
        if(time < start) {
            return vec4(point.xy, 0.0, 0.0);
        }
        float pos = min((time - start) / duration, 1.0);
        pos = easeInOutSine(pos);
        point.x *= pow(scaleX, pos);
        point.y *= pow(scaleY, pos);
        return vec4(point.xy, 0.0, 0.0);
    }
    """

colorShader = easeCode + \
    """
    uniform float time;

    vec4 getTimingsSample(vec4 xyzw);
    vec4 getColorSample(vec4 xyzw);

    vec3 hsv2rgb(vec3 c) {
      vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
      vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
      return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
    }

    #define TRANSITION 0.2

    vec4 getColor(vec4 xyzw) {
        vec4 color = getColorSample(xyzw);
        vec4 timings = getTimingsSample(xyzw);
        float start = timings.x;
        float duration = timings.y;
        float pos, ease;
        pos = max(0.0, min(1.0, (time - start) / duration));
        if(pos < TRANSITION) {
            ease = easeInOutSine(pos / TRANSITION);
            color.w *= ease * 0.6 + 0.4;
            color.y *= ease * 0.6 + 0.4;
        }
        else if(pos > 1.0 - TRANSITION) {
            ease = easeInOutSine((1.0 - pos) / TRANSITION);
            color.w *= ease * 0.6 + 0.4;
            color.y *= ease * 0.6 + 0.4;
        }
        return vec4(hsv2rgb(color.xyz), color.w);
    }
    """

sizeShader = easeCode + \
    """
    uniform float time;

    vec4 getTimingsSample(vec4 xyzw);

    #define TRANSITION 0.2
    #define SMALL 5.0
    #define BIG 7.0

    vec4 getSize(vec4 xyzw) {
        vec4 timings = getTimingsSample(xyzw);
        float start = timings.x;
        float duration = timings.y;
        float pos, ease, size = BIG;
        pos = max(0.0, min(1.0, (time - start) / duration));
        if(pos < TRANSITION) {
            ease = easeInOutSine(pos / TRANSITION);
            size = SMALL * (1.0-ease) + BIG * ease;
        }
        else if(pos > 1.0 - TRANSITION) {
            ease = easeInOutSine((1.0 - pos) / TRANSITION);
            size = SMALL * (1.0-ease) + BIG * ease;
        }
        return vec4(size, 0.0, 0.0, 0.0);
    }
    """


######################################################################
# Utility functions

HSVtoRGB = (h, s, v) ->
    i = Math.floor(h * 6);
    f = h * 6 - i;
    p = v * (1 - s);
    q = v * (1 - f * s);
    t = v * (1 - (1 - f) * s);
    switch i % 6
        when 0 then [v, t, p]
        when 1 then [q, v, p]
        when 2 then [p, v, t]
        when 3 then [p, q, v]
        when 4 then [t, p, v]
        when 5 then [v, p, q]

expLerp = (a, b) -> (t) -> Math.pow(b, t) * Math.pow(a, 1-t)
linLerp = (a, b) -> (t) -> b*t + a*(1-t)
polyLerp = (a, b, n) -> (t) -> Math.pow(t, n) * (b-a) + a
discLerp = (a, b, n) -> (t) -> Math.floor(Math.random() * (n+1)) * (b-a)/n + a
randElt = (l) -> l[Math.floor(Math.random() * l.length)]
randSign = () -> randElt [-1, 1]

mult22 = (m, v) -> [m[0]*v[0]+m[1]*v[1], m[2]*v[0]+m[3]*v[1]]
inv22 = (m) ->
    det = m[0]*m[3] - m[1]*m[2]
    [m[3]/det, -m[1]/det, -m[2]/det, m[0]/det]


######################################################################
# MathBox boilerplate

ortho = 1e5

myMathBox = (options) ->
  three = THREE.Bootstrap options
  if !three.fallback
    three.install 'time'      if !three.Time
    # Get rid of splash scree
    three.install ['mathbox'] if !three.MathBox
  three.mathbox ? three

# globals
mathbox = null
view0 = null

setupMathbox = () ->
    mathbox = window.mathbox = myMathBox
        plugins: ['core']
        mathbox:
            inspect: false
            splash: false
        camera:
            near:    ortho/4
            far:     ortho*4
        element: document.getElementById "mathbox"
    if mathbox.fallback
        throw "WebGL not supported"

    three = window.three = mathbox.three
    three.renderer.setClearColor new THREE.Color(0xffffff), 1.0
    mathbox.camera
        proxy:    false
        position: [0, 0, ortho]
        lookAt:   [0, 0, 0]
        up:       [1, 0, 0]
        fov:      Math.atan(1/ortho) * 360 / π
    mathbox.set 'focus', ortho/1.5

    view0 = mathbox.cartesian
        range: [[-1, 1], [-1, 1]]
        scale: [1, 1]


######################################################################
# Global variables

# Current demo
current = null

numPointsRow = 50
numPointsCol = 100

numPoints = numPointsRow * numPointsCol - 1
duration = 3.0
delay = (first) ->
    scale = numPoints / 1000
    pos = Math.random() * scale
    if first
        pos - 0.5 * scale
    else
        pos

curTime = 0
mode = 'spiralIn'
points = [[0, 0, 0, 0]]
stepMat = []
# Per-point animation timings
timings = [[-10, 1e15]]


######################################################################
# Colors

colors = [[0, 0, 0, 1]].concat([Math.random(), 1, 0.7, 1] for [0...numPoints])


######################################################################
# Change of basis

view = null
farthest  = 0
farthestX = 0
farthestY = 0

# Choose random (but not too wonky) coordinate system
makeCoordMat = () ->
    v1 = [0, 0]
    v2 = [0, 0]

    # Vector length between 1/2 and 2
    distribution = linLerp 0.5, 2
    len = distribution Math.random()
    θ = Math.random() * 2 * π
    v1[0] = Math.cos(θ) * len
    v1[1] = Math.sin(θ) * len
    # Angle between vectors between 45 and 135 degrees
    θoff = randSign() * linLerp(π/4, 3*π/4)(Math.random())
    len = distribution Math.random()
    v2[0] = Math.cos(θ + θoff) * len
    v2[1] = Math.sin(θ + θoff) * len

    coordMat = [v1[0], v2[0], v1[1], v2[1]]
    # coordMat = [1,0,0,1]
    # Find the farthest corner in the un-transformed coord system
    coordMatInv = inv22 coordMat
    corners = [[1, 1], [-1, 1]].map (c) -> mult22 coordMatInv, c
    farthest = Math.max.apply null, corners.map (c) -> c[0]*c[0] + c[1]*c[1]
    farthest = Math.sqrt farthest
    farthestX = Math.max.apply null, corners.map (c) -> Math.abs c[0]
    farthestY = Math.max.apply null, corners.map (c) -> Math.abs c[1]

    transformMat = [coordMat[0], coordMat[1], 0, 0,
                    coordMat[2], coordMat[3], 0, 0,
                    0, 0, 1, 0,
                    0, 0, 0, 1]
    if view
        view.set 'matrix', transformMat
    else
        view = view0.transform matrix: transformMat


######################################################################
# Axes

makeAxes = () ->
    for i in [1, 2]
        view.axis
            axis:    i
            end:     false
            width:   3
            size:    5
            zBias:   -1
            depth:   1
            color:   "black"
            opacity: 0.3
            range:   [-10,10]


######################################################################
# Dynamics base class

initialized = false
shaderElt = null
linesElt = null
linesDataElt = null

class Dynamics
    install: () =>
        for i in [1..numPoints]
            @newPoint i, true
            timings[i][0] = curTime + delay(true)

        if initialized
            shaderElt.set @shaderParams()
            linesDataElt.set @linesParams()
            linesElt.set "closed", @refClosed()

        else
            view0
                .matrix
                    id:       "timings"
                    channels: 2
                    width:    numPointsRow
                    height:   numPointsCol
                    data:     timings
                    live:     true

            pointsElt = view
                .matrix
                    id:       "points-orig"
                    channels: 4
                    width:    numPointsRow
                    height:   numPointsCol
                    data:     points
            shaderElt = pointsElt.shader @shaderParams(), time: (t) -> curTime = t
            shaderElt.resample id: "points"

            # Coloring pipeline
            view0
                .matrix
                    channels: 4
                    width:    numPointsRow
                    height:   numPointsCol
                    data:     colors
                    live:     false
                .shader
                    code:    colorShader
                    sources: ["#timings"]
                ,
                    time: (t) -> t
                .resample id: "colors"

            # Size pipeline
            view0
                .shader
                    code: sizeShader
                ,
                    time: (t) -> t
                .resample
                    source: "#timings"
                    id:     "sizes"

            view
                .point
                    points: "#points"
                    color:  "white"
                    colors: "#colors"
                    size:   1
                    sizes:  "#sizes"
                    zBias:  1
                    zIndex: 2

            # Reference lines
            linesDataElt = view.matrix @linesParams()
            linesElt = view.line
                color:    "rgb(80, 120, 255)"
                width:    2
                opacity:  0.4
                zBias:    0
                zIndex:   1
                closed:   @refClosed()

            initialized = true

    linesParams: () =>
        @reference = @makeReference()
        channels: 2
        height:   @reference.length
        width:    @reference[0].length
        items:    @reference[0][0].length
        data:     @reference
        live:     false

    refClosed: () => false


######################################################################
# Complex eigenvalues

class Complex extends Dynamics
    constructor: () ->
        super
        @deltaAngle = randSign() * linLerp(π/6, 5*π/6)(Math.random())
        @scale = @getScale()

        stepMat = [Math.cos(@deltaAngle) * @scale, -Math.sin(@deltaAngle) * @scale,
                   Math.sin(@deltaAngle) * @scale,  Math.cos(@deltaAngle) * @scale]

        @makeDistributions()

    newPoint: (i, first) =>
        distribution = if first then @origDist else @newDist
        r = distribution Math.random()
        θ = Math.random() * 2 * π
        timings[i] = [0, duration]
        points[i] = [Math.cos(θ) * r, Math.sin(θ) * r, 0, 0]

    shaderParams: () =>
        code: rotateShader,
        sources: ["#timings"]
        uniforms:
            deltaAngle: { type: 'f', value: @deltaAngle }
            scale:      { type: 'f', value: @scale }


class Circle extends Complex
    getScale: () => 1

    makeDistributions: () =>
        @newDist = @origDist = polyLerp 0.01, farthest, 1/2

    makeReference: () =>
        ret = []
        for t in [0...2*π] by π/72
            row = []
            for s in [farthest/10...farthest] by farthest/10
                row.push [s * Math.cos(t), s * Math.sin(t)]
            ret.push row
        [ret]

    updatePoint: (i) => points[i]

    refClosed: () => true


class Spiral extends Complex
    makeReference: () =>
        ret = []
        # Have to put this in a matrix to avoid texture size limits
        for i in [-10...10]
            row = []
            for t in [0..72]
                u = (i + t/72) * π
                s = Math.pow(@scale, u / @deltaAngle)
                items = []
                for j in [0...2*π] by π/4
                    items.push [s * Math.cos(u+j), s * Math.sin(u+j)]
                row.push items
            ret.push row
        ret


class SpiralIn extends Spiral
    getScale: () -> linLerp(0.3, 0.8)(Math.random())

    makeDistributions: () =>
        @close  = 0.01
        @medium = farthest
        @far    = farthest / @scale

        switch randElt ['cont', 'disc']
            when 'cont'
                @origDist = expLerp @close, @far
                @newDist = expLerp @medium, @far
            when 'disc'
                distances = []
                distance = @far
                while distance > @close
                    distances.push distance
                    distance *= @scale
                @origDist = (t) -> distances[Math.floor(t * distances.length)]
                @newDist = (t) => @far

    updatePoint: (i) =>
        point = points[i]
        if point[0]*point[0] + point[1]*point[1] < @close*@close
            @newPoint i
        points[i]


class SpiralOut extends Spiral
    getScale: () => linLerp(1/0.8, 1/0.3)(Math.random())

    makeDistributions: () =>
        @veryClose = 0.01 / @scale
        @close     = 0.01
        @medium    = farthest

        switch randElt ['cont', 'disc']
            when 'cont'
                @origDist = expLerp @veryClose, @medium
                @newDist = expLerp @veryClose, @close
            when 'disc'
                distances = []
                distance = @veryClose
                while distance < @medium
                    distances.push distance
                    distance *= @scale
                @origDist = (t) -> distances[Math.floor(t * distances.length)]
                @newDist = (t) => @veryClose

    updatePoint: (i) =>
        point = points[i]
        if point[0]*point[0] + point[1]*point[1] > @medium * @medium
            @newPoint i
        points[i]


######################################################################
# Real eigenvalues, diagonalizable

class Diagonalizable extends Dynamics
    constructor: () ->
        super
        @makeScales()
        stepMat = [@scaleX, 0, 0, @scaleY]

    shaderParams: () =>
        code: diagShader,
        sources: ["#timings"]
        uniforms:
            scaleX: { type: 'f', value: @scaleX }
            scaleY: { type: 'f', value: @scaleY }


class Hyperbolas extends Diagonalizable
    makeScales: () =>
        @scaleX = linLerp(0.3, 0.8)(Math.random())
        @scaleY = linLerp(1/0.8, 1/0.3)(Math.random())
        # Implicit equations for paths are x^{log(scaleY)}y^{-log(scaleX)} = r
        @logScaleX = Math.log @scaleX
        @logScaleY = Math.log @scaleY
        # @close means (@close, @close) is the closest point to the origin
        @close = 0.05
        @closeR = Math.pow(@close, @logScaleY - @logScaleX)
        @farR = Math.pow(farthestX, @logScaleY) * Math.pow(farthestY, -@logScaleX)
        @lerpR = linLerp(@closeR, @farR)

    newPoint: (i, first) =>
        # First choose r uniformly between @closeR and @farR
        r = @lerpR Math.random()
        if first
            # x value on that hyperbola at y = farthestY
            closeX = Math.pow(r * Math.pow(farthestY, @logScaleX), 1/@logScaleY)
            # Choose x value exponentially along that hyperbola
            x = expLerp(closeX, farthestX / @scaleX)(Math.random())
        else
            # As above, but out of sight
            x = expLerp(farthestX, farthestX / @scaleX)(Math.random())
        # Corresponding y
        y = Math.pow(1/r * Math.pow(x, @logScaleY), 1/@logScaleX)
        timings[i] = [0, duration]
        points[i] = [randSign() * x, randSign() * y, 0, 0]

    makeReference: () =>
        ret = []
        for t in [0...20]
            r = @lerpR t/20
            closeX = Math.pow(r * Math.pow(farthestY, @logScaleX), 1/@logScaleY)
            lerp = expLerp closeX, farthestX
            row = []
            for i in [0..100]
                x = lerp i/100
                y = Math.pow(1/r * Math.pow(x, @logScaleY), 1/@logScaleX)
                row.push [[x,  y], [-x,  y], [ x, -y], [-x, -y]]
            ret.push row
        ret

    updatePoint: (i) =>
        point = points[i]
        if Math.abs(point[1]) > farthestY
            @newPoint i
        points[i]


class AttractRepel extends Diagonalizable
    makeScales: () =>
        # Implicit equations for paths are x^{log(scaleY)}y^{-log(scaleX)} = r
        @logScaleX = Math.log @scaleX
        @logScaleY = Math.log @scaleY
        # Choose points on paths between the ones going through
        # (.95,.05) and (.05,.95)
        offset = 0.05
        # Interpolate r by choosing the path that goes through a random point on
        # the line y = 1-x
        @lerpR = (t) ->
            t = linLerp(offset, 1-offset)(t)
            Math.pow(t, @logScaleY) * Math.pow(1-t, -@logScaleX)
        # Assume this is >1
        a = @logScaleY/@logScaleX
        # Points expand in/out in "wave fronts" of the form x^a + y = s
        # Acting (x,y) by stepMat multiplies this equation by scaleY
        # Last wave front is through (farthestX, farthestY)
        @sMin = 0.01
        @sMax = Math.pow(farthestX, a) + farthestY
        # The y-value of the point of intersection of the curves
        # x^a+y=s and x^lsy y^{-lsx} = r
        @yValAt = (r, s) -> s / (1 + Math.pow(r, 1/@logScaleX))
        # x as a function of y on the curve blah=r
        @xOfY = (y, r) -> Math.pow(r * Math.pow(y, @logScaleX), 1/@logScaleY)

    makeReference: () =>
        ret = []
        for i in [0...15]
            r = @lerpR i/15
            lerp = expLerp 0.01, farthestY
            row = []
            for i in [0..100]
                y = lerp i/100
                x = @xOfY y, r
                row.push [[x,  y], [-x,  y], [ x, -y], [-x, -y]]
            ret.push row
        ret


class Attract extends AttractRepel
    makeScales: () =>
        # scaleX >= scaleY implies logScaleY/logScaleX > 1
        @scaleX = linLerp(0.3, 0.9)(Math.random())
        @scaleY = linLerp(0.3, @scaleX)(Math.random())
        super

    newPoint: (i, first) =>
        # First choose r
        r = @lerpR Math.random()
        farY = @yValAt r, @sMax / @scaleY
        if first
            closeY = @yValAt r, @sMin
        else
            closeY = @yValAt r, @sMax
        y = expLerp(closeY, farY)(Math.random())
        x = @xOfY y, r
        timings[i] = [0, duration]
        points[i] = [randSign() * x, randSign() * y, 0, 0]

    updatePoint: (i) =>
        point = points[i]
        if Math.abs(point[1]) < .01
            @newPoint i
        points[i]


class Repel extends AttractRepel
    makeScales: () =>
        # scaleX <= scaleY implies logScaleY/logScaleX > 1
        @scaleY = linLerp(1/0.9, 1/0.3)(Math.random())
        @scaleX = linLerp(1/0.9, @scaleY)(Math.random())
        super

    newPoint: (i, first) =>
        # First choose r
        r = @lerpR Math.random()
        closeY = @yValAt r, @sMin / @scaleY
        if first
            farY = @yValAt r, @sMax
        else
            farY = @yValAt r, @sMin
        y = expLerp(closeY, farY)(Math.random())
        x = @xOfY y, r
        timings[i] = [0, duration]
        points[i] = [randSign() * x, randSign() * y, 0, 0]

    updatePoint: (i) =>
        point = points[i]
        if Math.abs(point[0]) > farthestX or Math.abs(point[1]) > farthestY
            @newPoint i
        points[i]


class AttractRepelLine extends Diagonalizable
    makeScales: () =>
        @scaleX = 1
        @lerpX = linLerp -farthestX, farthestX

    newPoint: (i, first) =>
        x = @lerpX Math.random()
        y = (if first then @origLerpY else @newLerpY)(Math.random())
        timings[i] = [0, duration]
        points[i] = [x, randSign() * y, 0, 0]

    makeReference: () =>
        item1 = []
        item2 = []
        for i in [0...20]
            x = @lerpX (i+.5)/20
            item1.push [x, -farthestY]
            item2.push [x,  farthestY]
        [[item1, item2]]


class AttractLine extends AttractRepelLine
    makeScales: () =>
        super
        @scaleY = linLerp(0.3, 0.8)(Math.random())
        @origLerpY = expLerp 0.01, farthestY / @scaleY
        @newLerpY = expLerp farthestY, farthestY / @scaleY

    updatePoint: (i) =>
        point = points[i]
        if Math.abs(point[1]) < 0.01
            @newPoint i
        points[i]


class RepelLine extends AttractRepelLine
    makeScales: () =>
        super
        @scaleY = linLerp(1/0.8, 1/0.3)(Math.random())
        @origLerpY = expLerp 0.01 / @scaleY, farthestY
        @newLerpY = expLerp 0.01 / @scaleY, 0.01

    updatePoint: (i) =>
        point = points[i]
        if Math.abs(point[1]) > farthestY
            @newPoint i
        points[i]


######################################################################
# Entry point

types = [
    ["all",           null],
    ["ellipse",       Circle],
    ["spiral in",     SpiralIn],
    ["spiral out",    SpiralOut]
    ["hyperbolas",    Hyperbolas]
    ["attract point", Attract]
    ["repel point",   Repel]
    ["attract line",  AttractLine]
    ["repel line",    RepelLine]
]
typesList = (t[1] for t in types.slice(1))
select = null

reset = () ->
    makeCoordMat()
    if select
        type = types.filter((x) -> x[0] == select.value)[0][1]
    unless type
        type = randElt typesList
        # type = Repel
    current = window.current = new type()
    current.install()

window.doCover = startup = () ->
    setupMathbox()
    makeCoordMat()
    makeAxes()
    reset()

    setInterval () ->
        for point, i in points
            if i == 0  # Origin
                continue
            end = timings[i][0] + timings[i][1]
            if end < curTime
                # Reset point
                [point[0], point[1]] = mult22 stepMat, point
                point = current.updatePoint i
                # Reset timer
                timings[i][0] = curTime + delay()
        null
    , 100

makeControls = (elt) ->
    div = document.createElement "div"
    div.id = "cover-controls"
    button = document.createElement "button"
    button.innerText = "Go"
    button.onclick = reset
    select = document.createElement "select"
    for [key, val] in types
        option = document.createElement "option"
        option.innerText = key
        select.appendChild option
    div.appendChild select
    div.appendChild button
    elt.appendChild div

install = (elt) ->
    # Create containers
    div = document.createElement "div"
    div.id = "mathbox-container"
    div2 = document.createElement "div"
    div2.id = "mathbox"
    div.appendChild div2
    elt.appendChild div
    # Adjust width
    main = document.getElementsByClassName("main")[0]
    elt.style.width = main.clientWidth + "px"
    content = document.getElementById "content"
    elt.style.marginLeft = "-" + getComputedStyle(content, null).marginLeft
    # Add controls
    makeControls elt
    startup()

element = document.getElementById "cover"
if element
    install element

