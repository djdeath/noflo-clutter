noflo = require 'noflo'

class FilterMoveResizeWindow extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      in: new noflo.Port 'object'

    @outPorts =
      out: new noflo.ArrayPort 'object'

    @window = null

    @inPorts.in.on 'data', (win) =>
      return if @window
      return if win.maximized || win.minimized || win.get_transition('x') != null
      @window = win
      @window.setMoveResize(true)
      @outPorts.out.send(win) if @outPorts.out.isAttached()

    @inPorts.in.on 'disconnect', () =>
      return unless @window
      @window.setMoveResize(false)
      @window = null
      @outPorts.out.disconnect() if @outPorts.out.isConnected()

exports.getComponent = -> new FilterMoveResizeWindow
