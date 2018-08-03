## -*- coffee -*-

<%inherit file="base_triptych.mako"/>

<%block name="title">A transformation in steps</%block>

<%block name="inline_style">
${parent.inline_style()}
.color1 {
    color: var(--palette-green);
}
.color2 {
    color: var(--palette-blue);
}
</%block>

<%block name="overlay_text">
<div class="overlay-text">
  <p>Starting vector:
    <span id="vector1-here"></span>
    &nbsp;&nbsp;
    Reflect over <span class="color1">xy</span>-plane:
    <span id="vector2-here"></span>
    &nbsp;&nbsp;
    Project onto <span class="color2">yz</span>-plane:
      <span id="vector3-here"></span>
  </p>
</div>
</%block>

<%block name="label1">
<div class="mathbox-label">Start</div>
</%block>
<%block name="label2">
<div class="mathbox-label">Reflect over <span class="color1">xy</span>-plane</div>
</%block>
<%block name="label3">
<div class="mathbox-label">Project onto <span class="color2">yz</span>-plane</div>
</%block>

##

##################################################
# globals
vector1 = urlParams.get 'x', 'float[]', [1, 2, 2]
vector2 = [0, 0, 0]
vector3 = [0, 0, 0]

computeOut = () ->
    vector2[0] = vector1[0]
    vector2[1] = vector1[1]
    vector2[2] = -vector1[2]
    vector3[0] = 0
    vector3[1] = vector2[1]
    vector3[2] = vector2[2]
    updateCaption()

##################################################
# make demos

setupDemo = (opts) ->
    new Demo {
        mathbox: element: document.getElementById "mathbox#{opts.index}"
        scaleUI: false
        camera: position: [2, 1.4, 1.2]
    }, () ->
        {@index, @vector, @color, @label} = opts
        window["mathbox#{@index}"] = @mathbox

        ##################################################
        # view
        @viewObj = @view
            grid:      false
            viewRange: [[-3,3],[-3,3],[-3,3]]

        ##################################################
        # labeled vector
        labeled = @labeledVectors @viewObj,
            name:          "labeled"
            vectors:       [@vector]
            colors:        [@color]
            labels:        if @label then [@label] else undefined
            live:          true
            zeroPoints:    true
            zeroThreshold: 0.1
            vectorOpts:    zIndex: 2
            labelOpts:     zIndex: 3
            zeroOpts:      zIndex: 3

        ##################################################
        # planes
        @viewObj
            .area
                axes:    [1, 2]
                rangeX:  [-3, 3]
                rangeY:  [-3, 3]
                width:   7
                height:  7
                live:    false
            .surface
                color:   new Color("green").arr()
                lineX:   true
                lineY:   true
                fill:    false
                opacity: 0.75
            .swizzle order: "zxyw"
            .surface
                color:   new Color("blue").arr()
                lineX:   true
                lineY:   true
                fill:    false
                opacity: 0.75

color1 = new Color("green")
color2 = new Color("violet")
color3 = new Color("red")

inLabel = urlParams.in ? 'u'
window.demo1 = setupDemo
    index:  1
    vector: vector1
    color:  color1
    label:  inLabel

window.demo2 = setupDemo
    index:  2
    vector: vector2
    color:  color2

outLabel = urlParams.out ? 'T'
window.demo3 = setupDemo
    index:  3
    vector: vector3
    color:  color3
    label:  "#{outLabel}(#{inLabel})"

##################################################
# dragging
demo1.draggable demo1.viewObj,
    points:   [vector1]
    postDrag: computeOut

groupControls demo1, demo2, demo3


vector1Elt = document.getElementById 'vector1-here'
vector2Elt = document.getElementById 'vector2-here'
vector3Elt = document.getElementById 'vector3-here'

updateCaption = () ->
    str = demo1.texVector vector1, color: color1
    katex.render str, vector1Elt
    str = demo2.texVector vector2, color: color2
    katex.render str, vector2Elt
    str = demo3.texVector vector3, color: color3
    katex.render str, vector3Elt

computeOut()
