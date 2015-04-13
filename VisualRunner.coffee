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
          pausedForSeek = false
          @play()
      @seekControl.on 'input', =>
        @_index = parseInt(@seekControl.val(), 10)

    @seekControl
      .val(@_index)
      .attr('min', 0)
      .attr('step', 1)
      .attr('max', @_funcQueue?.length ? 0)

  _setIndex: (i) ->
    @_index = i
    @seekControl.val(@_index)

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
    { name, args } = @_funcQueue[@_index]
    @exposedFuncs[name](args...)
    @render()
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
    @_setIndex(0)
    @loadInitialState()
    @play()

  play: ->
    if @_stepId?
      return
    @_step()
    @_stepId = setInterval(@_step.bind(@), 100)

  pause: ->
    clearInterval(@_stepId)
    @_stepId = null

module.exports = VisualRunner
