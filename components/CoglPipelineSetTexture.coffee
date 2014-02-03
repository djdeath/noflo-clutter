noflo = require 'noflo'
{StateComponent} = require '../lib/StateComponent'

class CoglPipelineSetTexture extends StateComponent
  description: 'Set a texture on a CoglPipeline'
  constructor: ->
    super()
    @inPorts =
      pipeline: new noflo.Port 'object'
      texture: new noflo.Port 'object'
      layer: new noflo.Port 'number'
    @outPorts =
      pipeline: new noflo.ArrayPort 'object'

    @connectDataPort('pipeline', @inPorts.pipeline)
    @connectDataPort('texture', @inPorts.texture)
    @connectParamPort('texture', @inPorts.texture)

    @Cogl = imports.gi.Cogl
    @ctx = @Clutter.get_default_backend().get_cogl_context();

  process: (state) ->
    if @outPorts.pipeline.isAttached()
      state.pipeline.set_layer_texture(state.layer, state.texture)
      @outPorts.pipeline.send(state.pipeline)

exports.getComponent = -> new CoglPipelineSetTexture
