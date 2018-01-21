"use strict"

# This module contains utility classes for animations and slideshows.  The goal
# is to keep track of the state of all on-screen objects, being able to jump
# from one state to another (fast-forward and rewinding of slides) and to
# transition smoothly between states.
#
# This module contains the following primary classes:
#
# + Controller:
#   This class controls the current state of what's being displayed.  It is
#   responsible for keeping track of the on-screen objects, and updating them
#   with a new State.  It contains some utility functions to this end.
#
# + State:
#   This class contains the state for a Controller.  It is an Object, with
#   values associated to keys.  Each value knows how to duplicate itself and how
#   to install itself into (i.e. apply its value to) the associated object of a
#   Controller.
#
# + Animation:
#   An Animation object can start() itself, can be stop()ped, and knows when it
#   is done().  It emits a signal on stop() and on done().  The animation
#   controls the on-screen objects in a Controller.
#
# + Slide:
#   A Slide is an Animation that takes a Controller from one State to another.
#   It typically runs several child Animation instances.  A Slide knows how to
#   transform() a State to the State after the slide would have run.  It can
#   also fastForward() while running to return the state after the slide would
#   have been done().  This allows for just-in-time calculations (e.g. widths of
#   elements) when fast-forwarded in a Slideshow.
#
# + Slideshow:
#   A Slideshow controls playing and navigating a sequence of Slide instances.
#   It hooks into controls defined in the DOM.  It implements a convenient API
#   for defining a sequence of slides.

# Poor man's listen / trigger mix-in
addEvents = (cls) ->
    cls.prototype.on = (types, callback) ->
        if not (types instanceof Array)
            types = [types]
        @_listeners ?= {}
        for type in types
            @_listeners[type] ?= []
            @_listeners[type].push callback
        @
    cls.prototype.off = (types, callback) ->
        if not (types instanceof Array)
            types = [types]
        for type in types
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


# Class that holds the state of the on-screen elements of a Controller.  It
# knows how to copy itself and how to install itself, i.e. how to apply itself
# to the associated on-screen elements.
class State
    constructor: (@controller) ->
        @keys        = []
        @_copyVal    = {}
        @_installVal = {}

    addVal: (opts) ->
        # Add a key/value pair to the State
        key     = opts.key
        val     = opts.val     ? undefined
        copy    = opts.copy    ? (val)  -> val
        install = opts.install ? (controller, val) ->
        @keys.push key
        @[key] = val
        @_copyVal[key] = copy
        @_installVal[key] = install

    copy: () ->
        ret = new State(@controller)
        for k in @keys
            ret.addVal
                key:     k
                val:     @_copyVal[k] @[k]
                copy:    @_copyVal[k]
                install: @_installVal[k]
        ret

    copyVal: (key) ->
        @_copyVal[key] @[key]
    installVal: (key) ->
        @_installVal[key] @controller, @[key]
    install: () ->
        @installVal k for k in @keys


# Class that controls the state of the on-screen elements.  It contains the
# instance variable @state, a State instance which it must define in the
# constructor.  It must also create or locate the associated on-screen elemnets
# when instantiated.
#
# This class can jumpState() to an arbitrary new State.  This generally just
# involves install()ing the new State.  At this point, @state accurately
# reflects the state of the on-screen elements.  When an Animation or a Slide is
# playing, the @state object is in transition; its relation to the on-screen
# elements is undefined.  When a Slide is done(), the @state again reflects the
# state of the on-screen elements.

class Controller
    constructor: (@name, @state, @mathbox) ->
        # Array of currently playing animations.  This exists for convenience;
        # anything here will be stop()ped when jumpState() is called.
        @anims = []
        # This should be set to 'true' when a Slideshow can start playing.
        @loaded = false
        @mathbox.three.on 'pre', @frame
        @mathbox.three.on 'post', @frame
        @clock = @mathbox.select('root')[0].clock

    jumpState: (nextState) ->
        # Apply a nextState to the on-screen elements.
        anim.stop() for anim in @anims
        @anims = []
        @state = nextState.copy()
        @state.install()

    frame: (event) =>
        # Exeucute a callback after a specified number of frames.
        return unless @nextFrame?[event.type]?
        frames = @mathbox.three.Time.frames
        for f, callbacks of @nextFrame[event.type]
            if f < frames
                delete @nextFrame[event.type][f]
                callback() for callback in callbacks

    onNextFrame: (after, callback, stage='post') ->
        # Execute 'callback' after 'after' frames
        @nextFrame ?= {}
        @nextFrame[stage] ?= {}
        time = @mathbox.three.Time.frames + (after-1)
        @nextFrame[stage][time] ?= []
        @nextFrame[stage][time].push(callback)

