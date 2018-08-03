## -*- coffee -*-

<%inherit file="base2.mako"/>

<%block name="title">Span of vectors</%block>

<%block name="inline_style">
  .overlay-popup h2 {
      color:      var(--palette-green);
      text-align: center;
  }
  .span-type, #span-type {
      color: var(--palette-violet);
  }
  .complement {
      color: var(--palette-red);
  }
  .inter-is {
      padding: 10px;
  }
  .dg.main .cr.boolean > div > .property-name {
      width: 60%;
  }
  .dg.main .cr.boolean > div > .c {
      width: 40%;
  }
  .dg.main .cr.number.has-slider > div > .property-name {
      width: 10%;
  }
  .dg.main .cr.number.has-slider > div > .c {
      width: 90%;
  }
  .dg.main .cr.number.has-slider > div > .c .slider {
      width: 85%;
  }
  .dg.main .cr.number.has-slider > div > .c input {
      width: 10%;
  }
</%block>

##

# Supported URL parameters:
#     camera: camera position
#     range: size of the viewable range
#     v1, v2, v3: vector starting locations; also determines number of vectors
#     labels: vector labels
#     coeffs: linear combination coefficients labels
#     lcstart: linear combination starting coefficients
#     target: target vector
#     tlabel: target vector label
#     nomove: whether the vectors are movable
#     axes: show axes (on, [off], disabled)
#     lincombo: show linear combination (on, [off], disabled)
#     grid: show grid (on, off / enabled, [disabled])
#     hidespace: don't turn the box red when the span is space
#     captions: caption type:
#         target: "make this vector as a linear combination..."
#         combo: write linear combination
#         indep: "these vectors are linearly independent"
#         orthog: orthogonal complements
#         default: "the span of these vectors is a plane"
#     capopt: caption options:
#         matrix: use matrix equation instead of vector equation

is2D = urlParams.v1?.split(',').length == 2

