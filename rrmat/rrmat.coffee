"use strict"

# Compile with
#    cat animstate.coffee rrmat.coffee | coffee --compile --stdio > rrmat.js

# TODO: Funny sizes on Safari
# TODO: just-in-time width measuring with persistent measuring elements
# TODO: use CSS animations in setStyle; don't use timers
# TODO: cleanup html

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

# Make a two-dimensional array, with entries initialized to 'val'
makeArray = (rows, cols, val) ->
    ret = []
    for i in [0...rows]
        row = []
        for j in [0...cols]
            row.push val
        ret.push row
    ret

# Find best fractional approximation to a decimal by walking the Stern-Brocot
# tree.  See https://stackoverflow.com/a/5128558
approxFraction = (x, error=.00001) ->
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

# Turn decimals that want to be fractions into fractions rendered in LaTeX.
texFraction = (x, error=0.00001) ->
    [num, den] = approxFraction x, error
    if den == 1
        return num.toString()
    minus = if num < 0 then '-' else ''
    num = Math.abs num
    return "#{minus}\\frac{#{num}}{#{den}}"


# Slideshow that can attach slides from RRMatrix.
# For slides with multiple steps (rowSwap, rowMult, rowRep), the steps can be
# added individually or chained, depending on opts.keys.
class RRSlideshow extends Slideshow
    rowSwap: (row1, row2, opts={}) ->
        keys = opts.keys ? ['chain']
        delete opts.keys
        slides = @controller.rowSwap row1, row2, opts
        @addSlide slides[k] for k in keys
        @

    rowMult: (rowNum, factor, opts={}) ->
        keys = opts.keys ? ['chain']
        delete opts.keys
        slides = @controller.rowMult rowNum, factor, opts
        @addSlide slides[k] for k in keys
        @

    rowRep: (sourceRow, factor, targetRow, opts={}) ->
        keys = opts.keys ? ['chain']
        delete opts.keys
        slides = @controller.rowRep sourceRow, factor, targetRow, opts
        @addSlide slides[k] for k in keys
        @

    unAugment: (opts) ->
        @addSlide(@controller.unAugment opts)
        @
    reAugment: (opts) ->
        @addSlide(@controller.reAugment opts)
        @

    setStyle: (transitions, opts) ->
        @addSlide(@controller.setStyle transitions, opts)
        @
    highlightPivots: (opts) ->
        @addSlide(@controller.highlightPivots opts)
        @


