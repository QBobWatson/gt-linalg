## -*- html -*-

<%inherit file="base2.mako"/>

<%block name="inline_style">
html, body {
    margin:           0;
    height:           100%;
    background-color: white;
    overflow-x:       hidden;
}
.mathbox-wrapper {
    width:       50%;
    padding-top: 50%;
    position:    absolute;
    left:        0;
    top:         50%;
    transform:   translate(0, -50%);
}
.mathbox-wrapper + .mathbox-wrapper {
    left:        50%;
}
.mathbox-wrapper > div {
    position: absolute;
    top:      0;
    left:     0;
    width:    100%;
    height:   100%;
}
.mathbox-label {
    position:  absolute;
    left:      50%;
    top:       10px;
    color:     black;
    opacity:   1.0;
    background-color: rgba(220, 220, 220, .5);
    border:    solid 1px rgba(50, 50, 50, .5);
    padding:   5px;
    transform: translate(-50%, 0);
}
.overlay-text {
    z-index: 1;
}
</%block>

<%block name="body_html">
<%block name="overlay_text"/>
<div class="mathbox-wrapper">
    <div id="mathbox1">
        <%block name="label1"/>
    </div>
</div>
<div class="mathbox-wrapper">
    <div id="mathbox2">
        <%block name="label2"/>
    </div>
</div>
</%block>

${next.body()}
