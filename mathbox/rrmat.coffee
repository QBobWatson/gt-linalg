"use strict"

# TODO: Make this interactive!!!  The student can do their own row reduction.
# TODO: Factor out animation, slideshow code as abstractions
# TODO: Funny sizes on Safari
# TODO: just-in-time width measuring with persistent measuring elements
# TODO: AnimState, Animation, Step signals and triggers

deepCopy = (x) ->
    if x instanceof Array
        out = []
        for v in x
            out.push(deepCopy v)
        return out
    else if x? and typeof x == 'object'
        out = {}
        for k, v of x
            out[k] = deepCopy v
        return out
    else
        return x

arraysEqual = (a, b) ->
    if a instanceof Array and b instanceof Array
        if a.length != b.length
            return false
        for i in [0...a.length]
            if !arraysEqual a[i], b[i]
                return false
        return true
    else
        return a == b

makeArray = (rows, cols, val) ->
    ret = []
    for i in [0...rows]
        row = []
        for j in [0...cols]
            row.push val
        ret.push row
    ret

# Find best fractional approximation by walking the Stern-Brocot tree
# https://stackoverflow.com/a/5128558
approxFraction = (x, error) ->
    n = Math.floor x
    x -= n
    if x < error
        return [n, 1]
    else if 1 - error < x
        return [n+1, 1]
    # The lower fraction is 0/1
    lower_n = 0
    lower_d = 1
    # The upper fraction is 1/1
    upper_n = 1
    upper_d = 1
    while true
        # The middle fraction is (lower_n + upper_n) / (lower_d + upper_d)
        middle_n = lower_n + upper_n
        middle_d = lower_d + upper_d
        # If x + error < middle
        if middle_d * (x + error) < middle_n
            # middle is our new upper
            upper_n = middle_n
            upper_d = middle_d
        # Else If middle < x - error
        else if middle_n < (x - error) * middle_d
            # middle is our new lower
            lower_n = middle_n
            lower_d = middle_d
        # Else middle is our best fraction
        else
            return [n * middle_d + middle_n, middle_d]

# Turn decimals that want to be fractions into fractions
texFraction = (x, error=0.00001) ->
    [num, den] = approxFraction x, error
    if den == 1
        return num.toString()
    minus = if num < 0 then '-' else ''
    num = Math.abs num
    return "#{minus}\\frac{#{num}}{#{den}}"


# This class represents a single animation step
class Step
    constructor: (@rrmat, @stepID, @transform, @transition) ->
        # 'transform' is a function that takes the current state (or the
        # best guess for what that state will be in the future), and returns the
        # new state after the transition happens (but before resizing the matrix
        # elements).  'transition' is the function that actually animates the
        # transition.
        @nextState = null  # Set if and only if the effect is running

    onDone: (callback) ->
        @rrmat.view.on "#{@rrmat.name}.#{@stepID}.done", callback

    go: () =>
        # Stop animations
        mathbox.remove "play.#{@rrmat.name}"
        @nextState = @transform @rrmat.state
        @transition @nextState, @stepID
        @listener = listener = () =>
            @nextState = null
            @rrmat.view.off "#{@rrmat.name}.#{@stepID}.done", listener
        @rrmat.view.on "#{@rrmat.name}.#{@stepID}.done", @listener

    cancel: () =>
        # Stop animation, and return the next state
        return unless @nextState
        @rrmat.view.off "#{@rrmat.name}.#{@stepID}.done", @listener
        ret = @nextState
        @nextState = null
        ret

    fastForward: () =>
        # Skip the rest of this step and reset state to the next state
        return unless @nextState
        @rrmat.newState @cancel()


# Chain several steps together
class Chain extends Step
    constructor: (rrmat, stepID, @steps) ->
        transform = (oldState) =>
            for step in @steps
                oldState = step.transform oldState
            oldState

        super rrmat, stepID, transform, null
        @stepNum = -1  # nonnegative if and only if the effect is running

    goStep: (stepNum) =>
        step = @steps[stepNum]
        @listener = listener = () =>
            @rrmat.view.off "#{@rrmat.name}.#{step.stepID}.done", listener
            nextStep = @steps[stepNum+1]?
            if nextStep
                @goStep stepNum+1
            else
                @stepNum = -1
                event = type: "#{@rrmat.name}.#{@stepID}.done"
                @rrmat.view[0].trigger event
        @rrmat.view.on "#{@rrmat.name}.#{step.stepID}.done", @listener
        @stepNum = stepNum
        step.go()

    go: () =>
        @goStep 0

    cancel: () =>
        return unless @stepNum >= 0
        step = @steps[@stepNum]
        @rrmat.view.off "#{@rrmat.name}.#{step.stepID}.done", @listener
        nextState = step.cancel()
        for i in [@stepNum+1...@steps.length]
            nextState = @steps[i].transform nextState
        @stepNum = -1
        nextState

    fastForward: () =>
        return unless @stepNum >= 0
        @rrmat.newState @cancel()


