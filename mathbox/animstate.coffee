"use strict"

# Poor man's trigger / callback mix-in
addEvents = (cls) ->
    cls.prototype.on = (types, callback) ->
        if not (types instanceof Array)
            types = [types]
        @_listeners ?= {}
        for type in types
            @_listeners[type] ?= []
            @_listeners[type].push callback
        @
    cls.prototype.off = (type, callback) ->
        idx = @_listeners?[type]?.indexOf callback
        if idx? and idx >= 0
            @_listeners[type].splice idx, 1
        @
    cls.prototype.trigger = (event) ->
        type = event.type
        event.target = @
        listeners = @_listeners?[type]?.slice()
        return unless listeners?
        for callback in listeners
            callback.call @, event, @
            if callback.triggerOnce
                @off type, callback
        @


# Class that holds state.  Knows how to copy and install itself.
class State
    constructor: (@anim) ->
        @keys        = []
        @_copyVal    = {}
        @_installVal = {}

    addVal: (opts) ->
        key     = opts.key
        val     = opts.val     ? undefined
        copy    = opts.copy    ? (val)  -> val
        install = opts.install ? (anim, val) ->
        @keys.push key
        @[key] = val
        @_copyVal[key] = copy
        @_installVal[key] = install

    copy: () ->
        ret = new State(@anim)
        for k in @keys
            ret.addVal
                key:     k
                copy:    @_copyVal[k]
                install: @_installVal[k]
            ret[k] = @_copyVal[k] @[k]
        ret

    install: () ->
        @installVal k for k in @keys

    copyVal: (key) ->
        @_copyVal[key] @[key]
    installVal: (key) ->
        @_installVal[key] @anim, @[key]


# Class for stateful animations.  This class is responsible for two things:
#   1. Instantly setting to a given state.
#   2. Running animations and keeping track of them.
class Controller
    constructor: (@name, @state) ->
        @anims = []
        @loaded = false
        mathbox.three.on 'pre', @frame
        mathbox.three.on 'post', @frame
        @clock = mathbox.select('root')[0].clock

    jumpState: (nextState) ->
        anim.stop() for anim in @anims
        @anims = []
        @state = nextState.copy()
        @state.install()

    frame: (event) =>
        return unless @nextFrame?[event.type]?
        frames = mathbox.three.Time.frames
        for f, callbacks of @nextFrame[event.type]
            if f < frames
                delete @nextFrame[event.type][f]
                callback() for callback in callbacks

    onNextFrame: (after, callback, stage='post') ->
        # Execute 'callback' after 'after' frames
        @nextFrame ?= {}
        @nextFrame[stage] ?= {}
        time = mathbox.three.Time.frames + (after-1)
        @nextFrame[stage][time] ?= []
        @nextFrame[stage][time].push(callback)


# This class represents a single animation.
class Animation
    constructor: () ->
        @running = false

    start: () ->
        @running = true
        @

    stop: () ->
        @running = false
        @trigger type: 'stopped'
        @

    done: () ->
        @running = false
        @trigger type: 'done'
        @

addEvents Animation


class NullAnimation extends Animation
    start: () ->
        super
        @done()


class SimultAnimations extends Animation
    constructor: (@children) ->
        super

    start: () ->
        for child in @children
            child.on 'done', () => @done()
            child.start()
        super

    stop: () ->
        child.stop() for child in @children
        super

    done: () ->
        for child in @children
            return if child.running
        super


# Animation that is controlled by a Mathbox clock
class TimedAnimation extends Animation
    constructor: (@clock, @animate) ->
        super

    start: () ->
        startTime = @clock.getTime().clock
        @callback = () =>
            elapsed = @clock.getTime().clock - startTime
            @animate elapsed
        @clock.on 'clock.tick', @callback
        super

    stop: () ->
        @clock.off 'clock.tick', @callback
        super

    done: () ->
        @clock.off 'clock.tick', @callback
        super

# Thin wrapper around mathbox.play
class MathboxAnimation extends Animation
    constructor: (element, @opts) ->
        @opts.target  = element
        @opts.to     ?= Math.max.apply null, (k for k of @opts.script)
        super
    start: () ->
        @_play = @opts.target.play @opts
        @_play.on 'play.done', () =>
            @_play.remove()
            delete @_play
            @done()
        super
    stop: () ->
        @_play?.remove()
        delete @_play
        super


class FadeAnimation extends MathboxAnimation
    constructor: (element, script) ->
        # Fade an element in or out
        script2 = {}
        script2[k] = {props: {opacity: v}} for k, v of script
        opts = script: script2
        opts.ease = 'linear'
        super element, opts



# This class represents a single animation slide.  It is responsible for
# computing the state when finished.
class Slide extends Animation
    constructor: () ->
        # Currently running animations
        @anims = []
        super

    stopAll: () ->
        anim.stop() for anim in @anims
        @anims = []

    stop: () ->
        @stopAll()
        super

    done: () ->
        @stopAll()
        super

    # Reimplement these in subclasses / instances.
    #   'transform' transforms the state from an old state
    #   'fastForward' is only called when @running is true.  It yields the state
    #       after play() finishes.
    transform: (oldState) -> oldState.copy()
    fastForward: () ->


