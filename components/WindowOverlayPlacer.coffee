noflo = require 'noflo'

class WindowOverlayPlacer extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      window: new noflo.Port 'object'
      windows: new noflo.Port 'object'
      areawidth: new noflo.Port 'number'
      areaheight: new noflo.Port 'number'

    @outPorts =
      placedbox: new noflo.ArrayPort 'object'
      placedwindow: new noflo.ArrayPort 'object'
      unplacedwindow: new noflo.ArrayPort 'object'

    @inPorts.windows.on 'data', (windows) =>
      @windows = windows

    @inPorts.areawidth.on 'data', (width) =>
      @areaWidth = width

    @inPorts.areaheight.on 'data', (height) =>
      @areaHeight = height

    @inPorts.window.on 'data', (win) =>
      @placeWindow(win)

    class @Box
      constructor: (x, y, width, height) ->
        @x = x
        @y = y
        @width = width
        @height = height

      intersects: (box) =>
        dest_x = Math.max(@x, box.x)
        dest_y = Math.max(@y, box.y)
        dest_x2 = Math.min(@x + @width, box.x + box.width)
        dest_y2 = Math.min(@y + @height, box.y + box.height)
        return true if dest_x2 > dest_x && dest_y2 > dest_y
        return false

  getOccupiedBoxes: (win) =>
    ret = []
    for w in @windows
      if win != w
        ret.push(new @Box(w.x, w.y, w.width, w.height))
    ret

  intersectsBoxes: (box, boxes) =>
    for b in boxes
      return true if box.intersects(b)
    return false

  fitsWindowArea: (box) =>
    return box.x >= 0 && box.y >= 0 && (box.x + box.width) <= @areaWidth && (box.y + box.height) <= @areaHeight

  emitPosition: (win, box) =>
    log('new window position ' + box.x + ' ' + box.y + ' - ' + win)
    if @outPorts.placedwindow.isAttached()
      @outPorts.placedwindow.send(win)
      if @outPorts.placedbox.isAttached()
        @outPorts.placedbox.send(box)
        @outPorts.placedbox.disconnect()
      @outPorts.placedwindow.disconnect()

  emitNoPosition: (win) =>
    log('could not find a position')
    if @outPorts.unplacedwindow.isAttached()
      @outPorts.unplacedwindow.send(win)
      @outPorts.unplacedwindow.disconnect()

  placeWindow: (win) =>
    if @windows == null && @windows.length <= 1
      @emitPosition(win, { x: win.x, y: win.y, width: win.minimumWidth, height: win.minimumHeight, })
      return

    winBox = new @Box(win.x, win.y, win.width, win.height)
    boxes = @getOccupiedBoxes(win)
    for b in boxes
      # Try below
      winBox.x = b.x
      winBox.y = b.y + b.height
      if @fitsWindowArea(winBox) && !@intersectsBoxes(winBox, boxes)
        @emitPosition(win, winBox)
        return
    for b in boxes
      # Try right
      winBox.x = b.x + b.width
      winBox.y = b.y
      if @fitsWindowArea(winBox) && !@intersectsBoxes(winBox, boxes)
        @emitPosition(win, winBox)
        return
    for b in boxes
      # Try above
      winBox.x = b.x
      winBox.y = b.y - winBox.height
      if @fitsWindowArea(winBox) && !@intersectsBoxes(winBox, boxes)
        @emitPosition(win, winBox)
        return
    for b in boxes
      # Try left
      winBox.x = b.x - winBox.width
      winBox.y = b.y
      if @fitsWindowArea(winBox) && !@intersectsBoxes(winBox, boxes)
        @emitPosition(win, winBox)
        return
    @emitNoPosition(win)

exports.getComponent = -> new WindowOverlayPlacer