window.demo = new (if is2D then Demo2D else Demo) {
    mathbox:
        mathbox:
            warmup:  10
            splash:  false
            inspect: false
}, () ->
    window.mathbox = @mathbox

    ##################################################
    # Demo parameters: defaults and urlParams
    @numVecs  = 3
    @vector1  = @urlParams.get 'v1', 'float[]', [5, 3, -2]
    @vector2  = @urlParams.get 'v2', 'float[]', [3, -4, 1]
    @vector3  = @urlParams.get 'v3', 'float[]', [-1, 1, 7]
    @labels   = @urlParams.get 'labels', 'str[]', ['v1', 'v2', 'v3']
    @coeffs   = @urlParams.get 'coeffs', 'str[]', ['x', 'y', 'z']
    @lcstart  = @urlParams.get 'lcstart', 'float[]', [1.0, 1.0, 1.0]
    @colors   = [new Color("blue"), new Color("green"), new Color("brown")]
    @doTarget = false
    @target = null
    @targetColor = new Color(0, 0, 0)
    @doComplement = false
    @hideSpace = false

    if @urlParams.v1?
        @numVecs = 1
    if @urlParams.v2?
        @numVecs = 2
    if @urlParams.v3?
        @numVecs = 3
    if @urlParams.target?
        @target = @urlParams.get 'target', 'float[]'
        @doTarget = true
        # Existence of a target by default puts us into "linear combination" mode
        @urlParams.lincombo  ?= 'on'
        @urlParams.captions  ?= 'target'
        @urlParams.nomove    ?= 'true'
        @urlParams.grid      ?= 'on'
        @hideSpace = true
    else if @urlParams.captions == 'combo'
        @urlParams.lincombo  ?= 'on'
        @urlParams.grid      ?= 'on'
        @hideSpace = true
    else if @urlParams.captions == 'orthog'
        @urlParams.lincombo  ?= 'disabled'
        @urlParams.grid      ?= 'disabled'
        @doComplement = true
    @targetLabel = @urlParams.tlabel ? 'w'

    @hideSpace = @urlParams.get 'hidespace', 'bool', @hideSpace

    @vectors = [@vector1, @vector2, @vector3][0...@numVecs]
    @colors  = @colors[0...@numVecs]
    @labels  = @labels[0...@numVecs]
    @coeffs  = @coeffs[0...@numVecs]
    @lcstart = @lcstart[0...@numVecs]

    @isLive = !@urlParams.nomove? or @urlParams.nomove == "false"

    if is2D
        vec[2] = 0 for vec in @vectors
        @target[2] = 0 if @doTarget

    ##################################################
    # gui
    params =
        Axes: @urlParams.axes == "on"
    checkLabel = "Show #{@coeffs[0]}.#{@labels[0]}"
    if @numVecs >= 2
        checkLabel += " + #{@coeffs[1]}.#{@labels[1]}"
    if @numVecs >= 3
        checkLabel += " + #{@coeffs[2]}.#{@labels[2]}"
    params[checkLabel] = @urlParams.lincombo == "on"

    gui = new dat.GUI width: 350
    gui.closed = @urlParams.closed?
    guiElts = {}
    if @urlParams.axes != "disabled"
        guiElts.Axes = gui.add(params, 'Axes')
        guiElts.Axes.onFinishChange (val) ->
            mathbox.select(".view-axes").set "visible", val
    if @urlParams.lincombo != "disabled"
        guiElts[checkLabel] = gui.add(params, checkLabel)
        guiElts[checkLabel].onFinishChange (val) ->
            mathbox.select(".lincombo").set "visible", val
        params[@coeffs[0]] = @lcstart[0]
        guiElts[@coeffs[0]] = gui.add(params, @coeffs[0], -10, 10).step 0.1
        if @numVecs >= 2
            params[@coeffs[1]] = @lcstart[1]
            guiElts[@coeffs[1]] = gui.add(params, @coeffs[1], -10, 10).step 0.1
        if @numVecs >= 3
            params[@coeffs[2]] = @lcstart[2]
            guiElts[@coeffs[2]] = gui.add(params, @coeffs[2], -10, 10).step 0.1
    if @urlParams.grid in ["enabled", "on"]
        params.Grid = @urlParams.grid == "on"
        guiElts.Grid = gui.add(params, 'Grid')
        guiElts.Grid.onFinishChange (val) ->
            mathbox.select("#vecgrid").set "visible", val
            clipCube.uniforms.hilite.value = not val

    ##################################################
    # view, axes
    view = @view
        grid: false
        axes: @urlParams.axes != "disabled"
        axisOpts:
            zIndex:  1
    @mathbox.select(".view-axes").set "visible", params.Axes

    if @urlParams.captions == 'orthog'
        view
            .array
                channels: 3
                width:    1
                live:     false
                data:     [[0,0,0]]
            .point
                color:    "black"
                size:     15
                zIndex:   3

    ##################################################
    # labeled vectors
    lVectors = @vectors.slice()
    lColors  = @colors.slice()
    lLabels  = @labels.slice()
    if @doTarget
        lVectors.push @target
        lColors.push  @targetColor
        lLabels.push  @targetLabel
    @labeledVectors view,
        vectors:       lVectors
        colors:        lColors
        labels:        lLabels
        live:          @isLive
        zeroPoints:    true
        zeroThreshold: 0.05
        vectorOpts:    zIndex: 2
        labelOpts:     zIndex: 3
        zeroOpts:      zIndex: 3

    ##################################################
    # linear combination
    if @urlParams.lincombo != "disabled"
        linCombo = @linearCombo view,
            coeffs:    params
            coeffVars: @coeffs
            vectors:   @vectors
            colors:    @colors.slice()
            labels:    @labels
        @mathbox.select(".lincombo").set "visible", params[checkLabel]

    ##################################################
    # Clip cube
    surfaceColor = new Color "violet"
    complementColor = new Color "red"

    clipCube = @clipCube view,
        draw:     true
        material: new THREE.MeshBasicMaterial
            color:       surfaceColor.three()
            opacity:     0.25
            transparent: true
            visible:     false
            depthWrite:  false
            depthTest:   true

    clipCube.installMesh()
    clipCube.uniforms.hilite.value = not params.Grid

    ##################################################
    # Subspace
    range = @urlParams.get 'range', 'float', 10
    snapThreshold = 1.0 * range / 10.0
    zeroThreshold = 0.00001

    subspace = @subspace
        vectors:       @vectors
        noPlane:       is2D and @hideSpace
        zeroThreshold: zeroThreshold
        live:          @isLive
        range:         range
        color:         surfaceColor
        # Lines before planes for transparency
        lineOpts:
            zOrder: 0
        surfaceOpts:
            zOrder: 1
    subspace.draw clipCube.clipped

    if @doComplement
        complement = @subspace
            name:          'complement'
            vectors:       subspace.complementFull(is2D)
            noPlane:       is2D and @hideSpace
            zeroThreshold: zeroThreshold
            live:          @isLive
            range:         range
            color:         complementColor
            pointOpts:     {size: 20, zIndex: 4}
            # Lines before planes for transparency
            lineOpts:
                zOrder: 0
            surfaceOpts:
                zOrder: 1
        complement.draw clipCube.clipped

    ##################################################
    # Grid
    if @urlParams.grid in ["enabled", "on"]
        @grid clipCube.clipped,
            vectors: @vectors
            live:    @isLive
            lineOpts: color: surfaceColor
        mathbox.select("#vecgrid").set "visible", @urlParams.grid == "on"

    ##################################################
    # Snap to subspace
    snapped = new THREE.Vector3()
    diff = new THREE.Vector3()
    ss0 = @subspace vectors: [[0, 0, 0]]
    ss1 = @subspace vectors: [[0, 0, 0]]
    ss2 = @subspace vectors: [[0, 0, 0], [0, 0, 0]]
    ss3 = @subspace vectors: [[0, 0, 0], [0, 0, 0], [0, 0, 0]]
    subspaces = [ss0, ss1, ss2, ss3]

    snap = (vec, vecs) =>
        ss = subspaces[vecs.length]
        if vecs.length > 0
            ss.setVecs vecs
        ss.project vec, snapped
        diff.copy(vec).sub snapped
        if diff.lengthSq() <= snapThreshold
            vec.copy snapped
            return true
        return false

    self = @
    onDrag = (vec) ->
        # Try snapping to 0
        return if snap vec, []
        indices = [0...self.numVecs].filter (x) => x != @dragging
        others = (self.vectors[i] for i in indices)
        # Try snapping to one of the other vectors
        for other in others
            return if snap vec, [other]
        # Try snapping to the span of the other vectors
        snap vec, others

    updateMesh = () ->
        mesh = clipCube.mesh
        if complement?.dim == 3
            mesh.material.color = complementColor
            mesh.material.visible = true
        else if subspace.dim == 3
            mesh.material.color = surfaceColor.three()
            mesh.material.visible = true
        else
            mesh.material.visible = false
    updateMesh()

    if @isLive
        # Make the vectors draggable
        @draggable view,
            points: @vectors
            onDrag: onDrag
            postDrag: () =>
                subspace.setVecs @vectors
                complement?.setVecs subspace.complementFull(is2D)
                updateMesh()
                updateCaption()

    ##################################################
    # Captions

    switch @urlParams.captions
        when "target"
            @caption '''<p>Solve this equation by moving the sliders:</p>
                        <p><span id="eqn-here"></span>.</p>
                     '''
            eqnElt = document.getElementById 'eqn-here'
            popup = @popup '''<h2>Success</h2>
                              <p><span id="success-here"></span></p>
                           '''
            successElt = document.getElementById 'success-here'

            updateCaption = () =>
                if @urlParams.capopt == 'matrix'
                    str = @texMatrix @vectors, colors: @colors.slice()
                    str += @texVector (params[c] for c in @coeffs)
                else
                    str = @texCombo @vectors,
                                    (params[c] for c in @coeffs),
                                    colors: @colors.slice()
                lc = linCombo.combine()
                str += " = " + @texVector lc
                equal = (lc[0] == @target[0] and
                         lc[1] == @target[1] and
                         lc[2] == @target[2])
                str2 = str
                str += if equal then " = " else " \\neq "
                str += @texVector @target
                katex.render str, eqnElt

                if equal
                    katex.render str2, successElt
                    popup.show()
                else
                    popup.hide()

            for coeff in @coeffs
                guiElts[coeff].onChange () -> updateCaption()

        when "combo"
            @caption '<p><span id="eqn-here"></span></p>'
            eqnElt = document.getElementById 'eqn-here'
            updateCaption = () =>
                if @urlParams.capopt == 'matrix'
                    str = @texMatrix @vectors, colors: @colors.slice()
                    str += @texVector (params[c] for c in @coeffs)
                else
                    str = @texCombo @vectors,
                                    (params[c] for c in @coeffs),
                                    colors: @colors.slice()
                lc = linCombo.combine()
                str += " = " + @texVector lc
                katex.render str, eqnElt

            for coeff in @coeffs
                guiElts[coeff].onChange () -> updateCaption()

        when "indep"
            @caption '''<p>The set <span id="vectors-here"></span>
                        <span class="inter-is">is</span>
                        <span id="span-type" class="span-type"></span>.</p>
                     '''
            vectorsElt = document.getElementById 'vectors-here'
            spanElt    = document.getElementById 'span-type'
            updateCaption = () =>
                katex.render @texSet(@vectors, colors: @colors.slice()), vectorsElt

                if subspace.dim == @numVecs
                    spanElt.innerText = "linearly independent"
                else
                    spanElt.innerText = "linearly dependent"

        when "orthog"
            labels = @labels.join ', '
            @caption """
                <p>The subspace Span{#{labels}} <span class="inter-is">is</span>
                <span id="span-type" class="span-type"></span>.</p>
                <p>The orthogonal complement of Span{#{labels}}
                <span class="inter-is">is</span>
                <span id="complement-type" class="span-type complement"></span>.</p>
            """
            spaceElt = document.getElementById 'span-type'
            complElt = document.getElementById 'complement-type'
            types = ["a point", "a line", "a plane", "space"]
            updateCaption = () =>
                spaceElt.innerText = types[subspace.dim]
                complElt.innerText = types[complement.dim]

        else
            if @urlParams.capopt == 'matrix'
                str = '<p>The span of the columns of <span id="vectors-here"></span>'
            else
                str = '<p>Span <span id="vectors-here"></span>'
            @caption str + '''
                              <span class="inter-is">is</span>
                              <span id="span-type"></span>.</p>
                           '''
            vectorsElt = document.getElementById 'vectors-here'
            spanElt    = document.getElementById 'span-type'
            updateCaption = () =>
                if @urlParams.capopt == 'matrix'
                    katex.render @texMatrix(@vectors, colors: @colors.slice()), vectorsElt
                else
                    katex.render @texSet(@vectors, colors: @colors.slice()), vectorsElt

                spanElt.innerText = \
                    ["a point", "a line", "a plane", "space"][subspace.dim]

    updateCaption()
