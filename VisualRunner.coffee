class VisualRunner
  constructor: (name) ->
    window[name] = @exposedObject = {}
    @exposedObject.locals = {}
    @_funcQueue = []
    @_dataQueue = []
    @_index = 0

    @setupExposedObject()
    @createInitialState()
    @render()

  createInitialState: ->
    throw "Not implemented"

  loadInitialState: ->
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
      @loadInitialState()
      @_index = 0
    while @_index < i
      runOneStep(@_index)
      @_index++

    @seekControl.val(@_index)
      
    @render()

  _clearPrev: ->
    @_funcQueue = []
    @_dataQueue = []

  _save: (name, args...) ->
    @_funcQueue.push({ name, args })
    @_dataQueue.push(
      locals: @exposedObject.locals
    )

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
      @createInitialState()
      @render()
    @renderControls()

  onScrollChange: ->
    console.log 'well, that happened'

  setupExposedObject: ->
    for name, fx of @exposedFuncs
      do (name, fx) =>
        wrappedFunc = (args...) =>
          @_save(name, args...)
          fx(args...)

        @exposedObject[name] = wrappedFunc

  doTask: ->
    throw "Not implemented"

  run: (code) ->
    @_clearPrev()
    @loadInitialState()
    @doTask()
    @setupSeekControl()
    @loadInitialState()
    @_setIndex(0)
    @play()

  play: ->
    if @_stepId?
      return
    @_stepId = setInterval(@_step.bind(@), 100)

    @playButton?.hide()
    @pauseButton?.show()

  pause: ->
    clearInterval(@_stepId)
    @_stepId = null

    @pauseButton?.hide()
    @playButton?.show()

module.exports = VisualRunner
