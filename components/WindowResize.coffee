noflo = require 'noflo'

class WindowResize extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      window: new noflo.Port 'object'
      ratiox: new noflo.Port 'number'
      ratioy: new noflo.Port 'number'
      x: new noflo.Port 'number'
      y: new noflo.Port 'number'

    @outPorts =
      x: new noflo.ArrayPort 'number'
      y: new noflo.ArrayPort 'number'
      width: new noflo.ArrayPort 'number'
      height: new noflo.ArrayPort 'number'

    for item, port of @inPorts
      @connectPort(item, port)

    @onDisconnect('window', @inPorts.window)

  connectPort: (name, port) =>
    this[name] = null
    port.on 'data', (value) =>
      this[name] = value
      @generateOutput()
    port.on 'disconnect', () =>
      this[name] = null

  onDisconnect: (name, port) =>
    port.on 'disconnect', () =>
      this[name] = null
      @disconnectOutputs()

  disconnectOutputs: () =>
    for item, port of @outPorts
      port.disconnect()

  generateOutput: () =>
    return unless @window != null
    return unless @ratiox != null && @ratioy != null
    return unless @x != null && @y != null
    rets =
      x: if @ratiox < 0 then (if @x < 0 then -(@x * @ratiox) else -(@x * @ratiox)) else 0
      y: if @ratioy < 0 then (if @y < 0 then -(@y * @ratioy) else -(@y * @ratioy)) else 0
      width: @ratiox * @x
      height: @ratioy * @y
    for item, value of rets
      @outPorts[item].send(value) if @outPorts[item].isAttached()
    @x = @y = null

exports.getComponent = -> new WindowResize
