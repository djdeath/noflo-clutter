noflo_clutter = require 'noflo-clutter'

class CoglPipeline extends noflo_clutter.StateComponent
  description: 'creates a new CoglPipeline'
  constructor: ->
    super()
    @inPorts =
      start: new noflo.Port 'boolean'
    @outPorts =
      pipeline: new noflo.ArrayPort 'object'

    @connectParamPort('hook', @inPorts.hook)
    @connectDataPort('code', @inPorts.code)

    @Cogl = imports.gi.Cogl
    @ctx = @Clutter.get_default_backend().get_cogl_context();

  can_process: (state) ->
    return state.start

  process: (state) ->
    if @outPorts.pipeline.isAttached()
      pipeline = new @Cogl.Pipeline(ctx)
      @outPorts.pipeline.send(pipeline)

exports.getComponent = -> new CoglPipeline
