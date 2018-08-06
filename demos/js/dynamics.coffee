
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

    vec4 getPointSample(vec4 xyzw);

    vec4 rotate(vec4 xyzw) {
        vec4 point = getPointSample(xyzw);
        float start = point.z;
        float duration = point.w;
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

    vec4 getPointSample(vec4 xyzw);

    vec4 rotate(vec4 xyzw) {
        vec4 point = getPointSample(xyzw);
        float start = point.z;
        float duration = point.w;
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

shearShader = easeCode + \
    """
    uniform float scale;
    uniform float translate;
    uniform float time;

    vec4 getPointSample(vec4 xyzw);

    vec4 shear(vec4 xyzw) {
        vec4 point = getPointSample(xyzw);
        float start = point.z;
        float duration = point.w;
        if(time < start) {
            return vec4(point.xy, 0.0, 0.0);
        }
        float pos = min((time - start) / duration, 1.0);
        pos = easeInOutSine(pos);
        float s = pow(scale, pos);
        point.x  = s * (point.x + translate * pos * point.y);
        point.y *= s;
        return vec4(point.xy, 0.0, 0.0);
    }
    """

colorShader = easeCode + \
    """
    uniform float time;

    vec4 getPointSample(vec4 xyzw);
    vec4 getColorSample(vec4 xyzw);

    vec3 hsv2rgb(vec3 c) {
      vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
      vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
      return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
    }

    #define TRANSITION 0.2

    vec4 getColor(vec4 xyzw) {
        vec4 color = getColorSample(xyzw);
        vec4 point = getPointSample(xyzw);
        float start = point.z;
        float duration = point.w;
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
    uniform float small;

    vec4 getPointSample(vec4 xyzw);

    #define TRANSITION 0.2
    #define BIG (small * 7.0 / 5.0)

    vec4 getSize(vec4 xyzw) {
        vec4 point = getPointSample(xyzw);
        float start = point.z;
        float duration = point.w;
        float pos, ease, size = BIG;
        pos = max(0.0, min(1.0, (time - start) / duration));
        if(pos < TRANSITION) {
            ease = easeInOutSine(pos / TRANSITION);
            size = small * (1.0-ease) + BIG * ease;
        }
        else if(pos > 1.0 - TRANSITION) {
            ease = easeInOutSine((1.0 - pos) / TRANSITION);
            size = small * (1.0-ease) + BIG * ease;
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
# Controller class

class Controller
    constructor: (mathbox, opts) ->
        opts ?= {}
        opts.numPointsRow ?= 50
        opts.numPointsCol ?= 100
        opts.duration     ?= 3.0

        @mathbox = mathbox

        # Current demo
        @current = null

        @numPointsRow = opts.numPointsRow
        @numPointsCol = opts.numPointsCol
        @numPoints = @numPointsRow * @numPointsCol - 1
        @duration = opts.duration
        @curTime = 0
        @points = [[0, 0, -1, 1e15]]

        # Colors
        @colors = [[0, 0, 0, 1]].concat([Math.random(), 1, 0.7, 1] for [0...@numPoints])

        # Un-transformed view
        @view0 = mathbox.cartesian
            range: [[-1, 1], [-1, 1]]
            scale: [1, 1]

        # The variables below are set when the first type is installed
        # Transformed view
        @view = null
        # View extents
        @extents =
            x:   0
            y:   0
            rad: 0

        @initialized  = false
        @shaderElt    = null
        @linesElt     = null
        @linesDataElt = null

    install: (type) =>
        @current = new type @extents
        canvas = @mathbox._context.canvas

        for i in [1..@numPoints]
            @points[i] = @current.newPoint()
            @points[i][2] = @curTime + @delay(true)
            @points[i][3] = @duration

        if @initialized
            @shaderElt.set @current.shaderParams()
            @linesDataElt.set @current.linesParams()
            @linesElt.set "closed", @current.refClosed()

        else
            @pointsElt = @view
                .matrix
                    id:       "points-orig"
                    channels: 4
                    width:    @numPointsRow
                    height:   @numPointsCol
                    data:     @points
            @shaderElt = @pointsElt.shader @current.shaderParams(),
                time: (t) => @curTime = t
            @shaderElt.resample id: "points"

            # Coloring pipeline
            @view0
                .matrix
                    channels: 4
                    width:    @numPointsRow
                    height:   @numPointsCol
                    data:     @colors
                    live:     false
                .shader
                    code:    colorShader
                    sources: [@pointsElt]
                ,
                    time: (t) -> t
                .resample id: "colors"

            # Size pipeline
            @view0
                .shader
                    code:   sizeShader
                ,
                    time:  (t) -> t
                    small: () -> 5 / 739 * canvas.clientWidth
                .resample
                    source: @pointsElt
                    id:     "sizes"

            @view
                .point
                    points: "#points"
                    color:  "white"
                    colors: "#colors"
                    size:   1
                    sizes:  "#sizes"
                    zBias:  1
                    zIndex: 2

            # Reference lines
            @linesDataElt = @view.matrix @current.linesParams()
            @linesElt = @view.line
                color:    "rgb(80, 120, 255)"
                width:    2
                opacity:  0.4
                zBias:    0
                zIndex:   1
                closed:   @current.refClosed()

            @initialized = true

    start: () =>
        setInterval () =>
            for point, i in @points
                if i == 0  # Origin
                    continue
                end = point[2] + point[3]
                if end < @curTime
                    # Reset point
                    [point[0], point[1]] = mult22 @current.stepMat, point
                    [point[0], point[1]] = @current.updatePoint point
                    # Reset timer
                    point[2] = @curTime + @delay()
            null
        , 100

    # Choose random (but not too wonky) coordinate system
    randomizeCoords: () =>
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

        @installCoords [v1[0], v2[0], v1[1], v2[1]]

    installCoords: (coordMat) =>
        # coordMat = [1,0,0,1]
        # Find the farthest corner in the un-transformed coord system
        coordMatInv = inv22 coordMat
        corners = [[1, 1], [-1, 1]].map (c) -> mult22 coordMatInv, c
        rad = Math.max.apply null, corners.map (c) -> c[0]*c[0] + c[1]*c[1]
        @extents =
            rad: Math.sqrt rad
            x:   Math.max.apply null, corners.map (c) -> Math.abs c[0]
            y:   Math.max.apply null, corners.map (c) -> Math.abs c[1]

        transformMat = [coordMat[0], coordMat[1], 0, 0,
                        coordMat[2], coordMat[3], 0, 0,
                        0, 0, 1, 0,
                        0, 0, 0, 1]
        if @view
            @view.set 'matrix', transformMat
        else
            @view = @view0.transform matrix: transformMat
            for i in [1, 2]
                @view.axis
                    axis:    i
                    end:     false
                    width:   3
                    size:    5
                    zBias:   -1
                    depth:   1
                    color:   "black"
                    opacity: 0.3
                    range:   [-10,10]

    delay: (first) =>
        scale = @numPoints / 1000
        pos = Math.random() * scale
        if first
            pos - 0.5 * scale
        else
            pos


######################################################################
# Dynamics base class

class Dynamics
    constructor: (@extents) ->

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
    constructor: (extents) ->
        super extents
        @deltaAngle = randSign() * linLerp(π/6, 5*π/6)(Math.random())
        @scale = @getScale()

        @stepMat = [Math.cos(@deltaAngle) * @scale, -Math.sin(@deltaAngle) * @scale,
                    Math.sin(@deltaAngle) * @scale,  Math.cos(@deltaAngle) * @scale]

        @makeDistributions()

    newPoint: (oldPoint) =>
        distribution = if not oldPoint then @origDist else @newDist
        r = distribution Math.random()
        θ = Math.random() * 2 * π
        [Math.cos(θ) * r, Math.sin(θ) * r, 0, oldPoint?[3]]

    shaderParams: () =>
        code: rotateShader,
        uniforms:
            deltaAngle: { type: 'f', value: @deltaAngle }
            scale:      { type: 'f', value: @scale }


class Circle extends Complex
    getScale: () => 1

    makeDistributions: () =>
        @newDist = @origDist = polyLerp 0.01, @extents.rad, 1/2

    makeReference: () =>
        ret = []
        for t in [0...2*π] by π/72
            row = []
            for s in [@extents.rad/10...@extents.rad] by @extents.rad/10
                row.push [s * Math.cos(t), s * Math.sin(t)]
            ret.push row
        [ret]

    updatePoint: (point) -> point

    refClosed: () => true


class Spiral extends Complex
    makeReference: () =>
        ret = []
        close = 0.05
        # How many iterations does it take to get from close to farthest?
        s = if @scale > 1 then @scale else 1/@scale
        iters = (Math.log(@extents.rad) - Math.log(close))/Math.log(s)
        # How many full rotations in that many iterations?
        rotations = Math.ceil(@deltaAngle * iters / 2*π)
        d = @direction
        # Have to put this in a matrix to avoid texture size limits
        for i in [0..rotations]
            row = []
            for t in [0..100]
                u = (i + t/100) * 2*π
                ss = close * Math.pow(s, u / @deltaAngle)
                items = []
                for j in [0...2*π] by π/4
                    items.push [ss * Math.cos(d*(u+j)), ss * Math.sin(d*(u+j))]
                row.push items
            ret.push row
        ret


class SpiralIn extends Spiral
    constructor: (extents) ->
        super extents
        @direction = -1

    getScale: () -> linLerp(0.3, 0.8)(Math.random())

    makeDistributions: () =>
        @close  = 0.01
        @medium = @extents.rad
        @far    = @extents.rad / @scale

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

    updatePoint: (point) =>
        if point[0]*point[0] + point[1]*point[1] < @close*@close
            @newPoint point
        else
            point


class SpiralOut extends Spiral
    constructor: (extents) ->
        super extents
        @direction = 1

    getScale: () => linLerp(1/0.8, 1/0.3)(Math.random())

    makeDistributions: () =>
        @veryClose = 0.01 / @scale
        @close     = 0.01
        @medium    = @extents.rad

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

    updatePoint: (point) =>
        if point[0]*point[0] + point[1]*point[1] > @medium * @medium
            @newPoint point
        else
            point


######################################################################
# Real eigenvalues, diagonalizable

class Diagonalizable extends Dynamics
    constructor: (extents) ->
        super extents
        @makeScales()
        @stepMat = [@scaleX, 0, 0, @scaleY]

    shaderParams: () =>
        code: diagShader,
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
        @farR = Math.pow(@extents.x, @logScaleY) * Math.pow(@extents.y, -@logScaleX)
        @lerpR = linLerp(@closeR, @farR)

    newPoint: (oldPoint) =>
        # First choose r uniformly between @closeR and @farR
        r = @lerpR Math.random()
        if not oldPoint
            # x value on that hyperbola at y = @extents.y
            closeX = Math.pow(r * Math.pow(@extents.y, @logScaleX), 1/@logScaleY)
            # Choose x value exponentially along that hyperbola
            x = expLerp(closeX, @extents.x / @scaleX)(Math.random())
        else
            # As above, but out of sight
            x = expLerp(@extents.x, @extents.x / @scaleX)(Math.random())
        # Corresponding y
        y = Math.pow(1/r * Math.pow(x, @logScaleY), 1/@logScaleX)
        [randSign() * x, randSign() * y, 0, oldPoint?[3]]

    makeReference: () =>
        ret = []
        for t in [0...20]
            r = @lerpR t/20
            closeX = Math.pow(r * Math.pow(@extents.y, @logScaleX), 1/@logScaleY)
            lerp = expLerp closeX, @extents.x
            row = []
            for i in [0..100]
                x = lerp i/100
                y = Math.pow(1/r * Math.pow(x, @logScaleY), 1/@logScaleX)
                row.push [[x,  y], [-x,  y], [ x, -y], [-x, -y]]
            ret.push row
        ret

    updatePoint: (point) =>
        if Math.abs(point[1]) > @extents.y
            @newPoint point
        else
            point


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
        # Last wave front is through (@extents.x, @extents.y)
        @sMin = 0.01
        @sMax = Math.pow(@extents.x, a) + @extents.y
        # The y-value of the point of intersection of the curves
        # x^a+y=s and x^lsy y^{-lsx} = r
        @yValAt = (r, s) -> s / (1 + Math.pow(r, 1/@logScaleX))
        # x as a function of y on the curve blah=r
        @xOfY = (y, r) -> Math.pow(r * Math.pow(y, @logScaleX), 1/@logScaleY)

    makeReference: () =>
        ret = []
        for i in [0...15]
            r = @lerpR i/15
            lerp = expLerp 0.01, @extents.y
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

    newPoint: (oldPoint) =>
        # First choose r
        r = @lerpR Math.random()
        farY = @yValAt r, @sMax / @scaleY
        if not oldPoint
            closeY = @yValAt r, @sMin
        else
            closeY = @yValAt r, @sMax
        y = expLerp(closeY, farY)(Math.random())
        x = @xOfY y, r
        [randSign() * x, randSign() * y, 0, oldPoint?[3]]

    updatePoint: (point) =>
        if Math.abs(point[1]) < .01
            @newPoint point
        else
            point


class Repel extends AttractRepel
    makeScales: () =>
        # scaleX <= scaleY implies logScaleY/logScaleX > 1
        @scaleY = linLerp(1/0.9, 1/0.3)(Math.random())
        @scaleX = linLerp(1/0.9, @scaleY)(Math.random())
        super

    newPoint: (oldPoint) =>
        # First choose r
        r = @lerpR Math.random()
        closeY = @yValAt r, @sMin / @scaleY
        if not oldPoint
            farY = @yValAt r, @sMax
        else
            farY = @yValAt r, @sMin
        y = expLerp(closeY, farY)(Math.random())
        x = @xOfY y, r
        [randSign() * x, randSign() * y, 0, oldPoint?[3]]

    updatePoint: (point) =>
        if Math.abs(point[0]) > @extents.x or Math.abs(point[1]) > @extents.y
            @newPoint point
        else
            point


class AttractRepelLine extends Diagonalizable
    makeScales: () =>
        @scaleX = 1
        @lerpX = linLerp -@extents.x, @extents.x

    newPoint: (oldPoint) =>
        x = @lerpX Math.random()
        y = (if not oldPoint then @origLerpY else @newLerpY)(Math.random())
        [x, randSign() * y, 0, oldPoint?[3]]

    makeReference: () =>
        item1 = []
        item2 = []
        for i in [0...20]
            x = @lerpX (i+.5)/20
            item1.push [x, -@extents.y]
            item2.push [x,  @extents.y]
        [[item1, item2]]


class AttractLine extends AttractRepelLine
    makeScales: () =>
        super
        @scaleY = linLerp(0.3, 0.8)(Math.random())
        @origLerpY = expLerp 0.01, @extents.y / @scaleY
        @newLerpY = expLerp @extents.y, @extents.y / @scaleY

    updatePoint: (point) =>
        if Math.abs(point[1]) < 0.01
            @newPoint point
        else
            point


class RepelLine extends AttractRepelLine
    makeScales: () =>
        super
        @scaleY = linLerp(1/0.8, 1/0.3)(Math.random())
        @origLerpY = expLerp 0.01 / @scaleY, @extents.y
        @newLerpY = expLerp 0.01 / @scaleY, 0.01

    updatePoint: (point) =>
        if Math.abs(point[1]) > @extents.y
            @newPoint point
        else
            point


######################################################################
# Real eigenvalues, not diagonalizable

class Shear extends Dynamics
    constructor: (extents) ->
        super extents
        @translate = randSign() * linLerp(0.2, 2.0)(Math.random())
        @stepMat = [1, @translate, 0, 1]
        @lerpY = linLerp 0.01, @extents.y
        # For reference
        @lerpY2 = linLerp -@extents.y, @extents.y

    newPoint: (oldPoint) =>
        a = @translate
        if not oldPoint
            y = @lerpY Math.random()
            # Put a few points on the x-axis
            if Math.random() < 0.005
                y = 0
                x = linLerp(-@extents.x, @extents.x)(Math.random())
            else
                if a < 0
                    x = linLerp(-@extents.x, @extents.x - a*y)(Math.random())
                else
                    x = linLerp(-@extents.x - a*y, @extents.x)(Math.random())
        else
            # Don't change path
            y = Math.abs oldPoint[1]
            if a < 0
                x = linLerp(@extents.x, @extents.x - a*y)(Math.random())
            else
                x = linLerp(-@extents.x - a*y, -@extents.x)(Math.random())
        s = randSign()
        [s*x, s*y, 0, oldPoint?[3]]

    shaderParams: () =>
        code: shearShader,
        uniforms:
            scale:     { type: 'f', value: 1.0 }
            translate: { type: 'f', value: @translate }

    makeReference: () =>
        item1 = []
        item2 = []
        for i in [0...20]
            y = @lerpY2 (i+.5)/20
            item1.push [-@extents.x, y]
            item2.push [@extents.x, y]
        [[item1, item2]]

    updatePoint: (point) =>
        if Math.abs(point[0]) > @extents.x
            @newPoint point
        else
            point


class ScaleInOutShear extends Dynamics
    constructor: (extents) ->
        super extents
        @translate = randSign() * linLerp(0.2, 2.0)(Math.random())
        λ = @scale
        a = @translate
        @stepMat = [λ, λ*a, 0, λ]
        # Paths have the form λ^t(r+ta, 1)
        @xOfY = (r, y) -> y * (r + a*Math.log(y)/Math.log(λ))
        # tan gives a nice looking plot
        @lerpR = (t) -> Math.tan((t - 0.5) * π)
        # for points
        @lerpR2 = (t) -> Math.tan((t/0.99 + 0.005 - 0.5) * π)

    newPoint: (oldPoint) =>
        # Choose a path
        r = @lerpR2 Math.random()
        y = (if not oldPoint then @lerpY else @lerpYNew)(Math.random())
        x = @xOfY r, y
        s = randSign()
        [s*x, s*y, 0, oldPoint?[3]]

    shaderParams: () =>
        code: shearShader,
        uniforms:
            scale:     { type: 'f', value: @scale }
            translate: { type: 'f', value: @translate }

    makeReference: () =>
        ret = []
        numLines = 40
        for i in [1...numLines]
            r = @lerpR i/numLines
            row = []
            for j in [0...100]
                y = @lerpY j/100
                x = @xOfY r, y
                row.push [[x, y], [-x, -y]]
            ret.push row
        return ret


class ScaleOutShear extends ScaleInOutShear
    constructor: (@extents) ->
        @scale = linLerp(1/0.7, 1/0.3)(Math.random())
        @lerpY = expLerp 0.01/@scale, @extents.y
        @lerpYNew = expLerp 0.01/@scale, 0.01
        super @extents

    updatePoint: (point) =>
        if Math.abs(point[1]) > @extents.y
            @newPoint point
        else
            point


class ScaleInShear extends ScaleInOutShear
    constructor: (@extents) ->
        @scale = linLerp(0.3, 0.7)(Math.random())
        @lerpY = expLerp 0.01, @extents.y / @scale
        @lerpYNew = expLerp @extents.y, @extents.y / @scale
        super @extents

    updatePoint: (point) =>
        if Math.abs(point[1]) < .01
            @newPoint point
        else
            point


######################################################################
# Exports

window.dynamics = {}

window.dynamics.Controller    = Controller

window.dynamics.Circle        = Circle
window.dynamics.SpiralIn      = SpiralIn
window.dynamics.SpiralOut     = SpiralOut
window.dynamics.Hyperbolas    = Hyperbolas
window.dynamics.Attract       = Attract
window.dynamics.Repel         = Repel
window.dynamics.AttractLine   = AttractLine
window.dynamics.RepelLine     = RepelLine
window.dynamics.Shear         = Shear
window.dynamics.ScaleOutShear = ScaleOutShear
window.dynamics.ScaleInShear  = ScaleInShear

