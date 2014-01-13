noflo = require 'noflo'

class ArrayToElement extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      in: new noflo.Port 'object'

    @outPorts =
      previous: new noflo.ArrayPort 'object'
      current: new noflo.ArrayPort 'object'

    @objs = []

    @inPorts.in.on 'data', (objs) =>
      @sendItems(@outPorts.previous)
      @objs = objs
      @sendItems(@outPorts.current)

    @inPorts.in.on 'disconnect', () =>
      @sendItems(@outPorts.previous)
      @objs = []

  sendItems: (port) =>
    if port.isAttached()
      for obj in @objs
        port.send(obj)
    port.disconnect() if port.isConnected()

exports.getComponent = -> new ArrayToElement
