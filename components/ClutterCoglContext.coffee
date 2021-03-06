noflo = require 'noflo'

Clutter = imports.gi.Clutter

class ClutterCoglContext extends noflo.Component
  description: 'Gets the CoglContext attached used by Clutter'
  constructor: ->
    super()
    @inPorts =
      start: new noflo.Port 'boolean'
    @outPorts =
      context: new noflo.ArrayPort 'object'


    @inPorts.start.on 'data', () =>
      if @outPorts.context.isAttached()
        backend = Clutter.get_default_backend()
        @outPorts.context.send(backend.get_cogl_context())
        @outPorts.context.disconnect()

exports.getComponent = -> new ClutterCoglContext
