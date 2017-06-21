"use strict"

# TODO: Make this interactive!!!  The student can do their own row reduction.

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
    if a instanceof Array && b instanceof Array
        if a.length != b.length
            return false
        for i in [0...a.length]
            if !arraysEqual a[i], b[i]
                return false
        return true
    else
        return a == b

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
        # 'transform' is a function that takes the current animState (or the
        # best guess for what that state will be in the future), and returns the
        # new state after the transition happens (but before resizing the matrix
        # elements).  'transition' is the function that actually animates the
        # transition.
        @nextState = null  # Set if and only if the effect is running

    go: () =>
        @nextState = @transform(@rrmat.animState)
        @transition @nextState, @stepID
        @listener = listener = () =>
            @nextState = null
            @rrmat.view.off "#{@rrmat.name}.#{@stepID}.done", listener
            console.log "Step #{@stepID} done"
        @rrmat.view.on "#{@rrmat.name}.#{@stepID}.done", @listener

    cancel: () =>
        # Stop animation, and return the next state
        return unless @nextState
        @rrmat.view.off "#{@rrmat.name}.#{@stepID}.done", @listener
        ret = @nextState
        @nextState = null
        ret

    fastForward: () =>
        # Skip the rest of this step and reset animState to the next state
        return unless @nextState
        @rrmat.newState @cancel()

# Chain several steps together
class Chain extends Step
    constructor: (rrmat, stepID, @steps...) ->
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