# Chain several slides together
class SlideChain extends Slide
    constructor: (@slides) ->
        @slideNum = -1
        callback = () =>
            if @slideNum+1 < @slides.length
                @playSlide @slideNum+1
            else
                @slideNum = -1
                @done()
        slide.on 'done', callback for slide in @slides
        super

    transform: (oldState) ->
        for slide in @slides
            oldState = slide.transform oldState
        oldState

    playSlide: (slideNum) =>
        @slideNum = slideNum
        slide = @slides[@slideNum]
        slide.start()

    start: () =>
        super
        @playSlide 0
        @

    stop: () =>
        slide = @slides[@slideNum]
        slide.stop()
        @slideNum = -1
        super

    fastForward: () =>
        return unless @slideNum >= 0
        slide = @slides[@slideNum]
        nextState = slide.fastForward()
        for i in [@slideNum+1...@slides.length]
            nextState = @slides[i].transform nextState
        nextState


# This class controls playing slides.  Note that the slideshow's slide zero is the
# initial state; it doesn't correspond to a Slide.  This means that @states[i] is
# the animation state before @slides[i] runs, and @states[@slides.length] is the
# final state.  The @currentSlideNum is an index into @states[] for the current
# state, or, if an animation is playing, the previous state.  Setting the slide
# with @goToSlide will jump straight to that slide.
class Slideshow
    constructor: (@controller) ->
        @slides = []
        @states = [@controller.state.copy()]
        @currentSlideNum = 0
        @playing = false

        cls = ".slideshow.#{@controller.name}"
        @prevButton   = document.querySelector "#{cls} .prev-button"
        @reloadButton = document.querySelector "#{cls} .reload-button"
        @nextButton   = document.querySelector "#{cls} .next-button"
        @pageCounter  = document.querySelector "#{cls} .pages"
        @captions  = document.querySelectorAll "#{cls} .slides > .slide"

        @prevButton.onclick = () =>
            return if @currentSlideNum == 0 and !@playing
            return if !@controller.loaded
            if @playing
                @goToSlide @currentSlideNum
            else
                @goToSlide @currentSlideNum - 1
        @nextButton.onclick = () =>
            return if @currentSlideNum == @slides.length
            return if !@controller.loaded
            if @playing
                @goToSlide @currentSlideNum + 1
            else
                @states[0] = @controller.state.copy() if @currentSlideNum == 0
                @play()
        @reloadButton.onclick = () =>
            return if @currentSlideNum == 0 and !@playing
            return if !@controller.loaded
            if @playing
                @goToSlide @currentSlideNum
            else
                @goToSlide @currentSlideNum - 1
            @play()

        @updateUI()

    updateCaptions: (j) ->
        @captions[j].classList.remove 'inactive'
        for caption, i in @captions
            if i != j and !@captions[i].classList.contains 'inactive'
                @captions[i].classList.add 'inactive'

    updateUI: (oldSlideNum=-1) =>
        if @currentSlideNum == 0 and !@playing
            @prevButton.classList.add 'inactive'
            @reloadButton.classList.add 'inactive'
        else
            @prevButton.classList.remove 'inactive'
            @reloadButton.classList.remove 'inactive'
        if @currentSlideNum == @slides.length
            @nextButton.classList.add 'inactive'
        else
            @nextButton.classList.remove 'inactive'
        @pageCounter?.innerHTML = "#{@currentSlideNum+1} / #{@slides.length+1}"

    play: () ->
        return if @currentSlideNum >= @slides.length
        @playing = true
        @slides[@currentSlideNum].start()
        @updateUI()

    goToSlide: (slideNum) =>
        return if slideNum < 0 or slideNum > @slides.length
        #console.log "Active slide: #{slideNum}"
        oldSlideNum = @currentSlideNum
        @currentSlideNum = slideNum
        if @currentSlideNum > oldSlideNum and @playing
            @states[oldSlideNum+1] = @slides[oldSlideNum].fastForward()
            @states[oldSlideNum+1].captionNum++
            @slides[oldSlideNum].stop()
        else if @playing
            @slides[oldSlideNum].stop()
        @controller.jumpState @states[@currentSlideNum]
        @updateCaptions @states[@currentSlideNum].captionNum
        @playing = false
        @updateUI oldSlideNum

    addSlide: (slide) ->
        if @combining?
            @combining.push slide
            return @
        @slides.push slide
        slide.on 'done', () =>
            @playing = false
            @currentSlideNum += 1
            @controller.state.captionNum++
            @states[@currentSlideNum] = @controller.state.copy()
            @updateUI @currentSlideNum - 1
            @updateCaptions @controller.state.captionNum
        @updateUI()
        @

    # Combine several slides into a chain.  End with combined()
    combine: () ->
        @combining = []
        @
    combined: (opts) ->
        combining = @combining
        delete @combining
        @addSlide (new SlideChain combining)
        @

    class CaptionSlide extends Slide
        constructor: (@sshow) -> super
        start: () ->
            @_nextState = @transform @sshow.controller.state
            @sshow.updateCaptions @_nextState.captionNum
            @sshow.controller.state = @_nextState
            super
            @done()
        transform: (oldState) ->
            nextState = oldState.copy()
            nextState.captionNum++
            nextState
        fastForward: () -> @_nextState.copy()

    nextCaption: (opts) ->
        @addSlide(new CaptionSlide @)


window.State = State
window.Controller = Controller
window.Animation = Animation
window.SimultAnimations = SimultAnimations
window.NullAnimation = NullAnimation
window.TimedAnimation = TimedAnimation
window.MathboxAnimation = MathboxAnimation
window.FadeAnimation = FadeAnimation
window.Slide = Slide
window.SlideChain = SlideChain
window.Slideshow = Slideshow
