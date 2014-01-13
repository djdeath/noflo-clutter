noflo = require 'noflo'

class WindowNoWindowPlacer extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      windows: new noflo.Port 'object'
      window: new noflo.Port 'object'
      areawidth: new noflo.Port 'number'
      areaheight: new noflo.Port 'number'

    @outPorts =
      placedwindow: new noflo.ArrayPort 'object'
      placedbox: new noflo.ArrayPort 'object'
      unplacedwindow: new noflo.ArrayPort 'object'


    @connectDataPort('window', @inPorts.window)
    @connectDataPort('windows', @inPorts.windows)
    @connectDataPort('areaWidth', @inPorts.areawidth)
    @connectDataPort('areaHeight', @inPorts.areaheight)

    @windows = []

    @Util = imports.util

  connectDataPort: (name, port) =>
    this[name] = null
    port.on 'data', (value) =>
      this[name] = value
      @placeWindow()
    port.on 'disconnect', () =>
      this[name] = null

  connectParamPort: (name, port) =>
    this[name] = null
    port.on 'data', (value) =>
      this[name] = value
      @placeWindow()

  placeWindow: () =>
    return unless @windows != null && @window != null
    return unless @areaWidth != null && @areaHeight != null

    box = null
    if @windows.length < 1 || (@windows.length == 1 && @windows[0] == @window)
      box =
        x: 0
        y: 0
        width: @areaWidth
        height: @areaHeight

    win = @window
    @window = null

    # Emit result
    if box
      @outPorts.placedwindow.send(win) if @outPorts.placedwindow.isAttached()
      @outPorts.placedbox.send(box) if @outPorts.placedbox.isAttached()
      @outPorts.placedwindow.disconnect() if @outPorts.placedwindow.isConnected()
      @outPorts.placedbox.disconnect() if @outPorts.placedbox.isConnected()
    else
      if @outPorts.unplacedwindow.isAttached()
        @outPorts.unplacedwindow.send(win)
        @outPorts.unplacedwindow.disconnect()

exports.getComponent = -> new WindowNoWindowPlacer
