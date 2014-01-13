noflo = require 'noflo'

class WindowEnsureNoMaximize extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      maximized: new noflo.Port 'object'
      unmaximized: new noflo.Port 'object'
      destroy: new noflo.Port 'object'
      in: new noflo.Port 'object'

    @outPorts =
      unmaximize: new noflo.ArrayPort 'object'
      out: new noflo.ArrayPort 'object'

    @data = null
    @maximized = null

    @inPorts.in.on 'data', (data) =>
      @data = data
      @sendData()

    @inPorts.maximized.on 'data', (maximized) =>
      @maximized = maximized

    @inPorts.unmaximized.on 'data', (unmaximized) =>
      return unless @maximized == unmaximized
      @maximized = null
      @sendData()

    @inPorts.destroy.on 'data', (destroy) =>
      @maximized = null if @maximized == destroy

  sendData: () =>
    return if @data == null

    if @maximized
      if @outPorts.unmaximize.isAttached()
        @outPorts.unmaximize.send(@maximized)
        @outPorts.unmaximize.disconnect()
      return

    if @outPorts.out.isAttached()
      @outPorts.out.send(@data)
      @outPorts.out.disconnect()
    @data = null

exports.getComponent = -> new WindowEnsureNoMaximize
