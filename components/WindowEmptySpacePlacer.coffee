noflo = require 'noflo'

class WindowEmptySpacePlacer extends noflo.Component
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

  intersects: (box1, box2) =>
    dest_x = Math.max(box1.x, box2.x)
    dest_y = Math.max(box1.y, box2.y)
    dest_x2 = Math.min(box1.x + box1.width, box2.x + box2.width)
    dest_y2 = Math.min(box1.y + box1.height, box2.y + box2.height)
    return true if dest_x2 > dest_x && dest_y2 > dest_y
    return false

  getLeftBox: (parentBox, win) =>
    return @Util.copy(parentBox) unless @intersects(parentBox, win)
    box =
      x: parentBox.x
      y: parentBox.y
      width: Math.min(Math.max(0, win.x - parentBox.x), parentBox.width)
      height: parentBox.height

  getRightBox: (parentBox, win) =>
    return @Util.copy(parentBox) unless @intersects(parentBox, win)
    box =
      x: Math.min(Math.max(parentBox.x, win.x + win.width), parentBox.x + parentBox.width)
      y: parentBox.y
      width: Math.min(Math.max(0, parentBox.width - (win.x + win.width)), parentBox.width)
      height: parentBox.height

  getTopBox: (parentBox, win) =>
    return @Util.copy(parentBox) unless @intersects(parentBox, win)
    box =
      x: parentBox.x
      y: parentBox.y
      width: parentBox.width
      height: Math.min(Math.max(0, win.y - parentBox.y), parentBox.height)

  getBottomBox: (parentBox, win) =>
    return @Util.copy(parentBox) unless @intersects(parentBox, win)
    box =
      x: parentBox.x
      y: Math.min(Math.max(parentBox.y, win.y + win.height), parentBox.y + parentBox.height)
      width: parentBox.width
      height: Math.min(Math.max(0, parentBox.height - (win.y + win.height)), parentBox.height)

  getBiggestBox: (box1, box2) =>
    box1Valid = (box1.width >= @window.minimumWidth) && (box1.height >= @window.minimumHeight)
    box2Valid = (box2.width >= @window.minimumWidth) && (box2.height >= @window.minimumHeight)
    return box1 if box1Valid && !box2Valid
    return box2 if box2Valid && !box1Valid
    return box1 if (box1.width * box1.height) > (box2.width * box2.height)
    return box2

  subtractWindowToList: (windows, win) =>
    newList = []
    for w in windows
      newList.push(w) if w != win
    return newList

  bailNonIntersectingWindows: (windows, box) =>
    newList = []
    for w in windows
      newList.push(w) if @intersects(w, box)
    return newList

  findBiggestPlace: (windows, box) =>
    return box if windows.length < 1
    return @biggest if box.width * box.height <= @biggest.width * @biggest.height

    win = windows[0]
    sublist = @subtractWindowToList(windows, win)

    tmpBox = @getLeftBox(box, win)
    @biggest = @getBiggestBox(@findBiggestPlace(@bailNonIntersectingWindows(sublist, tmpBox), tmpBox), @biggest)
    tmpBox = @getRightBox(box, win)
    @biggest = @getBiggestBox(@findBiggestPlace(@bailNonIntersectingWindows(sublist, tmpBox), tmpBox), @biggest)
    tmpBox = @getTopBox(box, win)
    @biggest = @getBiggestBox(@findBiggestPlace(@bailNonIntersectingWindows(sublist, tmpBox), tmpBox), @biggest)
    tmpBox = @getBottomBox(box, win)
    @biggest = @getBiggestBox(@findBiggestPlace(@bailNonIntersectingWindows(sublist, tmpBox), tmpBox), @biggest)
    return @biggest

  placeWindow: () =>
    return unless @windows != null && @window != null
    return unless @areaWidth != null && @areaHeight != null

    # TODO: the algorithm complexity is n! (even though we're trying
    # to optimize as much as possible...), so it could be a good idea
    # to bail out around @windows.length > 5/6

    @offset = 0
    @biggest =
      x: 0
      y: 0
      width: 0
      height: 0
    box = @findBiggestPlace(@subtractWindowToList(@windows, @window), { x: 0, y: 0, width: @areaWidth, height: @areaHeight, })

    win = @window
    @window = null

    # Emit result
    if box.width >= win.minimumWidth && box.height >= win.minimumHeight
      @outPorts.placedwindow.send(win) if @outPorts.placedwindow.isAttached()
      @outPorts.placedbox.send(box) if @outPorts.placedbox.isAttached()
      @outPorts.placedwindow.disconnect() if @outPorts.placedwindow.isConnected()
      @outPorts.placedbox.disconnect() if @outPorts.placedbox.isConnected()
    else
      if @outPorts.unplacedwindow.isAttached()
        @outPorts.unplacedwindow.send(win)
        @outPorts.unplacedwindow.disconnect()

exports.getComponent = -> new WindowEmptySpacePlacer