# This class controls playing steps.  Note that the slideshow's step zero is the
# initial state; it doesn't correspond to a Step.  This means that @states[i] is
# the animation state before @steps[i] runs, and @states[@steps.length] is the
# final state.  The @currentStepNum is an index into @states[] for the current
# state, or, if an animation is playing, the previous state.  Setting the step
# with @goToStep will jump straight to that step.
class Slideshow
    constructor: (@rrmat, @showID='slideshow') ->
        @steps = []
        @states = [@rrmat.state.copy()]
        @currentStepNum = 0
        @playing = false

        @prevButton   = document.querySelector ".slideshow.#{@rrmat.name} .prev-button"
        @reloadButton = document.querySelector ".slideshow.#{@rrmat.name} .reload-button"
        @nextButton   = document.querySelector ".slideshow.#{@rrmat.name} .next-button"
        @pageCounter  = document.querySelector ".slideshow.#{@rrmat.name} .pages"
        @captions = document.querySelectorAll ".slideshow.#{@rrmat.name} .steps > .step"

        @prevButton.onclick = () =>
            return if @currentStepNum == 0 and !@playing
            if @playing
                @goToStep @currentStepNum
            else
                @goToStep @currentStepNum - 1
        @nextButton.onclick = () =>
            return if @currentStepNum == @steps.length
            if @playing
                @goToStep @currentStepNum + 1
            else
                @play()
        @reloadButton.onclick = () =>
            return if @currentStepNum == 0 and !@playing
            if @playing
                @goToStep @currentStepNum
            else
                @goToStep @currentStepNum - 1
            @play()

        @updateUI()

    updateCaptions: (j) ->
        @captions[j].classList.remove 'inactive'
        for caption, i in @captions
            if i != j and !@captions[i].classList.contains 'inactive'
                @captions[i].classList.add 'inactive'

    updateUI: (oldStepNum=-1) =>
        if @currentStepNum == 0 and !@playing
            @prevButton.classList.add 'inactive'
            @reloadButton.classList.add 'inactive'
        else
            @prevButton.classList.remove 'inactive'
            @reloadButton.classList.remove 'inactive'
        if @currentStepNum == @steps.length
            @nextButton.classList.add 'inactive'
        else
            @nextButton.classList.remove 'inactive'
        @pageCounter?.innerHTML = "#{@currentStepNum+1} / #{@steps.length+1}"

    play: () ->
        return if @currentStepNum >= @steps.length
        @playing = true
        @steps[@currentStepNum].go()
        @updateUI()

    goToStep: (stepNum) =>
        return if stepNum < 0 or stepNum > @steps.length
        #console.log "Active step: #{stepNum}"
        oldStepNum = @currentStepNum
        @currentStepNum = stepNum
        if @currentStepNum > oldStepNum and @playing
            @states[oldStepNum+1] = @steps[oldStepNum].fastForward()
            @states[oldStepNum+1].captionNum++
        else if @playing
            @steps[oldStepNum].cancel()
        @rrmat.newState @states[@currentStepNum]
        @updateCaptions @states[@currentStepNum].captionNum
        @playing = false
        @updateUI oldStepNum

    addStep: (steps, opts) ->
        keys = opts.key
        for key in keys
            if @combining?
                @combining.push steps[key]
                continue
            steps[key].opts = opts
            @steps.push steps[key]
            steps[key].onDone () =>
                #console.log "Step #{steps[key].stepID} done"
                @playing = false
                @currentStepNum += 1
                @rrmat.state.captionNum++
                @states[@currentStepNum] = @rrmat.state.copy()
                @updateUI @currentStepNum - 1
                @updateCaptions @rrmat.state.captionNum
        @updateUI()
        @

    stepID: () ->
        if @combining?
            return @showID + '-' + (@steps.length+1) + '-' + (@combining.length+1)
        return @showID + '-' + (@steps.length+1)

    # Combine several steps into a chain.  End with combined()
    combine: () ->
        @combining = []
        @
    combined: (opts) ->
        opts ?= {}
        opts.key = ['chain']
        combining = @combining
        delete @combining
        stepID = @stepID()
        @addStep {chain: new Chain @rrmat, stepID, combining}, opts
        @

    nextCaption: (opts) ->
        # Just run a no-op step
        opts ?= {}
        opts.key ?= ['step']
        transform = (oldState) ->
            nextState = oldState.copy()
            nextState.captionNum++
            nextState
        transition = (nextState, stepID) =>
            @updateCaptions nextState.captionNum
            @rrmat.newState nextState, stepID
        step = new Step @rrmat, @stepID(), transform, transition
        @addStep {step: step}, opts

    rowSwap: (row1, row2, opts) ->
        opts ?= {}
        opts.key ?= ['chain']
        steps = @rrmat.rowSwap @stepID(), row1-1, row2-1, opts
        @addStep steps, opts

    rowMult: (rowNum, factor, opts) ->
        opts ?= {}
        opts.key ?= ['chain']
        steps = @rrmat.rowMult @stepID(), rowNum-1, factor, opts
        @addStep steps, opts

    rowRep: (sourceRow, factor, targetRow, opts) ->
        opts ?= {}
        opts.key ?= ['chain']
        keys = opts?.key or ['chain']
        steps = @rrmat.rowRep @stepID(), sourceRow-1, factor, targetRow-1, opts
        @addStep steps, opts

    unAugment: (opts) ->
        opts ?= {}
        opts.key = ['step']
        step = @rrmat.unAugment @stepID(), opts
        @addStep {step: step}, opts
    reAugment: (opts) ->
        opts ?= {}
        opts.key = ['step']
        step = @rrmat.reAugment @stepID(), opts
        @addStep {step: step}, opts

    setStyle: (transitions, opts) ->
        opts ?= {}
        opts.key = ['step']
        step = @rrmat.setStyle @stepID(), transitions, opts
        @addStep {step: step}, opts


