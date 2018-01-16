<!DOCTYPE html> <!-- -*- coffee -*-
###
-->
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="initial-scale=1, maximum-scale=1">
  <title>Cover</title>

  <link rel="stylesheet" href="mathbox/mathbox.css">

  <style>
  #content {
      width:        80%;
      margin-left:  auto;
      margin-right: auto;
  }
  #mathbox-container {
      width:       100%;
      height:      0;
      padding-top: 100%;
      overflow:    hidden;
      position:    relative;
  }
  #mathbox {
      position: absolute;
      top:      0;
      left:     0;
      width:    100%;
      height:   100%;
  }
  </style>
</head>
<body>
    <div id="content">
        <div id="mathbox-container">
            <div id="mathbox">
            </div>
        </div>
    </div>

  <script src="mathbox/mathbox-bundle.js?version=3"></script>
  <script src="lib/domready.js"></script>

  <script type="application/glsl" id="rotate-shader">

#define M_PI 3.1415926535897932384626433832795

uniform float deltaAngle;
uniform float scale;
uniform float time;

vec4 getTimingsSample(vec4 xyzw);
vec4 getPointSample(vec4 xyzw);

float easeInOutSine(float pos) {
    return 0.5 * (1.0 - cos(M_PI * pos));
}

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

  </script>

  <script type="application/glsl" id="color-shader">

#define M_PI 3.1415926535897932384626433832795

uniform float time;

vec4 getTimingsSample(vec4 xyzw);
vec4 getColorSample(vec4 xyzw);

float easeInOutSine(float pos) {
    return 0.5 * (1.0 - cos(M_PI * pos));
}

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

  </script>

  <script type="application/glsl" id="size-shader">

#define M_PI 3.1415926535897932384626433832795

uniform float time;

vec4 getTimingsSample(vec4 xyzw);

float easeInOutSine(float pos) {
    return 0.5 * (1.0 - cos(M_PI * pos));
}

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

  </script>

  <script type="text/javascript">
      "use strict";
      DomReady.ready(function() {

/*
###
*/

<%block filter="coffee">

# TODO:
#  * Speed based on deltaAngle?
#  * change color saturation/brightness and size when moving?  (via shaders)
#  * make this interactive
#  * splash (via css?)
#  * ellipses instead of random radius distribution?

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
mult22 = (m, v) -> [m[0]*v[0]+m[1]*v[1], m[2]*v[0]+m[3]*v[1]]
inv22 = (m) ->
    det = m[0]*m[3] - m[1]*m[2]
    [m[3]/det, -m[1]/det, -m[2]/det, m[0]/det]
randSign = () -> if Math.random() < 0.5 then 1 else -1


######################################################################
# MathBox boilerplate

ortho = 1e5

mathbox = window.mathbox = mathBox
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

view = mathbox.cartesian
    range: [[-1, 1], [-1, 1]]
    scale: [1, 1]


######################################################################
# Global variables

# Current demo
current = null

numPoints = 5000
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
timings = [[1, 1]]


######################################################################
# Colors

colors = [[0, 0, 0, 1]].concat([Math.random(), 1, 0.7, 1] for [0...numPoints])


######################################################################
# Change of basis

# Choose random (but not too wonky) coordinate system
v1 = [0, 0]
v2 = [0, 0]
do () ->
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
# Find the farthest corner in the un-transformed coord system
coordMatInv = inv22 coordMat
corners = [[1, 1], [-1, 1]].map (c) -> mult22 coordMatInv, c
farthest = Math.max.apply null, corners.map (c) -> c[0]*c[0] + c[1]*c[1]
farthest = Math.sqrt farthest

view0 = view
view = view.transform
    matrix: [coordMat[0], coordMat[1], 0, 0,
             coordMat[2], coordMat[3], 0, 0,
             0, 0, 1, 0,
             0, 0, 0, 1]


######################################################################
# Axes

for i in [1, 2]
    view.axis
        axis:    i
        end:     false
        width:   3
        size:    5
        zBias:   -1
        depth:   1
        color:   "black"
        opacity: 0.5
        range:   [-10,10]


######################################################################
# Type of matrices and dynamics

initialized = false
shaderElt = null
linesElt = null

class Dynamics
    constructor: () ->
        @mat = []

    install: () =>
        for i in [1..numPoints]
            @newPoint i, true
            timings[i][0] = curTime + delay(true)

        if initialized
            shaderElt.set @shaderParams()
            linesElt.set @linesParams()

        else
            view0
                .array
                    id:       "timings"
                    channels: 2
                    width:    timings.length
                    data:     timings
                    live:     true

            pointsElt = view
                .array
                    id:       "points-orig"
                    channels: 4
                    width:    points.length
                    data:     points
            shaderElt = pointsElt.shader @shaderParams(), time: (t) -> curTime = t
            shaderElt.resample id: "points"

            # Coloring pipeline
            view0
                .array
                    channels: 4
                    width:    colors.length
                    data:     colors
                    live:     false
                .shader
                    code:    "#color-shader"
                    sources: ["#timings"]
                ,
                    time: (t) -> t
                .resample id: "colors"

            # Size pipeline
            view0
                .shader
                    code:   "#size-shader"
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
            view
                .array @linesParams()
                .line
                    color:    "rgb(0, 80, 255)"
                    width:    2
                    opacity:  0.75
                    zBias:    0
                    zIndex:   1
                    #closed:   true
            initialized = true

class SpiralIn extends Dynamics
    constructor: () ->
        super
        @deltaAngle = randSign() * linLerp(π/6, 5*π/6)(Math.random())
        @scale = linLerp(0.3, 0.8)(Math.random())

        stepMat = [Math.cos(@deltaAngle) * @scale, -Math.sin(@deltaAngle) * @scale,
                   Math.sin(@deltaAngle) * @scale,  Math.cos(@deltaAngle) * @scale]

        @close  = 0.01
        @medium = farthest
        @far    = farthest / @scale

        # Reference spirals
        @spiral = []
        for t in [-10*π...10*π] by π/72
            s = Math.pow(@scale, t / @deltaAngle)
            row = []
            for j in [0...2*π] by π/4
                row.push [s * Math.cos(t+j), s * Math.sin(t+j)]
            @spiral.push row

        # Original points
        @origDist = expLerp @close, @far
        # For new points
        @newDist = expLerp @medium, @far

    newPoint: (i, first) =>
        distribution = if first then @origDist else @newDist
        r = distribution Math.random()
        θ = Math.random() * 2 * π
        timings[i] = [0, duration]
        points[i] = [Math.cos(θ) * r, Math.sin(θ) * r, 0, 0]

    updatePoint: (i) =>
        point = points[i]
        if point[0]*point[0] + point[1]*point[1] < @close*@close
            @newPoint i
        points[i]

    shaderParams: () =>
        code: '#rotate-shader'
        sources: ["#timings"]
        uniforms:
            deltaAngle: { type: 'f', value: @deltaAngle }
            scale:      { type: 'f', value: @scale }

    linesParams: () =>
        channels: 2
        width:    @spiral.length
        items:    @spiral[0].length
        data:     @spiral
        live:     false

current = new SpiralIn()
current.install()

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

</%block>
/*
###
*/
        });
  </script>
</body>
</html>
<!--
###

-->
