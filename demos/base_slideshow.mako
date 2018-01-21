## -*- mode: coffee; coding: utf-8 -*-

<%inherit file="base2.mako"/>

<%block name="css">
    <link rel="stylesheet" href="${"css/slideshow.css" | vers}">
</%block>

<%block name="js">
    <script src="${"js/slideshow.js" | vers}"></script>
</%block>

<%block name="inline_style">
  body {
      text-align: center;
      margin: 0;
      background: white;
  }

  #mathbox {
      width: 800px;
      height: 300px;
      margin: 0;
      border: 0;
      position: relative;
      display: inline-block;
  }

  .centered {
      width: 800px;
      display: inline-block;
  }

  .my-turn {
      width: 30%;
      text-align: center;
  }
</%block>

<%block name="body_html">
    <div id="mathbox"></div>
    <div class="centered">
        <div class="slideshow rrmat">
            <div class="controls">
                <span class="control-button">
                    <span class="icon-arrow prev-button inactive">
                        <span></span><span></span>
                    </span>
                </span>
                <span class="control-button">
                    <span class="icon-repeat reload-button inactive">
                        <span></span><span></span><span></span><span></span>
                    </span>
                </span>
                <span class="control-button" id="next-button">
                    <span class="icon-arrow next-button">
                        <span></span><span></span></span>
                </span><br>
                <span class="pages"></span>
            </div>
            <div class="caption"><%block name="first_caption"/></div>
        </div>
        <div class="my-turn">
            <button class="slideshow-button">
                Let me take it from here.
            </button>
        </div>
    </div>
</%block>

##

ortho = 10000
width = 800
height = 300

mathbox = window.mathbox = mathBox
    element: document.getElementById "mathbox"
    size: { width: width, height: height }
    plugins: ['core']
    mathbox:
        warmup: 2
        splash: true
        inspect: false
    splash: {fancy: true, color: "blue"}
    camera:
        near: ortho / 4
        far: ortho * 4
        lookAt: -width/4
throw "WebGL not supported" if mathbox.fallback
three = mathbox.three
three.renderer.setClearColor(new THREE.Color(0xFFFFFF), 1.0)
# Place camera
camera = mathbox.camera
    proxy: false
    position: [0, 0, ortho]
    fov: Math.atan(height/ortho) * 360 / π
    lookAt: [width/4,0,0]
# 2D cartesian
view = mathbox.cartesian
    range: [[-width/2, width/2], [-height/2, height/2], [-50,50]]
    scale: [width, height, 100]
# Calibrate focus distance for units
mathbox.set('focus', ortho)

window.rrmat = new RRMatrix 3, 4, view, mathbox,
    augmentCol:     2
    startAugmented: true

window.blink = blink = (color, entries, times) ->
    times = 2 if !times
    arr = []
    delay = 0
    for i in [0...times]
        arr.push
            color:     color
            transform: "scale(2,2)"
            entries:   entries
            duration:  0.4
            delay:     delay
        delay += 0.4
        last =
            color:     "black"
            transform: ""
            entries:   entries
            duration:  0.4
            delay:     delay
        delay += 0.4
        arr.push last
    delete last.color
    return arr

augment = null
${next.body()}

document.querySelector(".my-turn button").onclick = () ->
    # Encode matrix
    mat = slideshow.states[0].matrix
    rows = []
    for i in [0...mat.length]
        row = []
        for j in [0...mat[0].length]
            entry = mat[i][j]
            [num, den] = RRMatrix.approxFraction entry
            row.push(num + (den != 1 ? "%2F" + den : ""))
        rows.push row.join ","
    matval = rows.join(":")
    # Encode row operations
    # Traverse slide tree recursively
    getOps = (slide) ->
        if slide.slides
            # Has children slides
            ret = []
            for i in [0...slide.slides.length]
                ret = ret.concat getOps slide.slides[i]
            return ret
        # No children slides
        if slide.data.shortOp
            return [slide.data.shortOp]
        return []
    ops = []
    for i in [0...slideshow.currentSlideNum]
        ops = ops.concat getOps slideshow.slides[i]
    opsval = ops.join ","

    str = "rrinter.html?mat=#{matval}&ops=#{opsval}&cur=#{ops.length}"
    if augment?
        str += "&augment=#{augment}"
    window.open str