addEvents Controller


# This class represents a single animation.  It knows how to start()
# itself, how to stop() itself, and when it is done().  It knows when it is
# @running, and it emits signals when start()ed and stop()ped.
#
# The stop() method should do nothing if @running is false.
class Animation
    constructor: () ->
        @running = false

    start: () ->
        @running = true
        @

    stop: () ->
        return unless @running
        @running = false
        @trigger type: 'stopped'
        @

    done: () ->
        @running = false
        @trigger type: 'done'
        @

addEvents Animation


# Do nothing
class NullAnimation extends Animation
    start: () ->
        super
        @done()


# Run several simultaneous child Animations.  start() starts them all; stop()
# stops them all; done() runs when the last one finishes.
class SimultAnimations extends Animation
    constructor: (@children) ->
        for child in @children
            child.on 'done', () => @done()
        super

    start: () ->
        child.start() for child in @children
        super

    stop: () ->
        child.stop() for child in @children
        super

    done: () ->
        for child in @children
            return if child.running
        super


# Animation that is controlled by a Mathbox clock.  The @animate instance
# variable is a function that is run on every clock tick.  It is passed the
# elapsed time since it was started, and 'this' is bound to the TimedAnimation
# object.  This function is responsible for calling done().
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

# Thin wrapper around the mathbox API's play() method
class MathboxAnimation extends Animation
    constructor: (element, @opts) ->
        @opts.target = element
        @opts.to ?= Math.max.apply null, (k for k of @opts.script)
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


# A MathboxAnimation that only controls the 'opacity' property
class FadeAnimation extends MathboxAnimation
    constructor: (element, script) ->
        # Fade an element in or out
        script2 = {}
        script2[k] = {props: {opacity: v}} for k, v of script
        opts = script: script2
        opts.ease = 'linear'
        super element, opts


# This class represents an animation slide.  Its main purpose is to transition a
# Controller from one well-defined State to another.  It contains the following
# methods, in addition to those in Animation:
#
# + transform:
#   This takes a State, and returns what the new State would be after this Slide
#   is done()
#
# + fastForward:
#   This is only applied when the Slide is @running.  It also returns what the
#   new State would be after the Slide is done().  This allows for just-in-time
#   computations, for instance of DOM element widths.
#
# The start() method starts with the current state of the Controller.  Note that
# start() and/or done() should actually update the Controller's state.  It is up
# to the caller to previde a reference to the Controller (e.g. in a closure).

class Slide extends Animation
    constructor: () ->
        # Array of currently running animations.  This is here for convenience;
        # all animations in this list will be stop()ped on stop() and done().
        @anims = []
        # Auxiliary data for use by the caller
        @data = {}
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

    # Reimplement these in subclasses.
    transform: (oldState) -> oldState.copy()
    fastForward: () ->


# Chain several slides together as one slide.
class SlideChain extends Slide
    constructor: (@slides) ->
        super
        @slideNum = -1
        callback = () =>
            if @slideNum+1 < @slides.length
                @playSlide @slideNum+1
            else
                @slideNum = -1
                @done()
        slide.on 'done', callback for slide in @slides
        # Propagate user data
        for slide in @slides
            for k, v of slide.data
                @data[k] = v

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
        return unless @slideNum >= 0
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


