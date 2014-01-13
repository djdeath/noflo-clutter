noflo = require 'noflo'

class WindowUnconstrainedPlacer extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      windows: new noflo.Port 'object'
      window: new noflo.Port 'object'
      areawidth: new noflo.Port 'number'
      areaheight: new noflo.Port 'number'
      xdiv: new noflo.Port 'number'
      ydiv: new noflo.Port 'number'

    @outPorts =
      unplacedwindow: new noflo.ArrayPort 'object'
      placedwindow: new noflo.ArrayPort 'object'
      placedbox: new noflo.ArrayPort 'object'


    @connectDataPort('window', @inPorts.window)
    @connectDataPort('windows', @inPorts.windows)
    @connectDataPort('areaWidth', @inPorts.areawidth)
    @connectDataPort('areaHeight', @inPorts.areaheight)
    @connectParamPort('xDiv', @inPorts.xdiv)
    @connectParamPort('yDiv', @inPorts.ydiv)

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

  isInWindowsArea: (box) =>
    return false if (box.x + box.width) > @areaWidth
    return false if (box.y + box.height) > @areaHeight
    return true

  intersects: (box1, box2) =>
    dest_x = Math.max(box1.x, box2.x)
    dest_y = Math.max(box1.y, box2.y)
    dest_x2 = Math.min(box1.x + box1.width, box2.x + box2.width)
    dest_y2 = Math.min(box1.y + box1.height, box2.y + box2.height)
    return true if dest_x2 > dest_x && dest_y2 > dest_y
    return false

  intersectWindows: (box) =>
    for w in @windows
      continue if w == @window
      if @intersects(w, box)
        return true
    return false

  placeWindow: () =>
    return unless @windows != null && @window != null
    return unless @areaWidth != null && @areaHeight != null
    return unless @xDiv != null && @yDiv != null

    # Try to find a place on the grid
    box = null
    for y in [0..@areaHeight] by @yDiv
      for x in [0..@areaWidth] by @xDiv
        tbox =
          x: x
          y: y
          width: @xDiv
          height: @yDiv
        continue unless @isInWindowsArea(tbox)
        if !@intersectWindows(tbox)
          box = tbox
          break
      if box != null
        break

    # Reset window to avoid cycles
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

exports.getComponent = -> new WindowUnconstrainedPlacer
