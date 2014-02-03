noflo = require 'noflo'

class CoglTexture extends noflo.Component
  description: 'creates a new CoglTexture from a file'
  constructor: ->
    @inPorts =
      filename: new noflo.Port 'string'

    @outPorts =
      texture: new noflo.ArrayPort 'object'

    @Clutter = imports.gi.Clutter
    @ctx = @Clutter.get_default_backend().get_cogl_context()

    @inPorts.filename.on 'data', (filename) =>
      texture = Cogl.Texture2D.new_from_file(@ctx, filename, Cogl.TextureFlags.NO_ATLAS, Cogl.PixelFormat.ANY)
      @outPorts.texture.send(texture)

exports.getComponent = -> new CoglTexture
