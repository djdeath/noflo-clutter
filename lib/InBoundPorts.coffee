noflo = require 'noflo'

class InBoundPorts extends noflo.InPorts
  add: (name, options, process) ->
    super(name, options, process)
    @ready = false
    if options.setValue
      @on(name, 'data', (data) =>
        @gotData(data)
        options.setValue(data))
    else
      @once(name, 'data', (data) => @gotData())

  gotData: (data) ->
    @ready = true

  isReady: () ->
    return @ready

  reset: () ->
    @ready = false

module.exports = InBoundPorts
