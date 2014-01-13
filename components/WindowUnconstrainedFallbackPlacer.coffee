noflo = require 'noflo'

class WindowUnconstrainedFallbackPlacer extends noflo.Component
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

  getSortedWindows: () =>
    sortedList = @Util.copyList(@windows)
    sortedList.sort((a, b) =>
      ret = a.x - b.x
      return ret if ret != 0
      return a.y - b.y)
    return sortedList

  getPositions: () =>
    ret = []
    maxWidth = if (@areaWidth % @xDiv) == 0 then @areaWidth else (@areaWidth - @xDiv)
    maxHeight = if (@areaHeight % @yDiv) == 0 then @areaHeight else (@areaHeight - @yDiv)
    for y in [0..(@areaHeight - @yDiv)] by @yDiv
      for x in [0..(@areaWidth - @xDiv)] by @xDiv
        ret.push({ x: x, y: y, width: @xDiv, height: @yDiv })
    return ret

  findClosestPosition: (win, positions) =>
    distance = (box1, box2) =>
      x1 = box1.x + box1.width / 2
      y1 = box1.y + box1.height / 2
      x2 = box2.x + box2.width / 2
      y2 = box2.y + box2.height / 2
      return (x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2)
    x = win.x + (win.width / 2)
    y = win.y + (win.height / 2)
    positions.sort((a, b) =>
      dax = (a.x + (a.width / 2)) - x
      day = (a.y + (a.height / 2)) - y
      dbx = (b.x + (b.width / 2)) - x
      dby = (b.y + (b.height / 2)) - y
      return (dax * dax + day * day) - (dbx * dbx + dby * dby))
    return positions.splice(0, 1)[0]

  placeWindow: () =>
    return unless @windows != null && @window != null
    return unless @areaWidth != null && @areaHeight != null
    return unless @xDiv != null && @yDiv != null

    sortedWindows = @getSortedWindows()
    positions = @getPositions()

    for w in sortedWindows
      continue if w == @window
      pos = @findClosestPosition(w, positions)
      w.save_easing_state()
      w.set_easing_duration(150)
      w.set_easing_mode(@Clutter.AnimationMode.LINEAR)
      w.x = pos.x
      w.y = pos.y
      w.width = pos.width
      w.height = pos.height
      w.restore_easing_state()

    if positions.length > 0
      @outPorts.placedbox.send(positions[0]) if @outPorts.placedbox.isAttached()
      @outPorts.placedwindow.send(@window) if @outPorts.placedwindow.isAttached()
    else
      log('No more room to place ' + @window)

    @window = null

exports.getComponent = -> new WindowUnconstrainedFallbackPlacer
