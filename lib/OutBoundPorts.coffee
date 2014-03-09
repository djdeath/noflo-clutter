noflo = require 'noflo'

class OutBoundPorts extends noflo.OutPorts
  add: (name, options, process) ->
    super(name, options, process)
    if options.getValue
      @on(name, 'attach', (socket) =>
        return unless socket.from.process.component.inPorts.isReady()
        socket.send(options.getValue())
        socket.disconnect())

module.exports = OutBoundPorts
