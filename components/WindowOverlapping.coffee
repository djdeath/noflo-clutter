noflo = require 'noflo'

class WindowOverlapping extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      windows: new noflo.Port 'object'
      window: new noflo.Port 'object'
      x: new noflo.Port 'number'
      y: new noflo.Port 'number'
      areawidth: new noflo.Port 'number'
      areaheight: new noflo.Port 'number'

    @outPorts =
      highlight: new noflo.ArrayPort 'object'
      fallbackbox: new noflo.ArrayPort 'object'

    @Clutter = imports.gi.Clutter
    @DependencyTree = imports.dependencyTree
    @Util = imports.util

    @connectPort('windows', @inPorts.windows)
    @connectPort('x', @inPorts.x)
    @connectPort('y', @inPorts.y)
    @connectPort('areaWidth', @inPorts.areawidth)
    @connectPort('areaHeight', @inPorts.areaheight)

    @window = null

    @inPorts.window.on 'data', (win) =>
      @storeWindows()
      @window = win

    @inPorts.window.on 'disconnect', () =>
      @window = null
      @disconnectPorts()
      @resetWindowsToOriginIfNeeded()

  connectPort: (name, port) =>
    this[name] = null
    port.on 'data', (value) =>
      this[name] = value
      @sendIntersectWindows()
    port.on 'disconnect', () =>
      this[name] = null
      #@disconnectPorts()
      #@resetWindowsToOriginIfNeeded()

  disconnectPorts: () =>
    for name, port of @outPorts
      port.disconnect() if port.isConnected()

  ###########################################

  storeWindows: () =>
    @windowsTreesLeft = {}
    @windowsTreesRight = {}
    @windowsTreesTop = {}
    @windowsTreesBottom = {}
    @windowsTrees = null
    for w in @windows
      id = w.getId()
      @windowsTreesLeft[id] = new @DependencyTree.DependencyTree({ window: w })
      @windowsTreesRight[id] = new @DependencyTree.DependencyTree({ window: w })
      @windowsTreesTop[id] = new @DependencyTree.DependencyTree({ window: w })
      @windowsTreesBottom[id] = new @DependencyTree.DependencyTree({ window: w })

  cleanTrees: () =>
    for id, tree of @windowsTreesTop
      @windowsTreesLeft[id].cleanImpacts()
      @windowsTreesRight[id].cleanImpacts()
      @windowsTreesTop[id].cleanImpacts()
      @windowsTreesBottom[id].cleanImpacts()

  windowUpdateCurrentState: () =>
    id = @window.getId()
    @windowsTreesLeft[id].currentState.x =
     @windowsTreesRight[id].currentState.x =
     @windowsTreesTop[id].currentState.x =
     @windowsTreesBottom[id].currentState.x = @x
    @windowsTreesLeft[id].currentState.y =
     @windowsTreesRight[id].currentState.y =
     @windowsTreesTop[id].currentState.y =
     @windowsTreesBottom[id].currentState.y = @y

  saveNewValidPositions: (movedWindows) =>
    id = @window.getId()
    @windowsTreesLeft[id].initialState.x =
     @windowsTreesRight[id].initialState.x =
     @windowsTreesTop[id].initialState.x =
     @windowsTreesBottom[id].initialState.x = @windowsTreesTop[id].currentState.x
    @windowsTreesLeft[id].initialState.y =
     @windowsTreesRight[id].initialState.y =
     @windowsTreesTop[id].initialState.y =
     @windowsTreesBottom[id].initialState.y = @windowsTreesTop[id].currentState.y
    for k, e of movedWindows
      @windowsTreesLeft[k].initialState.x =
        @windowsTreesRight[k].initialState.x =
        @windowsTreesTop[k].initialState.x =
        @windowsTreesBottom[k].initialState.x = e.params.x
      @windowsTreesLeft[k].initialState.y =
        @windowsTreesRight[k].initialState.y =
        @windowsTreesTop[k].initialState.y =
        @windowsTreesBottom[k].initialState.y = e.params.y

  getWindowBox: (win) =>
    return @windowsTreesTop[win.getId()].currentState if win == @window
    return @windowsTreesTop[win.getId()].initialState

  getImpactBox: (win, ratioX, ratioY) =>
    box =
      x1: 0
      y1: 0
      x2: 0
      y2: 0
    winbox = @getWindowBox(win)
    if ratioX < 0
      box.x1 = 0
      box.x2 = winbox.x + winbox.width
    if ratioX > 0
      box.x1 = winbox.x
      box.x2 = @areaWidth
    if ratioX == 0
      box.x1 = winbox.x
      box.x2 = winbox.x + winbox.width
    if ratioY < 0
      box.y1 = 0
      box.y2 = winbox.y + winbox.height
    if ratioY > 0
      box.y1 = winbox.y
      box.y2 = @areaHeight
    if ratioY == 0
      box.y1 = winbox.y
      box.y2 = winbox.y + winbox.height
    return box2 =
      x: box.x1
      y: box.y1
      width: box.x2 - box.x1
      height: box.y2 - box.y1

  isImpacted: (winObj, box) =>
    win = @getWindowBox(winObj)
    dest_x = Math.max(win.x, box.x)
    dest_y = Math.max(win.y, box.y)
    dest_x2 = Math.min(win.x + win.width, box.x + box.width)
    dest_y2 = Math.min(win.y + win.height, box.y + box.height)
    return true if dest_x2 > dest_x && dest_y2 > dest_y
    return false

  getMoveDirectionList: (winObj1, winObj2) =>
    win1 = @getWindowBox(winObj1)
    win2 = @getWindowBox(winObj2)
    x = Math.min(Math.abs(win1.x + win1.width - win2.x), Math.abs(win1.x - win2.x - win2.width))
    y = Math.min(Math.abs(win1.y + win1.height - win2.y), Math.abs(win1.y - win2.y - win2.height))
    ret = []
    pushX = () =>
      if win1.x < win2.x
        ret.push([-1, 0])
        ret.push([1, 0])
      else
        ret.push([1, 0])
        ret.push([-1, 0])
    pushY = () =>
      if win1.y < win2.y
        ret.push([0, -1])
        ret.push([0, 1])
      else
        ret.push([0, 1])
        ret.push([0, -1])
    if x < y
      pushX()
      pushY()
    else
      pushY()
      pushX()
    return ret

  directionToBox: (direction) =>
    win = @getWindowBox(@window)
    ret =
      x: -1
      y: -1
      width: -1
      height: -1
    if direction[0] < 0
      ret.x = 0
      ret.width = win.x
    else if direction[0] > 0
      ret.x = win.x + win.width
      ret.width = @areaWidth - (win.x + win.width)
    else if direction[1] < 0
      ret.y = 0
      ret.height = win.y
    else if direction[1] > 0
      ret.y = win.y + win.height
      ret.height = @areaHeight - (win.y + win.height)
    return ret

  _getImpactTree: (win, ratioX, ratioY) =>
    tree = @windowsTrees[win.getId()]

    boxx = @getImpactBox(win, ratioX, 0)
    boxy = @getImpactBox(win, 0, ratioY)

    @impactWindowTree[tree.window.getId()] = tree
    for w in @windows
      continue if @impactWindowTree[w.getId()] != undefined
      # lookahead from last iteration
      subtree = @windowsTrees[w.getId()]
      continue if subtree.hasImpactOn(tree)

      xImpacted = @isImpacted(w, boxx)
      yImpacted = @isImpacted(w, boxy)
      if xImpacted
        if ratioX
          tree.addXImpact(@_getImpactTree(w, ratioX, 0))
      else if yImpacted
        if ratioY
          tree.addYImpact(@_getImpactTree(w, 0, ratioY))
    delete @impactWindowTree[tree.window.getId()]

    return tree

  getImpactTree: (win, ratioX, ratioY) =>
    if ratioX < 0
      @windowsTrees = @windowsTreesLeft
    else if ratioX > 0
      @windowsTrees = @windowsTreesRight
    else if ratioY < 0
      @windowsTrees = @windowsTreesTop
    else if ratioY > 0
      @windowsTrees = @windowsTreesBottom

    @impactWindowTree = {}
    @impactWindowTree[@window.getId()] = @windowsTrees[@window.getId()]
    ret = @_getImpactTree(win, ratioX, ratioY)
    @impactWindowTree = {}

    @windowsTrees = null
    return ret

  ###########################################

  resetWindowToOrigin: (win) =>
    origin = @windowsTreesTop[win.getId()].initialState
    win.save_easing_state()
    win.set_easing_duration(100)
    win.set_easing_mode(@Clutter.AnimationMode.LINEAR)
    win.x = origin.x
    win.y = origin.y
    win.restore_easing_state()

  resetWindowsToOrigin: (includeMovedWindow) =>
    for w in @windows
      continue if !includeMovedWindow && w == @window
      @resetWindowToOrigin(w)

  resetWindowsToOriginIfNeeded: () =>
    return unless @placementError
    @resetWindowsToOrigin(true)
    @placementError = false

  animateWindowsToNewPositions: (movedWindows) =>
    for k, e of movedWindows
      e.window.save_easing_state()
      e.window.set_easing_duration(100)
      e.window.set_easing_mode(@Clutter.AnimationMode.LINEAR)
      for p, v of e.params
        e.window[p] = v
      e.window.restore_easing_state()

  ###########################################

  sendIntersectWindows: () =>
    return unless @windows != null && @window != null
    return unless @areaWidth != null && @areaHeight != null
    return unless @x != null && @y != null

    @cleanTrees()
    @windowUpdateCurrentState()
    @placementError = false

    impactedWindows = []
    resetWindows = []
    box =
      x: @x
      y: @y
      width: @window.width
      height: @window.height
    for w in @windows
      continue if w == @window
      if @isImpacted(w, box)
        impactedWindows.push(w)
      else
        resetWindows.push(w)

    if impactedWindows.length < 1
      #log('no impact')
      @saveNewValidPositions([])
      @resetWindowsToOrigin(false)
      @x = @y = null
      @disconnectPorts()
      return

    moveTrees = []
    for w in impactedWindows
      directions = @getMoveDirectionList(w, @window)
      found = false
      for d in directions
        box = @directionToBox(d)
        tree = @getImpactTree(w, d[0], d[1])
        if tree.canMoveIn(box)
          found = true
          moveTrees.push({ tree: tree, box: box })
          break

      continue if found
      #tree.print()
      #log('cannot find position for ' + w.getId())
      @placementError = true
      break

    if @placementError
      #log('cant place')
      @outPorts.highlight.send([ @window ]) if @outPorts.highlight.isAttached()
      @outPorts.fallbackbox.send(@Util.copy(@windowsTreesTop[@window.getId()].initialState)) if @outPorts.fallbackbox.isAttached()
    else
      movedWindows = {}
      for e in moveTrees
        e.tree.moveTo(movedWindows, e.box, 0)
        list = e.tree.toList()
        #e.tree.fillTable(movedWindows)
      # Reset windows
      for w in resetWindows
        @resetWindowToOrigin(w) unless movedWindows[w.getId()]
      # Animate windows to new positions
      @animateWindowsToNewPositions(movedWindows)
      @saveNewValidPositions(movedWindows)
      @outPorts.highlight.send([]) if @outPorts.highlight.isAttached()
      @outPorts.fallbackbox.disconnect() if @outPorts.fallbackbox.isConnected()

    @x = @y = null


exports.getComponent = -> new WindowOverlapping