# This class controls an animated matrix of numbers.  It produces slides that
# animate the steps of a row reduction sequence.
class RRMatrix extends Controller

    # These are the style properties that can be transformed using setStyle().
    # Add new keys here to control those too.
    styleKeys: ['color', 'opacity', 'transform']

    constructor: (@numRows, @numCols, @view, mathbox, opts) ->
        {name, @fontSize, @rowHeight, @rowSpacing, @defSpeed,
            @colSpacing, @augmentCol, startAugmented} = opts or {}

        # General options
        name        ?= "rrmat"
        @fontSize   ?= 20
        @rowHeight  ?= @fontSize * 1.2
        @rowSpacing ?= @fontSize
        @colSpacing ?= @fontSize
        @matHeight = @rowHeight * @numRows + @rowSpacing * (@numRows-1)
        startAugmented ?= @augmentCol?
        @defSpeed   ?= 1.0

        # VDOM element constructor
        @domClass = MathBox.DOM.createClass \
            render: (el, props, children) =>
                props = deepCopy props
                props.innerHTML  = children
                props.innerHTML += '<span class="baseline-detect"></span>'
                return el('span', props)

        # Running timers (TODO: get rid of these)
        @timers = []
        # Number of points to use when drawing the row swap line with arrows
        @swapLineSamples = 30

        # These get to the bound DOM elements when they are created.
        @matrixElts        = []
        @multFlyerElt      = undefined
        @addFlyerElts      = []
        @rrepParenLeftElt  = undefined
        @rrepParenRightElt = undefined

        ######################################################################
        # Animation State
        ######################################################################

        state = new State @

        # All text element positions go here.  They are not stored separately
        # because pixel position readback is slow (gl.readPixels is slow).  They
        # are stored as follows:
        #          0  matrix
        #        ...    ...entry
        #  numRows-1    ...positions
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

        # The matrix width.  Not manipulated directly; just saved in
        # @computePositions().
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

        # The matrix entries.  Not directly displayed on-screen; use
        # @htmlMatrix() to update @state.html.
        state.addVal
            key:  'matrix'
            val:  makeArray @numRows, @rumCols, 0
            copy: deepCopy

        # The matrix bracket line.
        state.addVal
            key:     'bracket'
            val:     makeArray 4, 2, 0
            copy:    deepCopy
            install: (rrmat, val) => @bracket.set 'data', val

        # The arrow for row swaps.
        state.addVal
            key:     'swapLine'
            val:     makeArray @swapLineSamples+1, 2, 0
            copy:    deepCopy
            install: (rrmat, val) => @swapLine.set 'data', val
        state.addVal
            key:     'swapOpacity'
            val:     0.0
            install: (rrmat, val) => @swapLineGeom.set 'opacity', val

        # The augmentation line.
        state.addVal
            key:     'augment'
            val:     [[0,0],[0,0]]
            copy:    deepCopy
            install: (rrmat, val) => @augment.set 'data', val
        state.addVal
            key:     'doAugment'
            val:     startAugmented
            install: (rrmat, val) => @augmentGeom.set 'visible', val

        # For slideshows.
        state.addVal
            key: 'caption'
            val: ''

        super name, state, mathbox
        @createMathbox()

    createMathbox: () ->
        # Create the on-screen elements.

        @positions = @view.matrix
            data:     @state.positions,
            width:    @numCols
            height:   @numRows+4
            channels: 3
            classes:  [@name]
            id:       @_id 'positions'

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

        html = @view.html
            width:   @numCols
            height:  @numRows+4
            classes: [@name]
            live:    true
            expr:    (emit, el, j, i) =>
                emit(el @domClass, htmlProps[i][j], @state.html[i][j])

        dom = @view.dom
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
        bracketLeft = @view.line
            color:   "black"
            width:   2
            classes: [@name]
            id:      @_id 'bracketLeft'
            opacity: 0
        tform = bracketLeft.transform
            scale:   [-1, 1, 1]
            classes: [@name]
        bracketRight = tform.line
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
            visible: @state.doAugment

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

        @onNextFrame 1, () =>
            # This gets run after the DOM elements are added
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

        # Give browsers (Safari...) time to warm up its element renderer before
        # using @_measureWidth.
        @onNextFrame 9, () =>
            resize = @resize()
            @anims.push resize
            resize.on 'stopped', () => @state.install()
            resize.start()
        # Fade in the matrix
        @onNextFrame 10, () =>
            scr = {0: 0, .3: 1}
            anim1 = new FadeAnimation dom,           scr
            anim2 = new FadeAnimation bracketLeft,   scr
            anim3 = new FadeAnimation bracketRight,  scr
            anim4 = new FadeAnimation @augmentGeom,  scr
            anim = new SimultAnimations [anim1, anim2, anim3, anim4]
            @anims.push anim
            anim.on 'stopped', () =>
                for elt in [dom, bracketLeft, bracketRight, @augmentGeom]
                    elt.set 'opacity', 1
                null
            anim.start()
            @loaded = true
            @trigger type: 'loaded'

        # This runs on DOM element updates to re-align baselines.
        observer = new MutationObserver (mutations) =>
            for mutation in mutations
                @alignBaselines mutation.target.getElementsByClassName 'baseline-detect'
        @onNextFrame 1, () =>
            for elt in document.querySelectorAll ".#{@name}.bound-entry"
                observer.observe elt,
                    childList: true
                    subtree:   true
                    characterData: true
        @

    # Unique ID for element names
    _id: (element) => "#{@name}-#{element}"

    _measureWidth: (html, fromElement) ->
        # Measure the width of rendered 'html', using the font properties in
        # fromElement.
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
        # width, as they would be in 'state'
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
        state.matWidth += (@numCols - 1) * @colSpacing
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
        if @augmentCol? and not state.doAugment
            diff = @view.get('scale').y
            state.augment[0][1] += diff
            state.augment[1][1] += diff

        state

    jumpState: (nextState) =>
        super nextState
        # TODO: get rid of timers
        clearTimeout timer for timer in @timers
        @timers = []

    htmlMatrix: (matrix, html) =>
        # Render katex html from matrix entries
        html[i][j] = katex.renderToString(texFraction matrix[i][j]) \
            for i in [0...@numRows] for j in [0...@numCols]
        html

    setMatrix: (matrix) ->
        @state.matrix = matrix
        @htmlMatrix @state.matrix, @state.html
        if @loaded
            resize = @resize()
            @anims.push resize
            resize.on 'stopped', () => @state.install()
            resize.start

    alignBaselines: (elts) =>
        # Align baselines with the reference points of the DOM elements
        # (javascript hack).  There seems to be no CSS way to set the absolute
        # position of a DOM element using its base line.
        elts ?= document.querySelectorAll ".#{@name} > .baseline-detect"
        for elt in elts
            elt.parentElement.style.top = -elt.offsetTop + "px"

    getPivots: (state=@state) ->
        pivots = []
        for row, i in state.matrix
            for ent, j in row
                if Math.abs(ent) > .00001
                    pivots.push j
                    break
            if pivots.length <= i
                pivots.push null  # zero row
        pivots

    isREF: (state=@state) ->
        pivots = @getPivots state
        # Check zero rows at bottom
        sawZero = false
        for col in pivots
            if col == null
                sawZero = true
            else
                return false if sawZero
        # Check ascending order of pivot columns
        last = -1
        for col in pivots
            break if col == null
            return false if col <= last
            last = col
        # Check zero entries under pivots
        for col, row in pivots
            break if col == null
            for i in [row+1...@numRows]
                return false if state.matrix[i][col] != 0
        return true

    isRREF: (state=@state) ->
        return false unless @isREF state
        pivots = @getPivots state
        # Check zero entries above pivots
        for col, row in pivots
            break if col == null
            for i in [0...row]
                return false if state.matrix[i][col] != 0
            return false if state.matrix[row][col] != 1
        return true

    ######################################################################
    # Transitions and helper functions
    ######################################################################

    resize: (nextState) =>
        # Return an animation that resizes the matrix from its current size to
        # its natural size.  This updates @state immediately.
        nextState ?= @computePositions @state
        @state.matWidth = nextState.matWidth

        equal = true
        anims = []
        for i in [0...@numRows]
            for j in [0...@numCols]
                for k in [0...1]
                    if nextState.positions[i][j][k] != @state.positions[i][j][k]
                        equal = false
                    break if not equal
                break if not equal
            break if not equal
        if not equal
            play1 = new MathboxAnimation @positions,
                script:
                    0:   props: data: @state.positions
                    0.2: props: data: nextState.positions
            anims.push play1
            @state.positions = nextState.copyVal 'positions'

        if !arraysEqual nextState.bracket, @state.bracket
            play2 = new MathboxAnimation @bracket,
                script:
                    0:   props: data: @state.bracket
                    0.2: props: data: nextState.bracket
            anims.push play2
            @state.bracket = nextState.copyVal 'bracket'

        if @augmentCol? and not arraysEqual nextState.augment, @state.augment
            play3 = new MathboxAnimation @augment,
                script:
                    0:   props: data: @state.augment
                    0.2: props: data: nextState.augment
            anims.push play3
            @state.augment = nextState.copyVal 'augment'

        return new SimultAnimations anims if anims.length
        return new NullAnimation()

    slideshow: () -> new RRSlideshow @
    chain: (slides) -> new SlideChain slides

    rowSwap: (row1, row2, opts) ->
        # Return an animation in two slides.
        # The first slide fades in the swap arrow.
        # The second slide does the swap.

        speed = opts?.speed or @defSpeed
        fadeTime = 0.3/speed
        swapTime = 1/speed
        rrmat = @

        _swapLinePoints = (top, bot, state) =>
            # Get points for the swap-arrows line
            samples = @swapLineSamples
            lineHeight = Math.abs(top - bot)
            center = (top + bot) / 2
            points = ([Math.sin(π * i/samples) * @colSpacing * 3 +
                          state.matWidth/2 + @colSpacing + 2,
                       Math.cos(π * i/samples) * lineHeight/2 + center] \
                      for i in [0..samples])
            return points

        class Slide1 extends Slide
            start: () ->
                @_nextState = @transform rrmat.state
                @_nextState.installVal 'swapLine'
                script = {}
                script[0] = 0
                script[fadeTime] = 1
                play = new FadeAnimation rrmat.swapLineGeom, script
                @anims.push play
                play.on 'done', () =>
                    rrmat.state = @_nextState
                    @done()
                play.start()
                super

            transform: (oldState) ->
                nextState = oldState.copy()
                nextState.swapOpacity = 1.0
                top = nextState.positions[row1][0][1] + rrmat.fontSize/3
                bot = nextState.positions[row2][0][1] + rrmat.fontSize/3
                nextState.swapLine = _swapLinePoints top, bot, nextState
                nextState

            fastForward: () -> @_nextState.copy()

        class Slide2 extends Slide
            start: () ->
                @_nextState = @transform rrmat.state
                pos = deepCopy rrmat.state.positions
                [pos[row1], pos[row2]] = [pos[row2], pos[row1]]

                play1 = new MathboxAnimation rrmat.positions,
                    pace: swapTime
                    script:
                        0: props: data: rrmat.state.positions
                        1: props: data: pos

                top = rrmat.state.swapLine[0][1]
                bot = rrmat.state.swapLine[rrmat.swapLineSamples][1]
                center = (top + bot) / 2
                transLine = ([x,-y+2*center] for [x,y] in rrmat.state.swapLine)

                play2 = new MathboxAnimation rrmat.swapLine,
                    pace: swapTime
                    script:
                        0: props: data: rrmat.state.swapLine
                        1: props: data: transLine

                script = {}
                script[0] = 1
                script[swapTime] = 1
                script[swapTime+fadeTime] = 0
                play3 = new FadeAnimation rrmat.swapLineGeom, script

                anim = new SimultAnimations [play1, play2, play3]
                @anims.push anim
                anim.on 'done', () =>
                    rrmat.state = @_nextState
                    rrmat.state.installVal 'positions'
                    rrmat.state.installVal 'html'
                    rrmat.state.installVal 'styles'
                    @done()
                anim.start()
                super

            transform: (oldState) ->
                nextState = oldState.copy()
                [nextState.matrix[row1], nextState.matrix[row2]] =
                    [nextState.matrix[row2], nextState.matrix[row1]]
                [nextState.styles[row1], nextState.styles[row2]] =
                    [nextState.styles[row2], nextState.styles[row1]]
                [nextState.html[row1], nextState.html[row2]] =
                    [nextState.html[row2], nextState.html[row1]]
                nextState.swapOpacity = 0.0
                nextState

            fastForward: () -> @_nextState.copy()

        slide1 = new Slide1()
        slide2 = new Slide2()

        slide1.data.type = slide2.data.type = "rowSwap"

        # Suitable for use in a URL
        slide2.data.shortOp = "s#{row1}:#{row2}"
        slide2.data.texOp = "R_{#{row1+1}} \\leftrightarrow R_{#{row2+1}}"

        slide1: slide1
        slide2: slide2
        chain: new SlideChain [slide1, slide2]

    rowMult: (rowNum, factor, opts) ->
        # Return an animation in two slides
        # The first slide fades in the multiplication flyer
        # The second slide does the multiplication

        speed = opts?.speed or @defSpeed
        flidx = @numRows
        rrmat = @

        class Slide1 extends Slide
            start: () ->
                @_nextState = @transform rrmat.state
                @_nextState.installVal 'positions'
                rrmat.state.html[flidx][0] = @_nextState.html[flidx][0]

                rrmat.multFlyerElt.parentElement.style.width = "0px"
                anim = new TimedAnimation rrmat.positions[0].clock,
                    (elapsed) ->
                        elapsed *= speed
                        if elapsed >= 0.3
                            rrmat.multFlyerElt.style.opacity = 1
                            @done()
                        else
                            rrmat.multFlyerElt.style.opacity = elapsed/0.3
                @anims.push anim
                anim.on 'done', () =>
                    rrmat.state = @_nextState
                    @done()
                anim.start()
                super

            transform: (oldState) ->
                nextState = oldState.copy()
                nextState.styles[flidx][0].opacity = 1
                nextState.html[flidx][0] =
                    katex.renderToString('\\times' + texFraction(factor))
                startX = nextState.matWidth/2 + rrmat.colSpacing + 10
                rowY = nextState.positions[rowNum][0][1]
                nextState.positions[flidx][0] = [startX, rowY, 10]
                nextState

            fastForward: () -> @_nextState.copy()

        class Slide2 extends Slide
            start: () ->
                nextState = @_nextState = @transform rrmat.state, false
                pos = []
                past = []
                row = rrmat.matrixElts[rowNum]
                for elt in row
                    box = elt.getBoundingClientRect()
                    pos.push (box.left + box.right) / 2
                    past.push false
                opacity = (distance) => Math.min (distance/(rrmat.fontSize*2))**3, 1

                anim = new TimedAnimation rrmat.positions[0].clock,
                    (elapsed) ->
                        elapsed *= speed
                        box = rrmat.multFlyerElt.getBoundingClientRect()
                        flyerPos = (box.left + box.right) / 2
                        for elt, i in row
                            if flyerPos < pos[i] and !past[i]
                                # Change the number as the flyer flies past
                                past[i] = true
                                rrmat.state.html[rowNum][i] = nextState.html[rowNum][i]
                            elt.style.opacity = opacity(Math.abs(flyerPos - pos[i]))
                        if past[0]
                            # Fade out the flyer
                            rrmat.multFlyerElt.style.opacity =
                                Math.max(1 - (pos[0] - flyerPos)/rrmat.fontSize/5, 0)
                            if rrmat.multFlyerElt.style.opacity < 0.05
                                rrmat.multFlyerElt.style.opacity = 0
                                @done()

                play = new MathboxAnimation rrmat.positions,
                    speed: speed
                    script:
                        0:    props: data: rrmat.state.positions
                        1.75: props: data: @_nextState.positions

                callback = () =>
                    rrmat.state = @_nextState
                    @stopAll()
                    rrmat.multFlyerElt.style.opacity = 0
                    resize = rrmat.resize()
                    @anims.push resize
                    resize.on 'done', () => @done()
                    resize.start()

                anim.on 'done', callback
                play.on 'done', callback

                play.start()
                anim.start()
                @anims.push play
                @anims.push anim
                super

            transform: (oldState, computePos=true) ->
                nextState = oldState.copy()
                nextState.matrix[rowNum] =
                    (r * factor for r in nextState.matrix[rowNum])
                rrmat.htmlMatrix nextState.matrix, nextState.html
                nextState.styles[flidx][0].opacity = 0
                rowY = rrmat.state.positions[rowNum][0][1]
                nextState.positions[flidx][0] =
                    [-nextState.matWidth*2, rowY, 10]
                if computePos
                    return rrmat.computePositions nextState
                nextState

            fastForward: () -> rrmat.computePositions @_nextState

        slide1 = new Slide1()
        slide2 = new Slide2()

        slide1.data.type = slide2.data.type = "rowMult"

        # Suitable for use in a URL
        [num, den] = approxFraction factor
        slide2.data.shortOp = "m#{rowNum}:#{num}"
        slide2.data.shortOp += ".#{den}" if den != 1
        slide2.data.texOp = "R_{#{rowNum+1}} = " +
            texFraction(factor) + "R_{#{rowNum+1}}"

        slide1: slide1
        slide2: slide2
        chain: new SlideChain [slide1, slide2]

    rowRep: (sourceRow, factor, targetRow, opts) ->
        # Return an animation in two slides
        # The first slide moves the row flyer into place
        # The second slide does the row replacement

        speed = opts?.speed or @defSpeed
        plus = if factor >= 0 then '+' else ''
        texString = katex.renderToString(plus + texFraction(factor) + '\\,\\bigl(')
        padding = 7
        flidx = @numRows + 1
        lpidx = @numRows + 2
        rpidx = @numRows + 3
        rrmat = @

        class Slide1 extends Slide
            start: () ->
                nextState = @_nextState = @transform rrmat.state
                rrmat.state.html = nextState.html
                tmpState = nextState.copy()
                tmpState.styles[lpidx][0].opacity = 0
                tmpState.styles[rpidx][0].opacity = 0
                tmpState.installVal 'styles'
                for elt in [rrmat.rrepParenLeftElt, rrmat.rrepParenRightElt]
                    # Put these to the right of the reference point
                    elt.parentElement.style.width = "0px"
                rrmat.state.positions[flidx]    = rrmat.state.positions[sourceRow]
                rrmat.state.positions[lpidx][0] = nextState.positions[lpidx][0]
                rrmat.state.positions[rpidx][0] = nextState.positions[rpidx][0]

                play = new MathboxAnimation rrmat.positions,
                    speed: speed
                    script:
                        0.0: props: data: rrmat.state.positions
                        1.5: props: data: nextState.positions
                @anims.push play

                anim = new TimedAnimation rrmat.positions[0].clock,
                    (elapsed) ->
                        elapsed *= speed
                        if elapsed < 0.3
                            # Fade in the parentheses
                            rrmat.rrepParenLeftElt.style.opacity = elapsed / 0.3
                            rrmat.rrepParenRightElt.style.opacity = elapsed / 0.3
                        else if elapsed < 1.5
                            rrmat.rrepParenLeftElt.style.opacity = 1
                            rrmat.rrepParenRightElt.style.opacity = 1
                        else
                            @done()
                @anims.push anim
                anim.on 'done', () =>
                    rrmat.state = @_nextState
                    @done()

                play.start()
                anim.start()
                super

            transform: (oldState) ->
                nextState = oldState.copy()
                nextState.html[lpidx][0] = texString
                nextState.html[rpidx][0] = katex.renderToString('\\bigr)')

                # Initialize row replacement factor
                leftParenWidth =
                    rrmat._measureWidth texString, rrmat.rrepParenLeftElt
                rowY = nextState.positions[targetRow][0][1]
                matWidth = nextState.matWidth + padding*2
                leftParenX = nextState.matWidth/2 + rrmat.colSpacing + 10
                nextState.positions[lpidx][0][0] = leftParenX
                nextState.positions[lpidx][0][1] = rowY
                nextState.positions[lpidx][0][2] = 5
                nextState.positions[rpidx][0][0] =
                    leftParenX + leftParenWidth + matWidth
                nextState.positions[rpidx][0][1] = rowY
                nextState.positions[rpidx][0][2] = 5
                nextState.styles[lpidx][0].opacity = 1
                nextState.styles[rpidx][0].opacity = 1

                # Initialize row flyer
                offsetX = nextState.matWidth + rrmat.colSpacing +
                    10 + leftParenWidth + padding
                nextState.styles[flidx]    = deepCopy nextState.styles[sourceRow]
                nextState.html[flidx]      = deepCopy nextState.html[sourceRow]
                nextState.positions[flidx] = deepCopy nextState.positions[sourceRow]
                for i in [0...rrmat.numCols]
                    nextState.styles[flidx][i].opacity = 1
                    nextState.positions[flidx][i][0] += offsetX
                    nextState.positions[flidx][i][1] = rowY
                    nextState.positions[flidx][i][2] = 10

                nextState

            fastForward: () -> @_nextState.copy()

        opacity = (right) ->
            return 0.5 if right < 0
            Math.max(0.5, Math.min (right/(rrmat.fontSize)), 1)

        class Slide2 extends Slide
            start: () ->
                nextState = @_nextState = @transform rrmat.state, false
                play = new MathboxAnimation rrmat.positions,
                    speed: speed
                    script:
                        0.0: props: data: rrmat.state.positions
                        1.5: props: data: nextState.positions
                @anims.push play
                row = rrmat.matrixElts[targetRow]

                anim = new TimedAnimation rrmat.positions[0].clock,
                    (elapsed) ->
                        elapsed *= speed
                        if elapsed < 1.5
                            # Decrease opacity of flyer and row as the former
                            # covers the latter
                            right = row[rrmat.numCols-1].getBoundingClientRect().right
                            for elt in rrmat.addFlyerElts
                                pos = elt.getBoundingClientRect().left
                                elt.style.opacity = opacity(pos - right)
                            left = rrmat.rrepParenLeftElt.getBoundingClientRect().left
                            for elt in row
                                pos = elt.getBoundingClientRect().right
                                elt.style.opacity = opacity(left - pos)
                            return
                        elapsed -= 1.5
                        if elapsed < 0.3
                            # Fade out flyer and matrix row
                            for elt in rrmat.addFlyerElts
                                elt.style.opacity = 0.5 - elapsed/(2*0.3)
                            for elt in row
                                elt.style.opacity = 0.5 - elapsed/(2*0.3)
                            rrmat.rrepParenLeftElt.style.opacity = 1 - elapsed/0.3
                            rrmat.rrepParenRightElt.style.opacity = 1 - elapsed/0.3
                            return
                        for elt in rrmat.addFlyerElts
                            elt.style.opacity = 0
                        rrmat.rrepParenLeftElt.style.opacity = 0
                        rrmat.rrepParenRightElt.style.opacity = 0
                        elapsed -= 0.3
                        if elapsed < 0.3
                            # Fade in new matrix row
                            for i in [0...rrmat.numCols]
                                rrmat.state.html[targetRow][i] =
                                    nextState.html[targetRow][i]
                            for elt in row
                                elt.style.opacity = elapsed/0.3
                            return
                        # All done
                        for elt in row
                            elt.style.opacity = 1
                        @done()
                @anims.push anim

                anim.on 'done', () =>
                    rrmat.state = @_nextState
                    @stopAll()
                    resize = rrmat.resize()
                    @anims.push resize
                    resize.on 'done', () => @done()
                    resize.start()

                anim.start()
                play.start()
                super

            transform: (oldState, computePos=true) ->
                nextState = oldState.copy()
                for i in [0...rrmat.numCols]
                    nextState.matrix[targetRow][i] +=
                        factor * nextState.matrix[sourceRow][i]
                rrmat.htmlMatrix nextState.matrix, nextState.html
                leftParenWidth =
                    rrmat._measureWidth texString, rrmat.rrepParenLeftElt
                offsetX = nextState.matWidth + rrmat.colSpacing +
                    10 + leftParenWidth + padding
                for i in [0...rrmat.numCols]
                    nextState.styles[flidx][i].opacity = 0
                    nextState.positions[flidx][i][0] -= offsetX
                nextState.positions[lpidx][0][0] -= offsetX
                nextState.positions[rpidx][0][0] -= offsetX
                nextState.styles[lpidx][0].opacity = 0
                nextState.styles[rpidx][0].opacity = 0
                if computePos
                    return rrmat.computePositions nextState
                nextState

            fastForward: () -> rrmat.computePositions @_nextState

        slide1 = new Slide1()
        slide2 = new Slide2()

        slide1.data.type = slide2.data.type = "rowRep"

        # Suitable for use in a URL
        plus = if factor < 0 then '' else '+'
        [num, den] = approxFraction factor
        slide2.data.shortOp = "r#{sourceRow}:#{num}"
        slide2.data.shortOp += ".#{den}" if den != 1
        slide2.data.shortOp += ":#{targetRow}"
        slide2.data.texOp = "R_{#{targetRow+1}} = R_{#{targetRow+1}} #{plus}" +
            texFraction(factor) + "R_{#{sourceRow+1}}"

        slide1: slide1
        slide2: slide2
        chain: new SlideChain [slide1, slide2]

    unAugment: (opts) ->
        # Remove the augmentation line.
        speed = opts?.speed or @defSpeed
        rrmat = @

        class AugSlide extends Slide
            start: () ->
                nextState = @_nextState = @transform rrmat.state, false
                play = new MathboxAnimation rrmat.augment,
                    speed: speed
                    script:
                        0:   props: data: rrmat.state.augment
                        0.5: props: data: nextState.augment
                @anims.push play
                play.on 'done', () =>
                    rrmat.state = @_nextState
                    @stopAll()
                    rrmat.state.installVal 'doAugment'
                    resize = rrmat.resize()
                    @anims.push resize
                    resize.on 'done', () => @done()
                    resize.start()
                play.start()
                super

            transform: (oldState, computePos=true) ->
                nextState = oldState.copy()
                nextState.doAugment = false
                diff = rrmat.view.get('scale').y
                nextState.augment[0][1] += diff
                nextState.augment[1][1] += diff
                if computePos
                    return rrmat.computePositions nextState
                nextState

            fastForward: () -> rrmat.computePositions @_nextState

        slide = new AugSlide()
        slide.data.type = "unAugment"
        slide

    reAugment: (opts) ->
        # Add the augmentation line back.
        speed = opts?.speed or @defSpeed
        rrmat = @

        class AugSlide extends Slide
            start: () ->
                nextState = @_nextState = @transform rrmat.state
                tmpState = nextState.copy()
                nextState.installVal 'doAugment'
                diff = rrmat.view.get('scale').y
                tmpState.augment[0][1] += diff
                tmpState.augment[1][1] += diff
                resize = rrmat.resize tmpState
                @anims.push resize
                play = new MathboxAnimation rrmat.augment,
                    speed: speed
                    script:
                        0:   props: data: tmpState.augment
                        0.5: props: data: nextState.augment
                resize.on 'done', () =>
                    @anims = [play]
                    play.start()
                play.on 'done', () =>
                    @anims = []
                    rrmat.state = @_nextState
                    @done()
                resize.start()
                super

            transform: (oldState) ->
                nextState = oldState.copy()
                nextState.doAugment = true
                nextState = rrmat.computePositions nextState
                nextState

            fastForward: () -> @_nextState.copy()

        slide = new AugSlide()
        slide.data.type = "reAugment"
        slide

    # Set the style of a number of matrix elements.
    #
    # 'transitions' is a list of style transitions.  Each transition is an
    # object with the following keys:
    #   color, opacity, transformation, ...: specify the new property values
    #   entries:  a list of [i,j] matrix entries to apply the values.
    #   duration: transition time, in seconds
    #   delay:    delay time, in seconds (default 0)
    #   timing:   easing function (default 'ease')

    class StyleSlide extends Slide
        constructor: (@transitions, @rrmat, opts) ->
            @speed = opts?.speed or @rrmat.defSpeed
            # Total time of the effect
            @transitions = @_initTransitions @transitions
            super

        _initTransitions: (transitions) ->
            @totalTime = 0
            if not (transitions instanceof Array)
                transitions = [transitions]
            for trans in transitions
                trans.duration ?= 0.0
                trans.duration /= @speed
                trans.delay ?= 0.0
                trans.delay /= @speed
                trans.timing ?= 'ease'
                @totalTime = Math.max @totalTime, trans.duration + trans.delay
                trans.props = []
                for prop in @rrmat.styleKeys
                    trans.props.push prop if trans[prop]?
            transitions

        _setStyle: (i, j, trans) ->
            if trans.duration
                transition =
                    ("#{p} #{trans.duration}s #{trans.timing}" \
                        for p in trans.props).join(', ')
            else
                transition = ""
            style = transition: transition
            for prop in trans.props
                style[prop] = trans[prop]
            elt = rrmat.matrixElts[i][j]
            for k, v of style
                elt.style[k] = v

        start: () ->
            @_nextState = @transform rrmat.state
            for trans in @transitions
                callback = do (trans) => () =>
                    for entry in trans.entries
                        @_setStyle entry[0], entry[1], trans
                    null
                if trans.delay == 0
                    # Give colors a chance to reset
                    rrmat.onNextFrame 1, callback
                else
                    timer = setTimeout callback, trans.delay*1000
                    rrmat.timers.push timer
            callback = () =>
                rrmat.state = @_nextState
                @done()
            timeout = setTimeout callback, @totalTime*1000
            rrmat.timers.push timeout
            super

        transform: (oldState) =>
            nextState = oldState.copy()
            # Compute final matrix entry styles
            for i in [0...rrmat.numRows]
                for j in [0...rrmat.numCols]
                    last = 0.0
                    style = {}
                    for trans in @transitions
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

        fastForward: () -> @_nextState.copy()

    setStyle: (transitions, opts) ->
        slide = new StyleSlide transitions, @, opts
        slide.data.type = "setStyle"
        slide

    # Automatically highlight pivots
    highlightPivots: (opts) ->
        color = opts?.color or "red"
        if opts?.duration?
            duration = opts.duration
        else
            duration = 0.3
        rrmat = @

        class PivotSlide extends StyleSlide
            constructor: () ->
                super [], rrmat, opts

            transform: (oldState) ->
                nextState = oldState.copy()
                pivots = rrmat.getPivots nextState
                entries = []
                for col, row in pivots
                    continue if col == null
                    entries.push [row, col]
                transition1 =
                    color:    color
                    duration: duration
                    entries:  entries
                entries2 = []
                for i in [0...rrmat.numRows]
                    for j in [0...rrmat.numCols]
                        isPivot = false
                        for ent in entries
                            if ent[0] == i and ent[1] == j
                                isPivot = true
                                break
                        entries2.push [i,j] unless isPivot
                transition2 =
                    color:    "black"
                    duration: duration
                    entries:  entries2
                @transitions = @_initTransitions [transition1, transition2]
                super nextState

        slide = new PivotSlide()
        slide.data.type = "highlightPivots"
        slide


RRMatrix.texFraction = texFraction
RRMatrix.approxFraction = approxFraction
RRMatrix.arraysEqual = arraysEqual
window.RRMatrix = RRMatrix
