noflo = require 'noflo'

class WindowGridPlacer extends noflo.Component
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
      placedwindow: new noflo.ArrayPort 'object'
      placedbox: new noflo.ArrayPort 'object'
      unplacedwindow: new noflo.ArrayPort 'object'

    @connectDataPort('window', @inPorts.window)
    @connectDataPort('windows', @inPorts.windows)
    @connectDataPort('areaWidth', @inPorts.areawidth)
    @connectDataPort('areaHeight', @inPorts.areaheight)
    @connectParamPort('xDiv', @inPorts.xdiv)
    @connectParamPort('yDiv', @inPorts.ydiv)

    @windows = []

    @Clutter = imports.gi.Clutter
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

  ###########################################

  getPositions: () =>
    xDiv = @xDiv
    yDiv = @yDiv

    nbWindows = @windows.length
    nbWindows += 1 if @windows.indexOf(@window) < 0

    if (@areaWidth / nbWindows) >= @xDiv
      if nbWindows < 2
        xDiv = @areaWidth
      else
        xDiv = Math.floor(@areaWidth / nbWindows)
      yDiv = @areaHeight

    ret = []
    for y in [0..(@areaHeight - @yDiv)] by yDiv
      for x in [0..(@areaWidth - @xDiv)] by xDiv
        ret.push({ x: x, y: y, width: xDiv, height: yDiv })
    return ret

  intersects: (win, box) =>
    dest_x = Math.max(win.x, box.x)
    dest_y = Math.max(win.y, box.y)
    dest_x2 = Math.min(win.x + win.width, box.x + box.width)
    dest_y2 = Math.min(win.y + win.height, box.y + box.height)
    return true if dest_x2 > dest_x && dest_y2 > dest_y
    return false

  intersectsWindows: (box, except) =>
    for w in @windows
      continue if w == except
      return true if @intersects(w, box)
    return false

  placeWindow: () =>
    return unless @windows != null && @window != null
    return unless @areaWidth != null && @areaHeight != null
    return unless @xDiv != null && @yDiv != null

    positions = @getPositions()

    win = @window
    @window = null

    for pos in positions
      continue if @intersectsWindows(pos, win)
      @outPorts.placedbox.send(pos) if @outPorts.placedbox.isAttached()
      @outPorts.placedwindow.send(win) if @outPorts.placedwindow.isAttached()
      @outPorts.placedwindow.disconnect() if @outPorts.placedwindow.isConnected()
      @outPorts.placedbox.disconnect() if @outPorts.placedbox.isConnected()
      return

    if @outPorts.unplacedwindow.isAttached()
      @outPorts.unplacedwindow.send(win)
      @outPorts.unplacedwindow.disconnect()

exports.getComponent = -> new WindowGridPlacer
