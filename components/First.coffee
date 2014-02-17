noflo = require 'noflo'

class First extends noflo.Component
  description: 'produce output only for the first received data'
  constructor: ->
    @inPorts =
      in: new noflo.Port 'all'
    @outPorts =
      out: new noflo.ArrayPort 'all'

    @gotData = false

    @inPorts.in.on 'data', (data) =>
      return if @gotData
      @gotData = true
      @outPorts.out.send(data) if @outPorts.out.isAttached()

  shutdown: () =>
    @gotData = false

exports.getComponent = -> new First
