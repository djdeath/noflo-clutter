noflo = require 'noflo'
{StateComponent} = require '../lib/StateComponent'
Cogl = imports.gi.Cogl

class CoglPipeline extends StateComponent
  description: 'creates a new CoglPipeline'
  constructor: ->
    super()
    @inPorts =
      start: new noflo.Port 'boolean'
      context: new noflo.Port 'context'
    @outPorts =
      pipeline: new noflo.ArrayPort 'object'

    @connectParamPort('start', @inPorts.start)
    @connectDataPort('context', @inPorts.context)

  process: (state) ->
    if @outPorts.pipeline.isAttached()
      pipeline = new Cogl.Pipeline(state.context)
      @outPorts.pipeline.send(pipeline)
      @outPorts.pipeline.disconnect()

exports.getComponent = -> new CoglPipeline
