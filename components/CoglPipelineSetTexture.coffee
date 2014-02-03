noflo_clutter = require 'noflo-clutter'

class CoglPipelineSetTexture extends noflo_clutter.StateComponent
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

    @Cogl = imports.gi.Cogl
    @ctx = @Clutter.get_default_backend().get_cogl_context();

  can_process: (state) ->
    return state.pipeline && state.texture && state.layer

  process: (state) ->
    if @outPorts.pipeline.isAttached()
      state.pipeline.set_layer_texture(state.layer, state.texture)
      @outPorts.pipeline.send(state.pipeline)

exports.getComponent = -> new CoglPipelineSetTexture