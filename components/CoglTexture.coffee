noflo = require 'noflo'
{StateComponent} = require '../lib/StateComponent'

class CoglTexture extends StateComponent
  description: 'creates a new CoglTexture from a file'
  constructor: ->
    super()
    @inPorts =
      filename: new noflo.Port 'string'
      context: new noflo.Port 'object'
    @outPorts =
      texture: new noflo.ArrayPort 'object'

    @connectParamPort('context', @inPorts.context)
    @connectDataPort('filename', @inPorts.filename)

    @Cogl = imports.gi.Cogl

  process: (state) ->
    if @outPorts.texture.isAttached()
      texture = @cogl.Texture2D.new_from_file(state.context, state.filename, Cogl.TextureFlags.NO_ATLAS, Cogl.PixelFormat.ANY)
      @outPorts.texture.send(texture)
      @outPorts.texture.disconnect()

exports.getComponent = -> new CoglTexture
