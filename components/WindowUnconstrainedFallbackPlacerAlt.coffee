noflo = require 'noflo'

class WindowUnconstrainedFallbackPlacerAlt extends noflo.Component
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

  nbWindows: () =>
    nbWindows = @windows.length
    nbWindows += 1 if @windows.indexOf(@window) < 0
    return nbWindows

  getSortedWindows: () =>
    sortedList = @Util.copyList(@windows)
    sortedList.sort((a, b) =>
      ret = a.x - b.x
      return ret if ret != 0
      return a.y - b.y)
    return sortedList

  getDividerPositions: () =>
    xDiv = @xDiv
    yDiv = @yDiv

    nbWindows = @nbWindows()

    if (@areaWidth / nbWindows) >= @xDiv
      if nbWindows < 2
        xDiv = @areaWidth
      else
        xDiv = Math.floor(@areaWidth / nbWindows)
      yDiv = @areaHeight

    ret = []
    for y in [0..(@areaHeight - yDiv)] by yDiv
      for x in [0..(@areaWidth - xDiv)] by xDiv
        ret.push({ x: x, y: y, width: xDiv, height: yDiv })

    return ret

  getWindowsBoxes: () =>
    ret = []
    for w in @windows
      ret.push({ id: w.getId(), x: w.x, y: w.y, width: w.width, height: w.height })
    ret.sort((a, b) =>
      res = (b.width * b.height) - (a.width * a.height)
      return res if res != 0
      return b.x - a.x)
    return ret

  boxesInContact: (box1, box2) =>
    if (box1.x + box1.width) == box2.x or (box2.x + box2.width) == box1.x
      return true if box1.y == box2.y
    else if (box1.y + box1.height) == box2.y or (box2.y + box2.height) == box1.y
      return true if box1.x == box2.x
    return false

  findClosestBox: (boxes, box) =>
    boxX = box.x + box.width / 2
    boxY = box.y + box.height / 2
    boxes.sort((a, b) =>
      dax = boxX - (a.x + a.width / 2)
      day = boxY - (a.y + a.height / 2)
      dbx = boxX - (b.x + b.width / 2)
      dby = boxY - (b.y + b.height / 2)
      return (dax * dax + day * day) - (dbx * dbx + dby * dby))
    return boxes.splice(0, 1)[0]

  getPositions: () =>
    divisions = @getDividerPositions()
    windows = @getWindowsBoxes()
    newBoxes = []

    nbWindows = @nbWindows()

    # Merge n divisions with n the difference between the number of
    # windows and the number of basic divisions
    nbIterations = divisions.length - nbWindows
    if nbIterations > 0
      for i in [0..(nbIterations - 1)]
        break if windows.length < 0
        tmp = []
        winBox = windows.shift()
        box1 = @findClosestBox(divisions, winBox)
        while divisions.length > 0
          box2 = @findClosestBox(divisions, winBox)
          if @boxesInContact(box1, box2)
            newBoxes.push({
              x: Math.min(box1.x, box2.x)
              y: Math.min(box1.y, box2.y),
              width: (if (box1.x == box2.x) then box1.width else (box1.width + box2.width))
              height: (if (box1.y == box2.y) then box1.height else (box1.height + box2.height)) })
            break
          tmp.push(box2)
        divisions = divisions.concat(tmp)

    # return the concatenation of unmerged divisions and the newly
    # created ones.
    return divisions.concat(newBoxes)

  findClosestPosition: (win, positions) =>
    positions.sort((a, b) =>
      dax = a.x - win.x
      day = a.y - win.y
      dbx = b.x - win.x
      dby = b.y - win.y
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

    tmpWindow = @window
    @window = null

    if positions.length > 0
      # sort remaining positions by top->bottom left->right order
      positions.sort((a, b) =>
        ret = a.y - b.y
        return ret if ret != 0
        return a.x - b.x)
      @outPorts.placedbox.send(positions[0]) if @outPorts.placedbox.isAttached()
      @outPorts.placedwindow.send(tmpWindow) if @outPorts.placedwindow.isAttached()
    else
      log('No more room to place ' + tmpWindow)


exports.getComponent = -> new WindowUnconstrainedFallbackPlacerAlt
