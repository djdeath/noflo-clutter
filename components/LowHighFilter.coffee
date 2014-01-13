noflo = require 'noflo'

class LowHighFilter extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      low: new noflo.Port 'number'
      high: new noflo.Port 'number'
      in: new noflo.Port 'number'

    @outPorts =
      out: new noflo.ArrayPort 'number'

    for item, port of @inPorts
      @connectPort(item, port)

    @inPorts.in.on 'disconnect', =>
      @outPorts.out.disconnect() if @outPorts.out.isConnected()

  connectPort: (item, port) =>
    this[item] = null
    port.on 'data', (value) =>
      this[item] = value
      @sendOutput()

  sendOutput: =>
    return unless @low != null && @high != null && @in != null
    @outPorts.out.send(Math.max(Math.min(@in, @high), @low)) if @outPorts.out.isAttached()

exports.getComponent = -> new LowHighFilter
