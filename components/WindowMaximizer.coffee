noflo = require 'noflo'

class WindowMaximizer extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      windows: new noflo.Port 'object'
      maximize: new noflo.Port 'object'
      unmaximize: new noflo.Port 'object'
      minimize: new noflo.Port 'object'
      unminimize: new noflo.Port 'object'
      new: new noflo.Port 'object'
      select: new noflo.Port 'object'
      destroy: new noflo.Port 'object'
      areawidth: new noflo.Port 'number'
      areaheight: new noflo.Port 'number'

    @outPorts =
      maximized: new noflo.ArrayPort 'object'
      unmaximized: new noflo.ArrayPort 'object'

    @Clutter = imports.gi.Clutter
    @Lang = imports.lang
    @Util = imports.util

    @connectPort('windows', @inPorts.windows)
    @connectPort('areaWidth', @inPorts.areawidth)
    @connectPort('areaHeight', @inPorts.areaheight)

    @windowsStates = {}
    @maximizedStack = []

    @inAnimation = false

    @inPorts.maximize.on 'data', (win) =>
      return unless @windows # Shouldn't happen
      return if win.moveResize
      return if @inAnimation
      @stashWindowStates(win)
      @maximized = win
      @fadeOutWindows()
      @presentMaximized()
      @maximized = null

    @inPorts.unmaximize.on 'data', (win) =>
      return unless @windows # Shouldn't happen
      return if @inAnimation
      @maximized = win
      @fadeInWindows()
      @unpresentMaximized()
      @maximized = null

    @inPorts.new.on 'data', (win) =>
      return unless @windows # Shouldn't happen
      @fadeInWindows()
      @unpresentAllMaximized()

    @inPorts.select.on 'data', (win) =>
      return unless @windows # Shouldn't happen
      return if win.maximized && @maximizedStack[@maximizedStack.length - 1] == win
      @fadeInWindows()
      @unpresentAllMaximized()

    @inPorts.destroy.on 'data', (win) =>
      return unless @windows # Shouldn't happen
      return unless win.maximized
      @dropWindowState(win)
      newtop = @getTopWindow()
      if newtop
        newtop.opacity = 255
      else
        @fadeInWindows()
      @maximized = null

    @inPorts.minimize.on 'data', (win) =>
      return unless @windows # Shouldn't happen
      return unless win.maximized
      @maximized = win
      @unstackWindow(win)
      @fadeInWindows()
      @maximized = null

    @inPorts.unminimize.on 'data', (win) =>
      return unless @windows # Shouldn't happen
      @maximized = win
      if win.maximized
        @stackWindow(win)
        @fadeOutWindows()
      else
        @fadeInWindows()
        @unpresentAllMaximized()
      @maximized = null

  connectPort: (name, port) =>
    this[name] = null
    port.on 'data', (value) =>
      this[name] = value
    port.on 'disconnect', () =>
      this[name] = null

  stackWindow: (win) =>
    @maximizedStack.push(win)

  unstackWindow: (win) =>
    idx = @maximizedStack.indexOf(win)
    @maximizedStack.splice(idx, 1) if idx >= 0

  stashWindowStates: (win) =>
    @windowsStates[win.getId()] =
      x: win.x
      y: win.y
      width: win.width
      height: win.height
    @stackWindow(win)

  dropWindowState: (win) =>
    state = @windowsStates[win.getId()]
    return unless state
    delete @windowsStates[win.getId()]
    @unstackWindow(win)
    return state

  getTopWindow: () =>
    return null if @maximizedStack.length < 1
    return @maximizedStack[@maximizedStack.length - 1]

  fadeOutWindows: () =>
    for w in @windows
      continue if w == @maximized
      w.set_pivot_point(0.5, 0.5)
      w.save_easing_state()
      w.set_easing_duration(250)
      w.set_easing_mode(@Clutter.AnimationMode.EASE_IN_OUT_QUINT)
      w.opacity = 0
      w.scale_x = w.scale_y = 0.8
      w.restore_easing_state()

  fadeInWindows: () =>
    for w in @windows
      continue if w == @maximized
      w.set_pivot_point(0.5, 0.5)
      w.save_easing_state()
      w.set_easing_duration(250)
      w.set_easing_mode(@Clutter.AnimationMode.EASE_OUT_QUINT)
      w.opacity = 255
      w.scale_x = w.scale_y = 1
      w.restore_easing_state()

  presentMaximized: () =>
    return if @maximized.maximized
    @maximized.save_easing_state()
    @maximized.set_easing_duration(250)
    @maximized.set_easing_mode(@Clutter.AnimationMode.EASE_IN_OUT_QUINT)
    @maximized.x = @maximized.y = 0
    @maximized.width = @areaWidth
    @maximized.height = @areaHeight
    @maximized.restore_easing_state()
    tmp = @maximized
    @inAnimation = true
    id = tmp.connect('transition-stopped::x', @Lang.bind(this, () =>
      @inAnimation = false
      tmp.disconnect(id)
      tmp.setMaximized(true)
      if @outPorts.maximized.isAttached()
        @outPorts.maximized.send(tmp)
        @outPorts.maximized.disconnect()))

  unpresentMaximized: () =>
    return unless @maximized.maximized
    state = @dropWindowState(@maximized)
    return unless state
    @maximized.save_easing_state()
    @maximized.set_easing_duration(250)
    @maximized.set_easing_mode(@Clutter.AnimationMode.EASE_OUT_QUINT)
    @maximized.x = state.x
    @maximized.y = state.y
    @maximized.width = state.width
    @maximized.height = state.height
    @maximized.restore_easing_state()
    tmp = @maximized
    @inAnimation = true
    id = tmp.connect('transition-stopped::x', @Lang.bind(this, () =>
      @inAnimation = false
      tmp.disconnect(id)
      tmp.setMaximized(false)
      if @outPorts.unmaximized.isAttached()
        @outPorts.unmaximized.send(tmp)
        @outPorts.unmaximized.disconnect()))

  unpresentAllMaximized: () =>
    while @maximizedStack.length > 0
      @maximized = @maximizedStack[@maximizedStack.length - 1]
      @unpresentMaximized()

exports.getComponent = -> new WindowMaximizer