# This class animates a row reduction sequnce on a matrix.
class RRMatrix

    constructor: (@numRows, @numCols, opts) ->
        {@name, @fontSize, @rowHeight, @rowSpacing, @colSpacing} = opts? || {}

        @name       ?= "rrmat"
        @fontSize   ?= 20
        @rowHeight  ?= @fontSize * 1.2
        @rowSpacing ?= @fontSize
        @colSpacing ?= @fontSize

        @matHeight = @rowHeight * @numRows + @rowSpacing * (@numCols-1)

        @domClass = MathBox.DOM.createClass render:
            (el, props, children) =>
                props.innerHTML = katex.renderToString(children)
                props.innerHTML += '<span class="baseline-detect"></span>'
                if props.i? && props.j?
                    props.id = "#{@name}-#{props.i}-#{props.j}"
                    props.className =
                        "#{@name}-col-#{props.j}" +
                        " #{@name}-row-#{props.i}" +
                        " #{@name} bound-entry #{@name}-matrix-entry"
                    delete props.i
                    delete props.j
                else
                    otherClasses = if props.className? then ' ' + props.className else ''
                    props.className = "#{@name} bound-entry" + otherClasses
                return el('span', props)

        @swapLineSamples = 30
        mathbox.three.on 'pre', @frame
        mathbox.three.on 'post', @frame

        @animState =
            # All text element positions go hear.  This is because pixel
            # position readback is slow (gl.readPixels is slow).
            # First come the matrix entries.  The next row only uses the first
            # entry, which is the multiplication flyer position.  The next row
            # is the row addition flyer.  The next two rows are the opening and
            # closing parens for the row replacement multiplication factor.
            positions: []
            # These are the contents of the DOM entries, in the order described
            # above.
            html: [] # Set in @install()
            # Matrix entries (as decimal numbers)
            matrix: []
            # Matrix width
            matWidth: 0
            # Bracket path
            bracket: []
            # Swap line position and opacity
            swapLine: []
            swapOpacity: 0.0
            # Multiplication factor opacity
            multOpacity: 0.0
            # Row replacement factor opacity
            rrepOpacity: 0.0
            rrepParenOpacity: 0.0

        # Zero out the original matrix
        @animState.matrix =
            (Array.apply(null, Array @numCols).map Number.prototype.valueOf, 0 \
                for [0...@numRows])

        [positions, @animState.bracket, @animState.matWidth] = @computePositions()
        for j in [0..@numRows+3]
            @animState.positions[j] = []
            @animState.positions[j][i] = [1000,-1000,0] for i in [0...@numCols]
        @animState.positions =
            @_insertMatrixPositions positions, @animState.positions
        @animState.swapLine = @swapLinePoints 100, -100

        mathbox.select('root')[0].clock.on 'clock.tick', @multEffect
        @doMultEffect = null
        mathbox.select('root')[0].clock.on 'clock.tick', @repEffect
        @doRepEffect = null

    _id: (element) => "#{@name}-#{element}"

    # We have to keep the matrix positions inside a larger matrix, so...
    _insertMatrixPositions: (matPos, allPos) ->
        allPos = deepCopy allPos
        allPos[i][j][k] = row[j][k] for row, i in matPos \
            for j in [0...@numCols] for k in [0,1]
        allPos
    _extractMatrixPositions: (allPos) ->
        [allPos[i][j][0], allPos[i][j][1]] \
            for j in [0...@numCols] for i in [0...@numRows]

    computePositions: () =>
        #console.log "recomputing matrix sizes..."
        positions = []
        bracket = []
        matWidth = 0
        colWidths = []

        # Compute column widths
        for j in [0...@numCols]
            col = document.getElementsByClassName "#{@name}-col-#{j}"
            max = @fontSize # default / minimum width
            for elt in col
                max = Math.max max, elt.getBoundingClientRect().width
            colWidths.push max
            matWidth += max
        matWidth += 3 * @colSpacing

        # Compute entry positions
        y = -@matHeight / 2 + @rowHeight
        for i in [0...@numRows]
            x = -matWidth / 2
            rowPos = []
            for j in [0...@numCols]
                x += colWidths[j]/2
                rowPos.push [x,-y]
                x += colWidths[j]/2
                x += @colSpacing
            y += @rowHeight + @rowSpacing
            positions.push rowPos

        # Compute bracket path
        x1 = -matWidth/2 - @colSpacing + 7
        x2 = -matWidth/2 - @colSpacing
        y1 = @matHeight / 2
        y2 = -(@matHeight + @fontSize) / 2
        bracket = [[x1,y1], [x2,y1], [x2,y2], [x1,y2]]

        return [positions, bracket, matWidth]

    resize: (stepID) =>
        oldWidth = @animState.matWidth
        [positions, bracket, @animState.matWidth] = @computePositions()
        if !arraysEqual positions, @_extractMatrixPositions @animState.positions
            @animState.positions =
                @_insertMatrixPositions positions, @animState.positions
            # Move stuff to the right or left if necessary
            if oldWidth != @animState.matWidth
                diff = @animState.matWidth - oldWidth
                if @animState.swapOpacity > 0
                    @animState.swapLine[i][0] += diff \
                        for i in [0..@swapLineSamples]
                if @animState.multOpacity > 0
                    @animState.positions[@numRows][0][0] += diff
                if @animState.rrepOpacity > 0
                    @animState.positions[@numRows+1][i][0] += diff \
                        for i in [0...@numCols]
                if @animState.rrepParenOpacity > 0
                    @animState.positions[@numRows+j][0][0] += diff \
                        for j in [@numRows+2..@numRows+3]
            play1 = @play @positions,
                script:
                    0:   {props: {data: Array.from @positions.get 'data'}}
                    0.2: {props: {data: @animState.positions}}
        if !arraysEqual bracket, @animState.bracket
            @animState.bracket = bracket
            play2 = @play @bracket,
                script:
                    0:   {props: {data: Array.from @bracket.get 'data'}}
                    0.2: {props: {data: bracket}}
        event = type: "#{@name}.#{stepID}.done"
        play1?.on 'play.done', (e) =>
            play1.remove()
            @positions.set 'data', @animState.positions
            @view[0].trigger event if stepID
        play2?.on 'play.done', (e) =>
            play2.remove()
            @bracket.set 'data', @animState.bracket
            if !play1? && stepID
                @view[0].trigger event
        @view[0].trigger event if !play1? && !play2? && stepID

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
        @nextFrame[stage][mathbox.three.Time.frames + (after-1)] = callback
    frame: (event) =>
        return unless @nextFrame?[event.type]?
        frames = mathbox.three.Time.frames
        for f, callback of @nextFrame[event.type]
            if f < frames
                delete @nextFrame[event.type][f]
                callback()

    newState: (nextState, stepID) =>
        # Set all displayed elements to a new state
        # Trigger an event when finished
        @animState = nextState
        # Stop/delete any animations
        mathbox.remove "play.#{@name}"
        @positions.set 'data', @animState.positions
        @bracket.set 'data', @animState.bracket
        @swapLineGeom.set 'opacity', @animState.swapOpacity
        @swapLine.set 'data', @animState.swapLine
        # Clean up opacity effects
        @doMultEffect = null
        @doRepEffect = null
        document.getElementById(@_id 'multFlyer').style.opacity =
            @animState.multOpacity
        for elt in document.getElementsByClassName @_id('rrepFactor')
            elt.style.opacity = @animState.rrepParenOpacity
        for elt in document.getElementsByClassName @_id('addFlyer')
            elt.style.opacity = @animState.rrepOpacity
        for elt in document.getElementsByClassName "#{@name}-matrix-entry"
            elt.style.opacity = 1
        # Give DOM elements a chance to update
        @onNextFrame 1, () => @resize stepID

    htmlMatrix: (matrix, html) =>
        # Render matrix in html
        htmlMat = []
        for i in [0...@numRows]
            row = []
            for j in [0...@numCols]
                row.push(@domEl @domClass, {i: i, j: j}, texFraction matrix[i][j])
            html[i] = row
        html

    install: (@view) ->
        @positions = @view.matrix
            data:     @animState.positions,
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

        # This is the element factory.  No good way to get at this.
        @domEl = html[0].controller.dom.el
        @htmlMatrix @animState.matrix, @animState.html

        # Multiply-by number flyer
        @animState.html[@numRows] = []
        @animState.html[@numRows][0] =
            @domEl @domClass, {id: @_id('multFlyer'), className: 'mult-flyer'}, ''
        # Nothing in the rest of the row
        for i in [1...@numCols]
            @animState.html[@numRows][i] =
                @domEl @domClass, {style: display: 'none'}, ''

        # Add row flyer
        @animState.html[@numRows+1] = []
        for i in [0...@numCols]
            @animState.html[@numRows+1][i] =
                @domEl @domClass, {className: @_id 'addFlyer'}, ''
        # Opening and closing parens for row replacement factor
        for j in [@numRows+2..@numRows+3]
            @animState.html[j] = []
            for i in [1...@numCols]
                # Empty
                @animState.html[j][i] =
                    @domEl @domClass, {style: display: 'none'}, ''
        @animState.html[@numRows+2][0] =
            @domEl @domClass, {
                className: 'rrep-factor ' + @_id('rrepFactor')
                id: @_id 'rrepParenLeft'}, ''
        @animState.html[@numRows+3][0] =
            @domEl @domClass, {
                className: 'rrep-factor ' + @_id('rrepFactor')
                id: @_id 'rrepParenRight'}, ''

        html.set
            # This is an expr so mathbox.inspect() isn't a million lines
            expr:    (emit, el, j, i) => emit(@animState.html[i][j])

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

        # @view.matrix
        #     width:    @numCols
        #     height:   @numRows
        #     channels: 4
        #     id:       "colors"
        #     expr: (emit, i, j) ->
        #         emit(1,0,0,1) if j == 0
        #         emit(0,1,0,1) if j == 1
        #         emit(0,0,1,1) if j == 2
        #         emit(0,0,0,1) if j == 3

        # @view.point
        #     points: "#rrmat-positions"
        #     colors: "#colors"

        # Brackets
        @bracket = @view.array
            channels: 2
            width:    4
            classes:  [@name]
            id:       @_id 'bracket'
            data: @animState.bracket

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

        # Swap-points arrow
        @swapLine = @view.array
            channels: 2
            width:    @swapLineSamples + 1
            classes:  [@name]
            id:       @_id 'swapLine'
            data:     @animState.swapLine

        @swapLineGeom = @view.line
            color:   "green"
            width:   4
            start:   true
            end:     true
            opacity: 0.0
            id:      @_id 'swapLineGeom'
            classes: [@name]

        # This gets run once after the DOM elements are added
        observer = new MutationObserver (mutations, observer) =>
            elts = document.querySelectorAll ".#{@name} > .baseline-detect"
            # There are the matrix entries, the mult flyer, the row flyer, and
            # the row replacement factor opening and closing parens
            if elts.length >= (@numRows + 4) * @numCols
                @alignBaselines elts
                @resize()
                @onNextFrame 10, () =>
                    @fade mathbox.select('#' + @_id('dom')), {0: 0, .3: 1}
                    @fade mathbox.select('#' + @_id('bracketLeft')), {0: 0, .3: 1}
                    @fade mathbox.select('#' + @_id('bracketRight')), {0: 0, .3: 1}
                observer.disconnect()
        observer.observe document.getElementById('mathbox'),
               childList:     true
               subtree:       true

        # This only runs on DOM element updates
        observer = new MutationObserver (mutations) =>
            for mutation in mutations
                continue unless mutation.target.classList.contains 'bound-entry'
                @alignBaselines mutation.target.getElementsByClassName 'baseline-detect'
        observer.observe document.getElementById('mathbox'),
               childList:     true
               subtree:       true


        @

    alignBaselines: (elts) =>
        # Align baselines with the reference points (javascript hack)
        elts ?= document.querySelectorAll ".#{@name} > .baseline-detect"
        for elt in elts
            elt.parentElement.style.top = -elt.offsetTop + "px"

    ######################################################################
    # Transitions and helper functions
    ######################################################################

    chain: (stepID, steps...) ->
        ret = new Chain(@, stepID)
        ret.steps = steps
        ret

    swapLinePoints: (top, bot, animState=@animState) ->
        # Get points for the swap-arrows line
        samples = @swapLineSamples
        lineHeight = Math.abs(top - bot)
        center = (top + bot) / 2
        points = ([Math.sin(π * i/samples) * @colSpacing * 3 +
                      animState.matWidth/2 + @colSpacing + 2,
                   Math.cos(π * i/samples) * lineHeight/2 + center] \
                  for i in [0..samples])
        return points

    rowSwap: (stepID, row1, row2) ->
        # Return an animation in two steps.
        # The first step fades in the swap arrow.
        # The second step does the swap.

        fadeTime = 0.3
        swapTime = 1

        transform1 = (oldState) =>
            nextState = deepCopy oldState
            nextState.swapOpacity = 1.0
            top = nextState.positions[row1][0][1] + @fontSize/3
            bot = nextState.positions[row2][0][1] + @fontSize/3
            nextState.swapLine = @swapLinePoints top, bot, nextState
            return nextState

        transition1 = (nextState, stepID) =>
            @swapLine.set 'data', nextState.swapLine
            script = {}
            script[0] = 0
            script[fadeTime] = 1
            @fade @swapLineGeom, script
                .on 'play.done', (e) => @newState nextState, stepID

        transform2 = (oldState) =>
            nextState = deepCopy oldState
            [nextState.matrix[row1], nextState.matrix[row2]] =
                [nextState.matrix[row2], nextState.matrix[row1]]
            @htmlMatrix nextState.matrix, nextState.html
            nextState.swapOpacity = 0.0
            return nextState

        transition2 = (nextState, stepID) =>
            pos = deepCopy @animState.positions
            [pos[row1], pos[row2]] = [pos[row2], pos[row1]]

            # Put moving rows on top
            # for i in [row1, row2]
            #     for j in [0...@numCols]
            #         @animState.positions[i][j][2] = 10

            @play @positions,
                pace: swapTime
                script:
                    0: {props: {data: @animState.positions}}
                    1: {props: {data: pos}}

            top = @animState.swapLine[0][1]
            bot = @animState.swapLine[@animState.swapLine.length-1][1]
            center = (top + bot) / 2
            transLine = ([x,-y+2*center] for [x,y] in @animState.swapLine)

            @play @swapLine,
                pace: swapTime
                script:
                    0: {props: {data: @animState.swapLine}}
                    1: {props: {data: transLine}}

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
        chain: new Chain @, stepID, step1, step2

    multEffect: () =>
        # Fade numbers in and out when multiplying
        return unless @doMultEffect
        {row, rowNum, rowPos, past, flyer, clock,
            stepNum, stepID, opacity, start, nextState} = @doMultEffect
        return if stepNum > 2
        elapsed = clock.getTime().clock - start
        if stepNum == 1
            if elapsed >= 0.3
                flyer.style.opacity = 1
                @doMultEffect.stepNum = 3
                @onNextFrame 1, () => @newState nextState, stepID
            else
                flyer.style.opacity = elapsed/0.3
            return
        # stepNum == 2
        box = flyer.getBoundingClientRect()
        flyerPos = (box.left + box.right) / 2
        for elt, i in row
            if flyerPos < rowPos[i] && !past[i]
                # Change the number as the flyer flies past
                past[i] = true
                @animState.html[rowNum][i] = nextState.html[rowNum][i]
            elt.style.opacity = opacity(Math.abs(flyerPos - rowPos[i]))
        if past[0]
            # Fade out the flyer
            flyer.style.opacity =
                Math.max(1 - (rowPos[0] - flyerPos)/@fontSize/5, 0)
            if flyer.style.opacity < 0.05
                @onNextFrame 1, () => @newState nextState, stepID
                @doMultEffect.stepNum = 3

    rowMult: (stepID, rowNum, factor) ->
        # Return an animation in two steps
        # The first step fades in the multiplication flyer
        # The second step does the multiplication

        precomputations = (doMultEffect) =>
            row = document.getElementsByClassName "#{@name}-row-#{rowNum}"
            flyer = document.getElementById @_id('multFlyer')
            # Put the flyer text to the right of the reference point
            flyer.parentElement.style.width = "0px"
            pos = []
            past = []
            for elt in row
                box = elt.getBoundingClientRect()
                pos.push (box.left + box.right) / 2
                past.push false
            doMultEffect.row    = row
            doMultEffect.flyer  = flyer
            doMultEffect.rowPos = pos
            doMultEffect.past   = past
            doMultEffect.start  = doMultEffect.clock.getTime().clock

        doMultEffect =
                rowNum:    rowNum
                clock:     @positions[0].clock
                opacity:   (distance) => Math.min (distance/(@fontSize*2))**3, 1

        transform1 = (oldState) =>
            nextState = deepCopy oldState
            nextState.multOpacity = 1
            nextState.html[@numRows][0] =
                @domEl @domClass, {id: @_id('multFlyer'), className: 'mult-flyer'},
                    '\\times' + texFraction(factor)

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
            @positions.set 'data', nextState.positions
            @animState.html[@numRows][0] = nextState.html[@numRows][0]

        transform2 = (oldState) =>
            nextState = deepCopy oldState
            nextState.matrix[rowNum] = (r * factor for r in nextState.matrix[rowNum])
            @htmlMatrix nextState.matrix, nextState.html
            nextState.multOpacity = 0
            rowY = @animState.positions[rowNum][0][1]
            nextState.positions[@numRows][0] = [-nextState.matWidth*2, rowY, 10]
            nextState

        transition2 = (nextState, stepID) =>
            @doMultEffect = doMultEffect
            precomputations @doMultEffect
            @doMultEffect.nextState = nextState
            @doMultEffect.stepID    = stepID
            @doMultEffect.stepNum   = 2

            @play @positions,
                script:
                    0:    {props: {data: @animState.positions}}
                    1.75: {props: {data: nextState.positions}}

        step1 = new Step @, "#{stepID}-1", transform1, transition1
        step2 = new Step @, "#{stepID}-2", transform2, transition2

        step1: step1
        step2: step2
        chain: new Chain @, stepID, step1, step2

    _measureWidth: (text) ->
        span = document.getElementById 'width-measurer'
        if !span
            div = document.createElement 'div'
            div.className = 'mathbox-outline-2 mathbox-label'
            div.style.fontSize = '20px'
            document.body.appendChild div
            span = document.createElement 'span'
            span.id = 'width-measurer'
            span.className = "#{@name} bound-entry rrep-factor " + @_id('rrepFactor')
            div.appendChild span
        span.innerHTML = text
        width = span.getBoundingClientRect().width
        return width

    repEffect: () =>
        # Opacity effects for row replacement
        return unless @doRepEffect
        {start, clock, parenLeft, parenRight, row, flyer,
            targetRow, opacity, nextState, stepID, stepNum} = @doRepEffect
        return if stepNum > 2
        elapsed = clock.getTime().clock - start
        if stepNum == 1
            if elapsed < 0.3
                # Fade in the parentheses
                parenLeft.style.opacity = elapsed / 0.3
                parenRight.style.opacity = elapsed / 0.3
            else if elapsed < 1.5
                parenLeft.style.opacity = 1
                parenRight.style.opacity = 1
            else
                @doRepEffect.stepNum = 3
                @onNextFrame 1, () => @newState nextState, stepID
            return
        # stepNum == 2
        if elapsed < 1.5
            # Decrease opacity of flyer and row as the former covers the latter
            right = row[@numCols-1].getBoundingClientRect().right
            for elt in flyer
                pos = elt.getBoundingClientRect().left
                elt.style.opacity = opacity(pos - right)
            left = parenLeft.getBoundingClientRect().left
            for elt in row
                pos = elt.getBoundingClientRect().right
                elt.style.opacity = opacity(left - pos)
            return
        elapsed -= 1.5
        if elapsed < 0.3
            for elt in flyer
                elt.style.opacity = 0.5 - elapsed/(2*0.3)
            for elt in row
                elt.style.opacity = 0.5 - elapsed/(2*0.3)
            parenLeft.style.opacity = 1 - elapsed/0.3
            parenRight.style.opacity = 1 - elapsed/0.3
            return
        elapsed -= 0.3
        if elapsed < 0.3
            for i in [0...@numCols]
                @animState.html[targetRow][i] = nextState.html[targetRow][i]
            for elt in row
                elt.style.opacity = elapsed/0.3
            return
        @onNextFrame 1, () => @newState nextState, stepID
        @doRepEffect.stepNum = 3

    rowRep: (stepID, sourceRow, factor, targetRow) ->
        # Return an animation in two steps
        # The first step moves the row flyer into place
        # The second step does the row replacement

        plus = if factor >= 0 then '+' else ''
        texString = plus + texFraction(factor) + '\\,\\bigl('
        leftParenWidth = @_measureWidth katex.renderToString(texString)
        padding = 7

        precomputations = (doRepEffect) =>
            doRepEffect.parenLeft  = document.getElementById(@_id 'rrepParenLeft')
            doRepEffect.parenRight = document.getElementById(@_id 'rrepParenRight')
            doRepEffect.row        = document.getElementsByClassName(
                "#{@name}-row-#{targetRow}")
            doRepEffect.flyer      = document.getElementsByClassName(@_id 'addFlyer')
            doRepEffect.start      = doRepEffect.clock.getTime().clock

        # Opacity effects
        doRepEffect =
            clock:      @positions[0].clock
            targetRow:  targetRow
            opacity:    (right) =>
                return 0.5 if right < 0
                Math.max(0.5, Math.min (right/(@fontSize)), 1)

        transform1 = (oldState) =>
            nextState = deepCopy oldState
            nextState.html[@numRows+2][0] =
                @domEl @domClass, {
                    className: 'rrep-factor ' + @_id('rrepFactor')
                    id: @_id 'rrepParenLeft'}, texString
            nextState.html[@numRows+3][0] =
                @domEl @domClass, {
                    className: 'rrep-factor ' + @_id('rrepFactor')
                    id: @_id 'rrepParenRight'}, '\\bigr)'

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

            # Initialize row flyer
            offsetX = nextState.matWidth + @colSpacing + 10 + leftParenWidth + padding
            for i in [0...@numCols]
                nextState.html[@numRows+1][i] =
                    @domEl @domClass, {className: @_id 'addFlyer'},
                        nextState.html[sourceRow][i].children
                nextState.positions[@numRows+1][i] =
                    deepCopy nextState.positions[sourceRow][i]
                nextState.positions[@numRows+1][i][0] += offsetX
                nextState.positions[@numRows+1][i][1] = rowY
                nextState.positions[@numRows+1][i][2] = 10

            nextState.rrepOpacity = 1
            nextState.rrepParenOpacity = 1

            nextState

        transition1 = (nextState, stepID) =>
            @animState.html = nextState.html
            for elt in document.getElementsByClassName @_id('rrepFactor')
                # Put these to the right of the reference point
                elt.parentElement.style.width = "0px"
                elt.style.opacity = 0
            addFlyer = document.getElementsByClassName(@_id 'addFlyer')
            elt.style.opacity = 1 for elt in addFlyer
            @animState.positions[@numRows+1] = @animState.positions[sourceRow]
            @animState.positions[@numRows+2][0] = nextState.positions[@numRows+2][0]
            @animState.positions[@numRows+3][0] = nextState.positions[@numRows+3][0]

            @play @positions,
                script:
                    0.0: {props: {data: @animState.positions}}
                    1.5: {props: {data: nextState.positions}}

            @doRepEffect = doRepEffect
            precomputations @doRepEffect
            @doRepEffect.nextState = nextState
            @doRepEffect.stepID = stepID
            @doRepEffect.stepNum = 1

        transform2 = (oldState) =>
            nextState = deepCopy oldState
            for i in [0...@numCols]
                nextState.matrix[targetRow][i] +=
                    factor * nextState.matrix[sourceRow][i]
            @htmlMatrix nextState.matrix, nextState.html
            offsetX = nextState.matWidth + @colSpacing + 10 + leftParenWidth + padding
            for i in [0...@numCols]
                nextState.positions[@numRows+1][i][0] -= offsetX
            nextState.positions[@numRows+2][0][0] -= offsetX
            nextState.positions[@numRows+3][0][0] -= offsetX
            nextState.rrepOpacity = 0
            nextState.rrepParenOpacity = 0
            nextState

        transition2 = (nextState, stepID) =>
            @play @positions,
                script:
                    0.0: {props: {data: @animState.positions}}
                    1.5: {props: {data: nextState.positions}}

            @doRepEffect = doRepEffect
            precomputations @doRepEffect
            @doRepEffect.nextState = nextState
            @doRepEffect.stepID    = stepID
            @doRepEffect.stepNum   = 2

        step1 = new Step @, "#{stepID}-1", transform1, transition1
        step2 = new Step @, "#{stepID}-2", transform2, transition2

        step1: step1
        step2: step2
        chain: new Chain @, stepID, step1, step2

window.RRMatrix = RRMatrix
