noflo = require 'noflo'

class ResizeDependingWindows extends noflo.Component
  description: ''

  constructor: ->
    @inPorts =
      windows: new noflo.Port 'object'

      ratiox: new noflo.Port 'number'
      ratioy: new noflo.Port 'number'
      areawidth: new noflo.Port 'number'
      areaheight: new noflo.Port 'number'

      resized: new noflo.Port 'object'
      x: new noflo.Port 'number'
      y: new noflo.Port 'number'
      width: new noflo.Port 'number'
      height: new noflo.Port 'number'

    @outPorts =
      dependingwindows: new noflo.ArrayPort 'object'

      resizetree: new noflo.ArrayPort 'object'
      resizebox: new noflo.ArrayPort 'object'
      resizeratiox: new noflo.ArrayPort 'number'
      resizeratioy: new noflo.ArrayPort 'number'

      x: new noflo.ArrayPort 'number'
      y: new noflo.ArrayPort 'number'
      width: new noflo.ArrayPort 'number'
      height: new noflo.ArrayPort 'number'

      area: new noflo.ArrayPort 'object'

      # debug ports
      xx: new noflo.ArrayPort 'number'
      xy: new noflo.ArrayPort 'number'
      xwidth: new noflo.ArrayPort 'number'
      xheight: new noflo.ArrayPort 'number'

      yx: new noflo.ArrayPort 'number'
      yy: new noflo.ArrayPort 'number'
      ywidth: new noflo.ArrayPort 'number'
      yheight: new noflo.ArrayPort 'number'

      maxresizex: new noflo.ArrayPort 'number'
      maxresizey: new noflo.ArrayPort 'number'
      maxresizewidth: new noflo.ArrayPort 'number'
      maxresizeheight: new noflo.ArrayPort 'number'

    @Lang = imports.lang
    @DependencyTree = imports.dependencyTree
    @Util = imports.util

    @connectPort('windows', @inPorts.windows)
    @connectPort('areaWidth', @inPorts.areawidth)
    @connectPort('areaHeight', @inPorts.areaheight)
    @connectPort('ratioX', @inPorts.ratiox)
    @connectPort('ratioY', @inPorts.ratioy)
    @connectPort('x', @inPorts.x)
    @connectPort('y', @inPorts.y)
    @connectPort('width', @inPorts.width)
    @connectPort('height', @inPorts.height)

    @window = null
    @inPorts.resized.on 'data', (win) =>
      @window = win
      @storeWindows()
      @outPorts.area.send(@window.get_parent()) if @outPorts.area.isAttached()
      @recomputeImpactedWindows()

    @inPorts.resized.on 'disconnect' , () =>
      @x = @y = @width = @height = @window = null
      @ratioX = @ratioY = null
      @disconnectPorts()

  connectPort: (name, port) =>
    this[name] = null
    port.on 'data', (value) =>
      this[name] = value
      @recomputeImpactedWindows()

  disconnectPorts: () =>
    for name, port of @outPorts
      port.disconnect() if port.isConnected()

  cleanupTrees: () =>
    for id, tree of @windowsTrees
      tree.cleanImpacts()
      tree.cleanCached()
      if id != @window.getId()
        tree.saveCurrentState()
    state = @windowsTrees[@window.getId()].currentState
    state.x = @x
    state.y = @y
    state.width = @width
    state.height = @height

  storeWindows: () =>
    @windowsTrees = {}
    for win in @windows
      @windowsTrees[win.getId()] = new @DependencyTree.DependencyTree({ window: win })

  getWindowBox: (win) =>
    return @windowsTrees[win.getId()].currentState

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
      box.x1 = winbox.x# + winbox.width
      box.x2 = @areaWidth
    if ratioX == 0
      box.x1 = winbox.x
      box.x2 = winbox.x + winbox.width
    if ratioY < 0
      box.y1 = 0
      box.y2 = winbox.y + winbox.height
    if ratioY > 0
      box.y1 = winbox.y# + winbox.height
      box.y2 = @areaHeight
    if ratioY == 0
      box.y1 = winbox.y
      box.y2 = winbox.y + winbox.height
    return box2 =
      x: box.x1
      y: box.y1
      width: box.x2 - box.x1
      height: box.y2 - box.y1

  isOverX: (winObj1, winObj2) =>
    win1 = @getWindowBox(winObj1)
    win2 = @getWindowBox(winObj2)
    x = Math.min(Math.abs(win1.x + win1.width - win2.x), Math.abs(win1.x - win2.x - win2.width))
    y = Math.min(Math.abs(win1.y + win1.height - win2.y), Math.abs(win1.y - win2.y - win2.height))
    return x < y

  isImpacted: (winObj, box) =>
    win = @getWindowBox(winObj)
    dest_x = Math.max(win.x, box.x)
    dest_y = Math.max(win.y, box.y)
    dest_x2 = Math.min(win.x + win.width, box.x + box.width)
    dest_y2 = Math.min(win.y + win.height, box.y + box.height)
    return true if dest_x2 > dest_x && dest_y2 > dest_y
    return false

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
      if xImpacted && yImpacted
        if subtree.firstImpactX != undefined
          if subtree.firstImpactX == true
            tree.addXImpact(@_getImpactTree(w, ratioX, 0))
          else
            tree.addYImpact(@_getImpactTree(w, 0, ratioY))
        else if @isOverX(win, w)
          if ratioX
            tree.addXImpact(@_getImpactTree(w, ratioX, 0))
            subtree.firstImpactX = true
        else
          if ratioY
            tree.addYImpact(@_getImpactTree(w, 0, ratioY))
            subtree.firstImpactX = false
      else
        if xImpacted
          if ratioX
            tree.addXImpact(@_getImpactTree(w, ratioX, 0))
            subtree.firstImpactX = true
        else if yImpacted
          if ratioY
            tree.addYImpact(@_getImpactTree(w, 0, ratioY))
            subtree.firstImpactX = false
        else
          delete @window.firstImpactX
    delete @impactWindowTree[tree.window.getId()]

    return tree

  getImpactTree: (win, ratioX, ratioY) =>
    @impactWindowTree = {}
    ret = @_getImpactTree(win, ratioX, ratioY)
    @impactWindowTree = {}
    return ret

  levelToSpace: (level) =>
    ret = ''
    for i in [0..level]
      ret += '   '
    return ret

  treeToList: (tree, level, axis) =>
    #log(@levelToSpace(level) + axis + ' - ' +  tree.id)
    ret = if level != 0 then [tree.window] else []
    return ret if tree.xImpacts.length < 1 && tree.yImpacts.length < 1
    for subtree in tree.xImpacts
      ret = ret.concat(@treeToList(subtree, level + 1, 'axis-x'))
    for subtree in tree.yImpacts
      ret = ret.concat(@treeToList(subtree, level + 1, 'axis-y'))
    return ret

  subResizeBox: (box, ratioX, ratioY) =>
    if ratioX < 0
      return b =
        x: 0
        y: -1
        width: box.x
        height: -1
    else if ratioX > 0
      return b =
        x: box.x + box.width
        y: -1
        width: @areaWidth - (box.x + box.width)
        height: -1
    else if ratioY < 0
      return b =
        x: -1
        y: 0
        width: -1
        height: box.y
    else if ratioY > 0
      return b =
        x: -1
        y: box.y + box.height
        width: -1
        height: @areaHeight - (box.y + box.height)

  recomputeImpactedWindows: () =>
    return unless @x != null && @y != null
    return unless @width != null && @height != null
    return unless @window != null
    return unless @ratioX != null && @ratioY != null
    return unless @areaWidth != null && @areaHeight != null

    @cleanupTrees()
    boxx = @getImpactBox(@window, @ratioX, 0)
    boxy = @getImpactBox(@window, 0, @ratioY)

    # Send impact display area first (debug)
    @outPorts.xx.send(boxx.x) if @outPorts.xx.isAttached()
    @outPorts.xy.send(boxx.y) if @outPorts.xy.isAttached()
    @outPorts.xwidth.send(boxx.width) if @outPorts.xwidth.isAttached()
    @outPorts.xheight.send(boxx.height) if @outPorts.xheight.isAttached()

    @outPorts.yx.send(boxy.x) if @outPorts.yx.isAttached()
    @outPorts.yy.send(boxy.y) if @outPorts.yy.isAttached()
    @outPorts.ywidth.send(boxy.width) if @outPorts.ywidth.isAttached()
    @outPorts.yheight.send(boxy.height) if @outPorts.yheight.isAttached()

    # Compute impacted windows
    tree = @getImpactTree(@window, @ratioX, @ratioY)
    #tree.print()

    # Send limited resize size
    if @ratioX < 0
      minWidth = tree.getSubTreeMinimumWidth()
      boxx.x += minWidth
      boxx.width = boxx.width - minWidth
    else if @ratioX > 0
      minWidth = tree.getSubTreeMinimumWidth()
      boxx.width = boxx.width - minWidth
    else
      boxx.x = tree.currentState.x
      boxx.width = tree.currentState.width

    if @ratioY < 0
      minHeight = tree.getSubTreeMinimumHeight()
      boxy.y += minHeight
      boxy.height = boxy.height - minHeight
    else if @ratioY > 0
      minHeight = tree.getSubTreeMinimumHeight()
      boxy.height = boxy.height - minHeight
    else
      boxy.y = tree.currentState.y
      boxy.height = tree.currentState.height
    windowNewState =
      x: Math.max(boxx.x, @x)
      y: Math.max(boxy.y, @y)
      width: Math.min(boxx.width, @width)
      height: Math.min(boxy.height, @height)
    for k, v of windowNewState
      @outPorts[k].send(v) if @outPorts[k].isAttached()

    # Send tree to resize
    @outPorts.resizetree.send(tree) if @outPorts.resizetree.isAttached()

    # Send box for resizing tree
    @outPorts.resizebox.send(@subResizeBox(windowNewState, @ratioX, 0)) if @outPorts.resizebox.isAttached()
    @outPorts.resizeratiox.send(@ratioX) if @outPorts.resizeratiox.isAttached()
    @outPorts.resizeratioy.send(0) if @outPorts.resizeratioy.isAttached()
    @outPorts.resizebox.disconnect() if @outPorts.resizebox.isConnected()
    @outPorts.resizeratiox.disconnect() if @outPorts.resizeratiox.isConnected()
    @outPorts.resizeratioy.disconnect() if @outPorts.resizeratioy.isConnected()

    @outPorts.resizebox.send(@subResizeBox(windowNewState, 0, @ratioY)) if @outPorts.resizebox.isAttached()
    @outPorts.resizeratiox.send(0) if @outPorts.resizeratiox.isAttached()
    @outPorts.resizeratioy.send(@ratioY) if @outPorts.resizeratioy.isAttached()
    @outPorts.resizebox.disconnect() if @outPorts.resizebox.isConnected()
    @outPorts.resizeratiox.disconnect() if @outPorts.resizeratiox.isConnected()
    @outPorts.resizeratioy.disconnect() if @outPorts.resizeratioy.isConnected()

    # Send maximum size (debug)
    @outPorts.maxresizex.send(boxx.x) if @outPorts.maxresizex.isAttached()
    @outPorts.maxresizey.send(boxy.y) if @outPorts.maxresizey.isAttached()
    @outPorts.maxresizewidth.send(boxx.width) if @outPorts.maxresizewidth.isAttached()
    @outPorts.maxresizeheight.send(boxy.height) if @outPorts.maxresizeheight.isAttached()

    # Optimize emission by waiting for another (x,y,width,height) set
    # before doing any computation
    @x = @y = @width = @height = null

exports.getComponent = -> new ResizeDependingWindows