# This class controls playing and navigating a sequence of Slide instances.  It
# hooks into predefined DOM elements for user controls (prev, next, reload) and
# caption desplay.
#
# Note that the Slideshow's state zero is the initial State; it doesn't
# correspond to a Slide.  This means that @states[i] is the Controller's State
# before @slides[i] runs, and @states[@slides.length] is the final State.  The
# @currentSlideNum is an index into @states[] for the current State, or, if a
# Slide is playing, the State before it started.  Setting the slide with
# @goToSlide will jump straight to that State.
#
class Slideshow
    constructor: (@controller) ->
        @slides = []
        @states = [@controller.state.copy()]
        @currentSlideNum = 0
        @playing = false
        @combining = []

        cls = ".slideshow.#{@controller.name}"
        @prevButton   = document.querySelector "#{cls} .prev-button"
        @reloadButton = document.querySelector "#{cls} .reload-button"
        @nextButton   = document.querySelector "#{cls} .next-button"
        @pageCounter  = document.querySelector "#{cls} .pages"
        @captionDiv   = document.querySelector "#{cls} .caption"
        @states[0].caption = @controller.state.caption = @captionDiv?.innerHTML;

        @prevButton.onclick   = () => @prevSlide()
        @nextButton.onclick   = () => @nextSlide()
        @reloadButton.onclick = () => @reloadSlide()

        @updateUI()

    prevSlide: () ->
        return if @currentSlideNum == 0 and !@playing
        return if !@controller.loaded
        if @playing
            @goToSlide @currentSlideNum
        else
            @goToSlide @currentSlideNum - 1

    nextSlide: () ->
        return if @currentSlideNum == @slides.length
        return if !@controller.loaded
        if @playing
            @goToSlide @currentSlideNum + 1
        else
            # Just-in-time update the initial state
            @states[0] = @controller.state.copy() if @currentSlideNum == 0
            @play()

    reloadSlide: () ->
        return if @currentSlideNum == 0 and !@playing
        return if !@controller.loaded
        if @playing
            @goToSlide @currentSlideNum
        else
            @goToSlide @currentSlideNum - 1
        @play()

    updateCaption: (text) ->
        @captionDiv?.innerHTML = text

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

    getState: (slideNum) ->
        state = @states[0]
        for i in [0...slideNum]
            state = @slides[i].transform state
        state

    goToSlide: (slideNum) =>
        return if slideNum < 0 or slideNum > @slides.length
        oldSlideNum = @currentSlideNum
        @currentSlideNum = slideNum
        if @currentSlideNum > oldSlideNum
            if @playing
                @states[oldSlideNum+1] = @slides[oldSlideNum].fastForward()
                start = oldSlideNum+1
            else
                start = oldSlideNum
            @slides[oldSlideNum].stop()
            for i in [start...@currentSlideNum]
                @states[i+1] = @slides[i].transform @states[i]
        else if @playing
            @slides[oldSlideNum].stop()
        @controller.jumpState @states[@currentSlideNum]
        @updateCaption @states[@currentSlideNum].caption
        @playing = false
        @updateUI oldSlideNum
        if oldSlideNum != @currentSlideNum
            @trigger type: 'slide.new', stateNum: @currentSlideNum

    ###################################################################
    # API for creating the slideshow

    addSlide: (slide) ->
        @combining.push slide
        @

    removeSlide: (index) ->
        [slide] = @slides.splice index, 1
        @states.splice index+1, 1
        if @currentSlideNum == index+1
            newSlide = if index < @slides.length then index+1 else index
            @goToSlide newSlide
        else if @currentSlideNum > index
            @currentSlideNum--
            @updateUI()

    break: () ->
        combining = @combining
        @combining = []
        slide = new SlideChain combining
        @slides.push slide
        slide.on 'done', () =>
            @playing = false
            @currentSlideNum += 1
            @states[@currentSlideNum] = @controller.state.copy()
            @updateUI @currentSlideNum - 1
            @updateCaption @controller.state.caption
            @trigger type: 'slide.new', stateNum: @currentSlideNum
        @updateUI()
        @

    # This class changes the caption without playing any animations.
    class CaptionSlide extends Slide
        constructor: (@sshow, @caption) -> super
        start: () ->
            @_nextState = @transform @sshow.controller.state
            @sshow.updateCaption @caption
            @sshow.controller.state = @_nextState
            super
            @done()
        transform: (oldState) ->
            nextState = oldState.copy()
            nextState.caption = @caption
            nextState
        fastForward: () -> @_nextState.copy()

    # Insert a caption
    caption: (text) ->
        slide = new CaptionSlide @, text
        slide.data.type = "caption"
        @addSlide slide


addEvents Slideshow

window.State      = State
window.Controller = Controller
window.Animation  = Animation
window.NullAnimation = NullAnimation
window.SimultAnimations = SimultAnimations
window.TimedAnimation = TimedAnimation
window.MathboxAnimation = MathboxAnimation
window.FadeAnimation = FadeAnimation
window.Slide      = Slide
window.SlideChain = SlideChain
window.Slideshow  = Slideshow
