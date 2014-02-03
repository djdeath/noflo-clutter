noflo = require 'noflo'

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
        @outPorts.context.send(Clutter.get_cogl_context())
        @outPorts.disconnect()

exports.getComponent = -> new ClutterCoglContext
