noflo = require 'noflo'

class GhostWindowDisplayer extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      ghostwindow: new noflo.Port 'object'
      window: new noflo.Port 'object'
      box: new noflo.Port 'object'

    @connectPort('ghostWindow', @inPorts.ghostwindow)
    @connectPort('window', @inPorts.window)
    @connectPort('box', @inPorts.box)

    @inPorts.window.on 'disconnect', () =>
      @ghostWindow.hide() if @ghostWindow
      @window = null

    @inPorts.box.on 'disconnect', () =>
      @ghostWindow.hide() if @ghostWindow
      @box = null

  connectPort: (item, port) =>
    this[item] = null
    port.on 'data', (value) =>
      this[item] = value
      @displayGhostWindow()

  displayGhostWindow: () =>
    return unless @ghostWindow != null && @window != null && @box != null

    for k, v of @box
      @ghostWindow[k] = v
    @ghostWindow.setTitle(@window.getTitle())
    @ghostWindow.setApplicationId(@window.getApplicationId())
    @ghostWindow.show()

exports.getComponent = -> new GhostWindowDisplayer
