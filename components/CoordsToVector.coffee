noflo = require 'noflo'

class CoordsToVector extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      x: new noflo.Port 'number'
      y: new noflo.Port 'number'

    @outPorts =
      vector: new noflo.ArrayPort 'object'

    @oldcoords =
      x: 0
      y: 0
    @coords =
      x: null
      y: null

    @connectPort('x', @inPorts.x)
    @connectPort('y', @inPorts.y)

  connectPort: (name, port) =>
    @inPorts[name].on 'data', (value) =>
      @coords[name] = value
      @sendOutput()
    @inPorts[name].on 'disconnect', () =>
      @outPorts.vector.disconnect() if @outPorts.vector.isConnected()

  sendOutput: () =>
    return unless @coords.x != null && @coords.y != null
    @outPorts.vector.send({ x: @oldcoords.x - @coords.x, y: @oldcoords.y - @coords.y }) if @outPorts.vector.isAttached()
    for k, v of @coords
      @oldcoords[k] = v
    @coords.x = @coords.y = null
  

exports.getComponent = -> new CoordsToVector
