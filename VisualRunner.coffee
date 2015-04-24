_ = require('underscore')

KEY_FRAME_SPACING = 100

class VisualRunner
  constructor: (name) ->
    window[name] = @exposedObject = {}
    @_index = 0
    @stepLength = 100

    @setupExposedObject()
    @createInitialState(0)
    @render({})

  clearSavedState: ->
    throw "Not implemented"

  createInitialState: (key) ->
    throw "Not implemented"

  saveState: (key) ->
    throw "Not implemented"

  loadState: (key) ->
    throw "Not implemented"

  setupSeekControl: (control) ->
    if control?
      @seekControl = control

      pausedForSeek = false
      @seekControl.on 'mousedown', =>
        if @_stepId?
          pausedForSeek = true
          @pause()
      @seekControl.on 'mouseup', =>
        if pausedForSeek
          @play()
        pausedForSeek = false
        return
      @seekControl.on 'input', =>
        @_setIndex(parseInt(@seekControl.val(), 10))

    @seekControl
      .val(@_index)
      .attr('min', 0)
      .attr('step', 1)
      .attr('max', (@_funcQueue?.length || 0))

  _setIndex: (i) ->
    runOneStep = (step) =>
      { name, args } = @_funcQueue[step]
      @exposedFuncs[name](args...)
    prevIndex = @_index

    if prevIndex > i
      @_index = Math.floor(i / KEY_FRAME_SPACING) * KEY_FRAME_SPACING
      @loadState(@_index)
    while @_index < i
      runOneStep(@_index)
      @_index++

    @seekControl.val(@_index)

    @render(@_dataQueue[@_index - 1] ? {})

  _clearPrev: ->
    @_funcQueue = []
    @_dataQueue = []
    @exposedObject.locals = {}

  _save: (name, args...) ->
    @_funcQueue.push({ name, args })
    @_dataQueue.push(
      locals: _.clone(@exposedObject.locals)
    )
    if @_funcQueue.length % KEY_FRAME_SPACING == 0
      @saveState(@_funcQueue.length)

  _step: ->
    if @_index >= @_funcQueue.length
      return @pause()
    @_setIndex(@_index + 1)

  render: ->
    throw "Not implemented"

  loadControls: ->
    throw "Not implemented"

  renderControls: ->
    throw "Not implemented"

  onInitialChange: ->
    if !@_stepId?
      @loadControls()
      @createInitialState(0)
      @_clearPrev()
      @setupSeekControl()
      @render({})
    @renderControls()

  onScrollChange: ->
    console.log 'well, that happened'

  setupExposedObject: ->
    for name, fx of @exposedFuncs
      do (name, fx) =>
        wrappedFunc = (args...) =>
          ret = fx(args...)
          @_save(name, args...)
          ret

        @exposedObject[name] = wrappedFunc

  doTask: ->
    throw "Not implemented"

  run: (code) ->
    @_clearPrev()
    @loadState(0)
    @doTask()
    @setupSeekControl()
    @loadState(0)
    @_setIndex(0)
    @play()

  _stepAndContinue: ->
    @_step()
    @_stepId = setTimeout(@_stepAndContinue.bind(@), @stepLength)

  play: ->
    if @_stepId?
      return
    @_stepId = setTimeout(@_stepAndContinue.bind(@), @stepLength)

    @playButton?.hide()
    @pauseButton?.show()

  pause: ->
    clearTimeout(@_stepId)
    @_stepId = null

    @pauseButton?.hide()
    @playButton?.show()

module.exports = VisualRunner