# This class animates a row reduction sequnce on a matrix.
class RRMatrix extends AnimState

    styleKeys: ['color', 'opacity', 'transform']

    constructor: (@numRows, @numCols, opts) ->
        {@name, @fontSize, @rowHeight, @rowSpacing,
            @colSpacing, @augmentCol, startAugmented} = opts or {}

        @name       ?= "rrmat"
        @fontSize   ?= 20
        @rowHeight  ?= @fontSize * 1.2
        @rowSpacing ?= @fontSize
        @colSpacing ?= @fontSize
        @matHeight = @rowHeight * @numRows + @rowSpacing * (@numRows-1)
        startAugmented ?= @augmentCol?

        # VDOM element constructor
        @domClass = MathBox.DOM.createClass \
            render: (el, props, children) =>
                props = deepCopy props
                props.innerHTML  = children
                props.innerHTML += '<span class="baseline-detect"></span>'
                return el('span', props)

        @loaded = false
        @timers = []
        @swapLineSamples = 30

        # Gets set on install
        @matrixElts        = []
        @multFlyerElt      = undefined
        @addFlyerElts      = []
        @rrepParenLeftElt  = undefined
        @rrepParenRightElt = undefined

        mathbox.three.on 'pre', @frame
        mathbox.three.on 'post', @frame
        @clock = mathbox.select('root')[0].clock
        @clock.on 'clock.tick', @multEffect
        @doMultEffect = null
        @clock.on 'clock.tick', @repEffect
        @doRepEffect = null

        ######################################################################
        # Animation state
        ######################################################################

        state = new State @

        # All text element positions go here.  This is because pixel position
        # readback is slow (gl.readPixels is slow).  They are stored as follows:
        #          0  matrix
        #        ...    entry
        #  numRows-1    positions
        #    numRows  multiplication flyer position (first entry)
        #  numRows+1  row replacement row positions
        #  numRows+2  left row replacement paren (first entry)
        #  numRows+3  right row replacement paren (first entry)
        state.addVal
            key:     'positions'
            val:     makeArray @numRows+4, @numCols, [0,0,0]
            copy:    deepCopy
            install: (rrmat, val) => @positions.set 'data', val
        state.positions[@numRows+i][j] = [1000,-1000,0] \
            for i in [0..3] for j in [0...@numCols]

        # The matrix width.  Not manipulated directly; just saved from the
        # calculation of the positions.
        state.addVal key: 'matWidth', val: 0.0

        # The html content of the text elements.  Organized as in 'positions'
        # above.
        state.addVal
            key:  'html'
            val:  makeArray @numRows+4, @numCols, ''
            copy: deepCopy

        # The styles of the text elements.  Organized as in 'positions' above.
        state.addVal
            key:    'styles'
            val:     makeArray @numRows+4, @numCols, {}
            copy:    deepCopy
            install: (rrmat, val) =>
                app = (a, b) ->
                    for k, v of a
                        b[k] = v if b[k] != v
                    null
                # DOM elements get moved on post
                rrmat.onNextFrame 1, () =>
                    for i in [0...@numRows]
                        for j in [0...@numCols]
                            app val[i][j], @matrixElts[i][j].style
                    app val[@numRows][0], @multFlyerElt.style
                    for j in [0...@numCols]
                        app val[@numRows+1][j], @addFlyerElts[j].style
                    app val[@numRows+2][0], @rrepParenLeftElt.style
                    app val[@numRows+3][0], @rrepParenRightElt.style
        empty = {}
        empty[prop] = '' for prop in @styleKeys
        empty.transition = ''
        state.styles[i][j] = deepCopy empty \
            for i in [0..@numRows+3] for j in [0...@numCols]
        for i in [0..3]
            for j in [0...@numCols]
                state.styles[@numRows+i][j].opacity = 0

        # The matrix entries
        state.addVal
            key:  'matrix'
            val:  makeArray @numRows, @rumCols, 0
            copy: deepCopy

        # The matrix bracket line
        state.addVal
            key:     'bracket'
            val:     makeArray 4, 2, 0
            copy:    deepCopy
            install: (rrmat, val) => @bracket.set 'data', val

        # The arrow for row swaps
        state.addVal
            key:     'swapLine'
            val:     makeArray @swapLineSamples+1, 2, 0
            copy:    deepCopy
            install: (rrmat, val) => @swapLine.set 'data', val
        state.addVal
            key:     'swapOpacity'
            val:     0.0
            install: (rrmat, val) => @swapLineGeom.set 'opacity', val

        # The augmentation line
        state.addVal
            key:     'augment'
            val:     [[0,0],[0,0]]
            copy:    deepCopy
            install: (rrmat, val) => @augment.set 'data', val
        state.addVal
            key: 'doAugment'
            val: startAugmented

        # For slideshows
        state.addVal
            key: 'captionNum'
            val: 0

        super state

    _id: (element) => "#{@name}-#{element}"

    _measureWidth: (html, fromElement) ->
        if !@measurer?
            div = document.createElement 'div'
            div.style.position  = 'absolute'
            div.style.left      = '0px'
            div.style.top       = '0px'
            div.style.width     = '0px'
            div.style.height    = '0px'
            document.body.appendChild div
            span = document.createElement 'span'
            span.id = 'width-measurer'
            span.style.whiteSpace  = 'nowrap'
            span.style.padding     = '0px'
            span.style.border      = 'none'
            span.style.visibility  = 'hidden'
            div.appendChild span
            @measurer = span
        else
            span = @measurer
        div = span.parentElement
        style = document.defaultView.getComputedStyle fromElement
        span.style.fontStyle   = style.getPropertyValue 'font-style'
        span.style.fontVariant = style.getPropertyValue 'font-variant'
        span.style.fontWeight  = style.getPropertyValue 'font-weight'
        span.style.fontSize    = style.getPropertyValue 'font-size'
        span.style.fontFamily  = style.getPropertyValue 'font-family'
        span.innerHTML = html
        width = span.getBoundingClientRect().width
        return width

    computePositions: (state) =>
        # Compute positions of DOM elements, brackets, augment line, matrix
        # width
        state = state.copy()
        state.matWidth = 0
        colWidths = []

        # Compute column widths
        for j in [0...@numCols]
            max = 0
            for i in [0...@numRows]
                elt = @matrixElts[i][j]
                width = @_measureWidth state.html[i][j], elt
                max = Math.max max, width
            colWidths.push max
            state.matWidth += max
        state.matWidth += 3 * @colSpacing
        state.matWidth += @colSpacing/2 if state.doAugment

        # Compute entry positions
        y = -@matHeight / 2 + @rowHeight
        for i in [0...@numRows]
            x = -state.matWidth / 2
            rowPos = []
            for j in [0...@numCols]
                x += colWidths[j]/2
                state.positions[i][j][0] = x
                state.positions[i][j][1] = -y
                x += colWidths[j]/2
                x += @colSpacing
                if @augmentCol? and @augmentCol == j and state.doAugment
                    x -= @colSpacing/4
                    state.augment = [[x, 0], [x, 0]]
                    x += 3*@colSpacing/4
            y += @rowHeight + @rowSpacing

        # Compute bracket path
        x1 = -state.matWidth/2 - @colSpacing + 7
        x2 = -state.matWidth/2 - @colSpacing
        y1 = @matHeight / 2
        y2 = -(@matHeight + @fontSize) / 2
        state.bracket = [[x1,y1], [x2,y1], [x2,y2], [x1,y2]]
        # Augment path
        state.augment[0][1] = y1
        state.augment[1][1] = y2
        if @augmentCol? and (not state.doAugment or @addingAugment)
            diff = @view.get('scale').y
            state.augment[0][1] += diff
            state.augment[1][1] += diff

        state

    resize: (stepID) =>
        nextState = @computePositions @state
        @state.matWidth = nextState.matWidth

        equal = true
        for i in [0...@numRows]
            for j in [0...@numCols]
                for k in [0...1]
                    if nextState.positions[i][j][k] != @state.positions[i][j][k]
                        equal = false
                    break if not equal
                break if not equal
            break if not equal
        if not equal
            play1 = @play @positions,
                script:
                    0:   props: data: @state.positions
                    0.2: props: data: nextState.positions
            @state.positions = nextState.copyVal 'positions'

        if !arraysEqual nextState.bracket, @state.bracket
            play2 = @play @bracket,
                script:
                    0:   props: data: @state.bracket
                    0.2: props: data: nextState.bracket
            @state.bracket = nextState.copyVal 'bracket'

        if @augmentCol? and not arraysEqual nextState.augment, @state.augment
            play3 = @play @augment,
                script:
                    0:   props: data: @state.augment
                    0.2: props: data: nextState.augment
            @state.augment = nextState.copyVal 'augment'

        event = type: "#{@name}.#{stepID}.done"
        play1?.on 'play.done', (e) =>
            play1.remove()
            @state.installVal 'positions'
            @view[0].trigger event if stepID
        play2?.on 'play.done', (e) =>
            play2.remove()
            @state.installVal 'bracket'
            if !play1? and stepID
                @view[0].trigger event
        play3?.on 'play.done', (e) =>
            play3.remove()
            @state.installVal 'augment'
            if !play1? and !play2? and stepID
                @view[0].trigger event
        @view[0].trigger event if !play1? and !play2? and !play3? and stepID
        @state

    newState: (nextState, stepID) =>
        # Stop/delete any animations
        mathbox.remove "play.#{@name}"
        super nextState
        # Clear timers
        clearTimeout timer for timer in @timers
        @timers = []
        # Clean up opacity effects
        @doMultEffect = null
        @doRepEffect = null
        mathbox.select('#' + @_id('dom')).set('opacity', 1)
        mathbox.select('#' + @_id('bracketLeft')).set('opacity', 1)
        mathbox.select('#' + @_id('bracketRight')).set('opacity', 1)
        mathbox.select('#' + @_id('augmentGeom')).set('opacity', 1)
        @resize stepID

    play: (element, opts) ->
        # Thin wrapper around mathbox.play
        return unless @view?
        id = "#{@name}-play-#{element[0].id}"
        mathbox.remove "#" + id
        opts.target  = element
        opts.id      = id
        opts.classes = [@name]
        opts.to     ?= Math.max.apply null, (k for k of opts.script)
        play = @view.play opts
        # Don't auto-remove, as there may be other listeners for play.done
        play

    fade: (element, script) ->
        # Fade an element in or out
        script2 = {}
        script2[k] = {props: {opacity: v}} for k, v of script
        @play element,
            ease:   'linear'
            script: script2

    onNextFrame: (after, callback, stage='post') ->
        # Execute 'callback' after 'after' frames
        @nextFrame ?= {}
        @nextFrame[stage] ?= {}
        time = mathbox.three.Time.frames + (after-1)
        @nextFrame[stage][time] ?= []
        @nextFrame[stage][time].push(callback)
    frame: (event) =>
        return unless @nextFrame?[event.type]?
        frames = mathbox.three.Time.frames
        for f, callbacks of @nextFrame[event.type]
            if f < frames
                delete @nextFrame[event.type][f]
                callback() for callback in callbacks

    onLoaded: (callback) ->
        @view?[0].on "#{@name}.loaded", callback

    htmlMatrix: (matrix, html) =>
        # Render matrix in html
        html[i][j] = katex.renderToString(texFraction matrix[i][j]) \
            for i in [0...@numRows] for j in [0...@numCols]
        html

    install: (@view) ->
        @positions = @view.matrix
            data:     @state.positions,
            width:    @numCols
            height:   @numRows+4
            channels: 3
            classes:  [@name]
            id:       @_id 'positions'

        html = @view.html
            width:   @numCols
            height:  @numRows+4
            classes: [@name]
            live:    true

        @htmlMatrix @state.matrix, @state.html

        # Static HTML element attributes.  (Only style changes.)
        htmlProps = makeArray @numRows+4, @numCols, {}
        for i in [0...@numRows]
            for j in [0...@numCols]
                htmlProps[i][j] =
                    id:        @_id "#{i}-#{j}"
                    className: "#{@name} bound-entry matrix-entry"
        htmlProps[@numRows][0] =
            id: @_id 'multFlyer'
            className: "#{@name} bound-entry mult-flyer"
        for j in [0...@numCols]
            htmlProps[@numRows+1][j] =
                id: @_id("addFlyer-#{j}")
                className: "#{@name} bound-entry add-flyer"
        htmlProps[@numRows+2][0] =
            id: @_id 'rrepParenLeft'
            className: "#{@name} bound-entry rrep-factor"
        htmlProps[@numRows+3][0] =
            id: @_id 'rrepParenRight'
            className: "#{@name} bound-entry rrep-factor"
        for i in [@numRows, @numRows+2, @numRows+3]
            for j in [1...@numCols]
                htmlProps[i][j] =
                    style: display: 'none'
                    className: @name
        @test = htmlProps

        html.set expr: (emit, el, j, i) =>
                emit(el @domClass, htmlProps[i][j], @state.html[i][j])

        @view.dom
            snap:    false
            offset:  [0,0]
            depth:   0
            zoom:    1
            outline: 0
            size:    @fontSize
            classes: [@name]
            id:      @_id 'dom'
            opacity: 0  # Becomes visible when DOM elements are loaded
            attributes: style: height: "0px"

        # Brackets
        @bracket = @view.array
            channels: 2
            width:    4
            classes:  [@name]
            id:       @_id 'bracket'
            data:     @state.bracket
        @view.line
            color:   "black"
            width:   2
            classes: [@name]
            id:      @_id 'bracketLeft'
            opacity: 0
        .transform
            scale:   [-1, 1, 1]
            classes: [@name]
        .line
            color:   "black"
            width:   2
            classes: [@name]
            id:      @_id 'bracketRight'
            opacity: 0

        # Augmentation line
        @augment = @view.array
            channels: 2
            width:    2
            classes:  [@name]
            id:       @_id 'augment'
            data:     @state.augment
        @augmentGeom = @view.line
            color:   "black"
            width:   1
            classes: [@name]
            id:      @_id 'augmentGeom'
            opacity: 0

        # Swap-points arrow
        @swapLine = @view.array
            channels: 2
            width:    @swapLineSamples + 1
            classes:  [@name]
            id:       @_id 'swapLine'
            data:     @state.swapLine

        @swapLineGeom = @view.line
            color:   "green"
            width:   4
            start:   true
            end:     true
            opacity: 0
            id:      @_id 'swapLineGeom'
            classes: [@name]

        # This gets run once after the DOM elements are added
        @onNextFrame 1, () =>
            @alignBaselines()
            # Save all bound elements
            for i in [0...@numRows]
                row = []
                for j in [0...@numCols]
                    row.push document.getElementById("#{@name}-#{i}-#{j}")
                @matrixElts.push row
            @multFlyerElt = document.getElementById(@_id 'multFlyer')
            for j in [0...@numCols]
                @addFlyerElts.push document.getElementById(@_id "addFlyer-#{j}")
            @rrepParenLeftElt  = document.getElementById(@_id 'rrepParenLeft')
            @rrepParenRightElt = document.getElementById(@_id 'rrepParenRight')

        @onNextFrame 9, () => @resize()
        @onNextFrame 10, () =>
            @fade mathbox.select('#' + @_id('dom')), {0: 0, .3: 1}
            @fade mathbox.select('#' + @_id('bracketLeft')), {0: 0, .3: 1}
            @fade mathbox.select('#' + @_id('bracketRight')), {0: 0, .3: 1}
            @fade mathbox.select('#' + @_id('augmentGeom')), {0: 0, .3: 1}
            @loaded = true
            @view[0].trigger type: "#{@name}.loaded"

        # This runs on DOM element updates
        observer = new MutationObserver (mutations) =>
            for mutation in mutations
                continue unless mutation.target.classList.contains 'bound-entry'
                @alignBaselines mutation.target.getElementsByClassName 'baseline-detect'
        observer.observe document.getElementById('mathbox'),
               childList:     true
               subtree:       true
        @

    setMatrix: (matrix) ->
        @state.matrix = matrix
        @htmlMatrix @state.matrix, @state.html
        @resize() if @loaded

    alignBaselines: (elts) =>
        # Align baselines with the reference points (javascript hack)
        elts ?= document.querySelectorAll ".#{@name} > .baseline-detect"
        for elt in elts
            elt.parentElement.style.top = -elt.offsetTop + "px"

    ######################################################################
    # Transitions and helper functions
    ######################################################################

    slideshow: (showID='slideshow') ->
        new Slideshow @, showID

    chain: (stepID, steps...) ->
        ret = new Chain @, stepID, steps
        ret

    swapLinePoints: (top, bot, state) ->
        # Get points for the swap-arrows line
        samples = @swapLineSamples
        lineHeight = Math.abs(top - bot)
        center = (top + bot) / 2
        points = ([Math.sin(π * i/samples) * @colSpacing * 3 +
                      state.matWidth/2 + @colSpacing + 2,
                   Math.cos(π * i/samples) * lineHeight/2 + center] \
                  for i in [0..samples])
        return points

    rowSwap: (stepID, row1, row2, opts) ->
        # Return an animation in two steps.
        # The first step fades in the swap arrow.
        # The second step does the swap.

        speed = opts?.speed or 1.0
        fadeTime = 0.3/speed
        swapTime = 1/speed

        transform1 = (oldState) =>
            nextState = oldState.copy()
            nextState.swapOpacity = 1.0
            top = nextState.positions[row1][0][1] + @fontSize/3
            bot = nextState.positions[row2][0][1] + @fontSize/3
            nextState.swapLine = @swapLinePoints top, bot, nextState
            return nextState

        transition1 = (nextState, stepID) =>
            nextState.installVal 'swapLine'
            script = {}
            script[0] = 0
            script[fadeTime] = 1
            @fade @swapLineGeom, script
                .on 'play.done', (e) => @newState nextState, stepID

        transform2 = (oldState) =>
            nextState = oldState.copy()
            [nextState.matrix[row1], nextState.matrix[row2]] =
                [nextState.matrix[row2], nextState.matrix[row1]]
            [nextState.styles[row1], nextState.styles[row2]] =
                [nextState.styles[row2], nextState.styles[row1]]
            [nextState.html[row1], nextState.html[row2]] =
                [nextState.html[row2], nextState.html[row1]]
            nextState.swapOpacity = 0.0
            return nextState

        transition2 = (nextState, stepID) =>
            pos = deepCopy @state.positions
            [pos[row1], pos[row2]] = [pos[row2], pos[row1]]

            @play @positions,
                pace: swapTime
                script:
                    0: props: data: @state.positions
                    1: props: data: pos

            top = @state.swapLine[0][1]
            bot = @state.swapLine[@swapLineSamples][1]
            center = (top + bot) / 2
            transLine = ([x,-y+2*center] for [x,y] in @state.swapLine)

            @play @swapLine,
                pace: swapTime
                script:
                    0: props: data: @state.swapLine
                    1: props: data: transLine

            script = {}
            script[0] = 1
            script[swapTime] = 1
            script[swapTime+fadeTime] = 0
            @fade @swapLineGeom, script
                .on 'play.done', (e) => @newState nextState, stepID

        step1 = new Step @, "#{stepID}-1", transform1, transition1
        step2 = new Step @, "#{stepID}-2", transform2, transition2

        step1: step1
        step2: step2
        chain: new Chain @, stepID, [step1, step2]

    multEffect: () =>
        # Fade numbers in and out when multiplying
        return unless @doMultEffect
        {rowNum, rowPos, past, clock, speed,
            stepNum, stepID, opacity, start, nextState} = @doMultEffect
        return if stepNum > 2
        row = @matrixElts[rowNum]
        elapsed = clock.getTime().clock - start
        elapsed *= speed
        if stepNum == 1
            if elapsed >= 0.3
                @multFlyerElt.style.opacity = 1
                @doMultEffect.stepNum = 3
                @onNextFrame 1, () => @newState nextState, stepID
            else
                @multFlyerElt.style.opacity = elapsed/0.3
            return
        # stepNum == 2
        box = @multFlyerElt.getBoundingClientRect()
        flyerPos = (box.left + box.right) / 2
        for elt, i in row
            if flyerPos < rowPos[i] and !past[i]
                # Change the number as the flyer flies past
                past[i] = true
                @state.html[rowNum][i] = nextState.html[rowNum][i]
            elt.style.opacity = opacity(Math.abs(flyerPos - rowPos[i]))
        if past[0]
            # Fade out the flyer
            @multFlyerElt.style.opacity =
                Math.max(1 - (rowPos[0] - flyerPos)/@fontSize/5, 0)
            if @multFlyerElt.style.opacity < 0.05
                @onNextFrame 1, () => @newState nextState, stepID
                @doMultEffect.stepNum = 3

    rowMult: (stepID, rowNum, factor, opts) ->
        # Return an animation in two steps
        # The first step fades in the multiplication flyer
        # The second step does the multiplication
        speed = opts?.speed or 1.0

        precomputations = (doMultEffect) =>
            # Put the flyer text to the right of the reference point
            @multFlyerElt.parentElement.style.width = "0px"
            pos = []
            past = []
            for elt in @matrixElts[rowNum]
                box = elt.getBoundingClientRect()
                pos.push (box.left + box.right) / 2
                past.push false
            doMultEffect.rowPos = pos
            doMultEffect.past   = past
            doMultEffect.start  = doMultEffect.clock.getTime().clock

        doMultEffect =
                rowNum:  rowNum
                clock:   @positions[0].clock
                opacity: (distance) => Math.min (distance/(@fontSize*2))**3, 1
                speed:   speed

        transform1 = (oldState) =>
            nextState = oldState.copy()
            nextState.styles[@numRows][0].opacity = 1
            nextState.html[@numRows][0] =
                katex.renderToString('\\times' + texFraction(factor))
            startX = nextState.matWidth/2 + @colSpacing + 10
            rowY = nextState.positions[rowNum][0][1]
            nextState.positions[@numRows][0] = [startX, rowY, 10]
            nextState

        transition1 = (nextState, stepID) =>
            @doMultEffect = doMultEffect
            precomputations @doMultEffect
            @doMultEffect.nextState = nextState
            @doMultEffect.stepID    = stepID
            @doMultEffect.stepNum   = 1
            nextState.installVal 'positions'
            @state.html[@numRows][0] = nextState.html[@numRows][0]

        transform2 = (oldState) =>
            nextState = oldState.copy()
            nextState.matrix[rowNum] = (r * factor for r in nextState.matrix[rowNum])
            @htmlMatrix nextState.matrix, nextState.html
            nextState.styles[@numRows][0].opacity = 0
            rowY = @state.positions[rowNum][0][1]
            nextState.positions[@numRows][0] = [-nextState.matWidth*2, rowY, 10]
            nextState

        transition2 = (nextState, stepID) =>
            @doMultEffect = doMultEffect
            precomputations @doMultEffect
            @doMultEffect.nextState = nextState
            @doMultEffect.stepID    = stepID
            @doMultEffect.stepNum   = 2

            @play @positions,
                speed: speed
                script:
                    0:    props: data: @state.positions
                    1.75: props: data: nextState.positions

        step1 = new Step @, "#{stepID}-1", transform1, transition1
        step2 = new Step @, "#{stepID}-2", transform2, transition2

        step1: step1
        step2: step2
        chain: new Chain @, stepID, [step1, step2]

    repEffect: () =>
        # Opacity effects for row replacement
        return unless @doRepEffect
        {start, clock, speed,
            targetRow, opacity, nextState, stepID, stepNum} = @doRepEffect
        return if stepNum > 2
        elapsed = clock.getTime().clock - start
        elapsed *= speed
        row = @matrixElts[targetRow]
        if stepNum == 1
            if elapsed < 0.3
                # Fade in the parentheses
                @rrepParenLeftElt.style.opacity = elapsed / 0.3
                @rrepParenRightElt.style.opacity = elapsed / 0.3
            else if elapsed < 1.5
                @rrepParenLeftElt.style.opacity = 1
                @rrepParenRightElt.style.opacity = 1
            else
                @doRepEffect.stepNum = 3
                @onNextFrame 1, () => @newState nextState, stepID
            return
        # stepNum == 2
        if elapsed < 1.5
            # Decrease opacity of flyer and row as the former covers the latter
            right = row[@numCols-1].getBoundingClientRect().right
            for elt in @addFlyerElts
                pos = elt.getBoundingClientRect().left
                elt.style.opacity = opacity(pos - right)
            left = @rrepParenLeftElt.getBoundingClientRect().left
            for elt in row
                pos = elt.getBoundingClientRect().right
                elt.style.opacity = opacity(left - pos)
            return
        elapsed -= 1.5
        if elapsed < 0.3
            for elt in @addFlyerElts
                elt.style.opacity = 0.5 - elapsed/(2*0.3)
            for elt in row
                elt.style.opacity = 0.5 - elapsed/(2*0.3)
            @rrepParenLeftElt.style.opacity = 1 - elapsed/0.3
            @rrepParenRightElt.style.opacity = 1 - elapsed/0.3
            return
        for elt in @addFlyerElts
            elt.style.opacity = 0
        @rrepParenLeftElt.style.opacity = 0
        @rrepParenRightElt.style.opacity = 0
        elapsed -= 0.3
        if elapsed < 0.3
            for i in [0...@numCols]
                @state.html[targetRow][i] = nextState.html[targetRow][i]
            for elt in row
                elt.style.opacity = elapsed/0.3
            return
        @doRepEffect.stepNum = 3
        @onNextFrame 1, () => @newState nextState, stepID

    rowRep: (stepID, sourceRow, factor, targetRow, opts) ->
        # Return an animation in two steps
        # The first step moves the row flyer into place
        # The second step does the row replacement
        speed = opts?.speed or 1.0
        plus = if factor >= 0 then '+' else ''
        texString = katex.renderToString(plus + texFraction(factor) + '\\,\\bigl(')
        leftParenWidth = @_measureWidth texString, @rrepParenLeftElt
        padding = 7

        precomputations = (doRepEffect) =>
            doRepEffect.start = doRepEffect.clock.getTime().clock

        # Opacity effects
        doRepEffect =
            clock:     @positions[0].clock
            targetRow: targetRow
            speed:     speed
            opacity:   (right) =>
                return 0.5 if right < 0
                Math.max(0.5, Math.min (right/(@fontSize)), 1)

        transform1 = (oldState) =>
            nextState = oldState.copy()
            nextState.html[@numRows+2][0] = texString
            nextState.html[@numRows+3][0] = katex.renderToString('\\bigr)')

            # Initialize row replacement factor
            rowY = nextState.positions[targetRow][0][1]
            matWidth = nextState.matWidth + padding*2
            leftParenX = nextState.matWidth/2 + @colSpacing + 10
            nextState.positions[@numRows+2][0][0] = leftParenX
            nextState.positions[@numRows+2][0][1] = rowY
            nextState.positions[@numRows+2][0][2] = 5
            nextState.positions[@numRows+3][0][0] =
                leftParenX + leftParenWidth + matWidth
            nextState.positions[@numRows+3][0][1] = rowY
            nextState.positions[@numRows+3][0][2] = 5
            nextState.styles[@numRows+2][0].opacity = 1
            nextState.styles[@numRows+3][0].opacity = 1

            # Initialize row flyer
            offsetX = nextState.matWidth + @colSpacing + 10 + leftParenWidth + padding
            nextState.styles[@numRows+1]    = deepCopy nextState.styles[sourceRow]
            nextState.html[@numRows+1]      = deepCopy nextState.html[sourceRow]
            nextState.positions[@numRows+1] = deepCopy nextState.positions[sourceRow]
            for i in [0...@numCols]
                nextState.styles[@numRows+1][i].opacity = 1
                nextState.positions[@numRows+1][i][0] += offsetX
                nextState.positions[@numRows+1][i][1] = rowY
                nextState.positions[@numRows+1][i][2] = 10

            nextState

        transition1 = (nextState, stepID) =>
            @state.html = nextState.html
            tmpState = nextState.copy()
            tmpState.styles[@numRows+2][0].opacity = 0
            tmpState.styles[@numRows+3][0].opacity = 0
            tmpState.installVal 'styles'
            for elt in [@rrepParenLeftElt, @rrepParenRightElt]
                # Put these to the right of the reference point
                elt.parentElement.style.width = "0px"
            @state.positions[@numRows+1]    = @state.positions[sourceRow]
            @state.positions[@numRows+2][0] = nextState.positions[@numRows+2][0]
            @state.positions[@numRows+3][0] = nextState.positions[@numRows+3][0]

            @play @positions,
                speed: speed
                script:
                    0.0: props: data: @state.positions
                    1.5: props: data: nextState.positions

            @doRepEffect = doRepEffect
            precomputations @doRepEffect
            @doRepEffect.nextState = nextState
            @doRepEffect.stepID    = stepID
            @doRepEffect.stepNum   = 1
            @repEffect()

        transform2 = (oldState) =>
            nextState = oldState.copy()
            for i in [0...@numCols]
                nextState.matrix[targetRow][i] +=
                    factor * nextState.matrix[sourceRow][i]
            @htmlMatrix nextState.matrix, nextState.html
            offsetX = nextState.matWidth + @colSpacing + 10 + leftParenWidth + padding
            for i in [0...@numCols]
                nextState.styles[@numRows+1][i].opacity = 0
                nextState.positions[@numRows+1][i][0] -= offsetX
            nextState.positions[@numRows+2][0][0] -= offsetX
            nextState.positions[@numRows+3][0][0] -= offsetX
            nextState.styles[@numRows+2][0].opacity = 0
            nextState.styles[@numRows+3][0].opacity = 0
            nextState

        transition2 = (nextState, stepID) =>
            @play @positions,
                speed: speed
                script:
                    0.0: props: data: @state.positions
                    1.5: props: data: nextState.positions

            @doRepEffect = doRepEffect
            precomputations @doRepEffect
            @doRepEffect.nextState = nextState
            @doRepEffect.stepID    = stepID
            @doRepEffect.stepNum   = 2

        step1 = new Step @, "#{stepID}-1", transform1, transition1
        step2 = new Step @, "#{stepID}-2", transform2, transition2

        step1: step1
        step2: step2
        chain: new Chain @, stepID, [step1, step2]

    _onoffAugment: (stepID, isOn, opts) ->
        speed = opts?.speed or 1.0

        transform = (oldState) =>
            nextState = oldState.copy()
            nextState.doAugment = isOn
            if isOn
                nextState = @computePositions nextState
            else
                diff = @view.get('scale').y
                nextState.augment[0][1] += diff
                nextState.augment[1][1] += diff
            return nextState

        transition = (nextState, stepID) =>
            if isOn
                # First make room for the augment line
                @state.doAugment = true
                @addingAugment = true
                @resize()
                @addingAugment = false
            @play @augment,
                speed: speed
                delay: if isOn then 0.2 else 0
                script:
                    0:   props: data: @state.augment
                    0.5: props: data: nextState.augment
            .on 'play.done', (e) => @newState nextState, stepID

        new Step @, stepID, transform, transition

    unAugment: (stepID, opts) ->
        @_onoffAugment stepID, false, opts
    reAugment: (stepID, opts) ->
        @_onoffAugment stepID, true, opts

    _setStyle: (i, j, trans) ->
        if trans.duration
            transition =
                ("#{p} #{trans.duration}s #{trans.timing}" for p in trans.props)
                .join(', ')
        else
            transition = ""
        style = transition: transition
        for prop in trans.props
            style[prop] = trans[prop]
        elt = @matrixElts[i][j]
        for k, v of style
            elt.style[k] = v

    # 'transitions' is a list of style transitions.  Each transition is an
    # object with the following keys:
    #   color, opacity, transformation, ...: specify the new property value
    #   entries:  a list of [i,j] matrix entries
    #   duration: transition time, in seconds
    #   delay:    delay time, in seconds (default 0)
    #   timing:   easing function (default 'ease')
    setStyle: (stepID, transitions, opts) ->
        speed = opts?.speed or 1.0
        # Total time of the effect
        totalTime = 0
        if not (transitions instanceof Array)
            transitions = [transitions]
        for trans in transitions
            trans.duration  /= speed
            trans.delay ?= 0.0
            trans.delay /= speed
            trans.timing ?= 'ease'
            totalTime = Math.max totalTime, trans.duration + trans.delay
            trans.props = []
            for prop in @styleKeys
                trans.props.push prop if trans[prop]?

        transform = (oldState) =>
            nextState = oldState.copy()
            # Compute final matrix entry styles
            for i in [0...@numRows]
                for j in [0...@numCols]
                    last = 0.0
                    style = {}
                    for trans in transitions
                        if trans.delay >= last
                            for ent in trans.entries
                                if ent[0] == i and ent[1] == j
                                    for prop in trans.props
                                        style[prop] = trans[prop]
                                    last = trans.delay
                                    break
                    for k, v of style
                        nextState.styles[i][j][k] = v
            nextState

        transition = (nextState, stepID) =>
            for trans in transitions
                callback = do (trans) => () =>
                    for entry in trans.entries
                        @_setStyle entry[0], entry[1], trans
                    null
                if trans.delay == 0
                    # Give colors a chance to reset
                    @onNextFrame 1, callback
                else
                    timer = setTimeout callback, trans.delay*1000
                    @timers.push timer
            callback = () =>
                @newState nextState, stepID
            timeout = setTimeout callback, totalTime*1000
            @timers.push timeout

        new Step @, stepID, transform, transition

window.RRMatrix = RRMatrix
