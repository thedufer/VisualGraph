class VisualRunner
  constructor: (name) ->
    window[name] = @exposedObject = {}
    @exposedObject.locals = {}
    @_funcQueue = []
    @_dataQueue = []

    @setupExposedObject()
    @createInitialState()
    @render()

  createInitialState: ->
    throw "Not implemented"

  loadInitialState: ->
    throw "Not implemented"

  _clearPrev: ->
    @_funcQueue = []
    @_dataQueue = []

  _save: (name, args...) ->
    @_funcQueue.push({ name, args })
    @_dataQueue.push(
      locals: @exposedObject.locals
    )

  _step: ->
    [fxName, args...] = @_funcQueue[@_index]
    @exposedFuncs[fxName](args...)
    @render()
    @_index++

  render: ->
    throw "Not implemented"

  loadControls: ->
    throw "Not implemented"

  renderControls: ->
    throw "Not implemented"

  onInitialChange: ->
    if !@_stepId?
      @loadControls()
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
    @doTask()
    @_index = 0
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
