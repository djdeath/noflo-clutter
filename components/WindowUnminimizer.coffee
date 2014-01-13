noflo = require 'noflo'

class WindowUnminimizer extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      window: new noflo.Port 'object'
      windows: new noflo.Port 'object'
      box: new noflo.Port 'object'

    @outPorts =
      unminimizing: new noflo.ArrayPort 'object'
      unminimized: new noflo.ArrayPort 'object'
      notunminimized: new noflo.ArrayPort 'object'

    @Clutter = imports.gi.Clutter
    @Lang = imports.lang

    @connectPort('window', @inPorts.window)
    @connectPort('windows', @inPorts.windows)
    @connectPort('box', @inPorts.box)

  connectPort: (name, port) =>
    this[name] = null
    port.on 'data', (value) =>
      this[name] = value
      @unminimize()

  intersects: (win1, win2) =>
    dest_x = Math.max(win1.x, win2.x)
    dest_y = Math.max(win1.y, win2.y)
    dest_x2 = Math.min(win1.x + win1.width, win2.x + win2.width)
    dest_y2 = Math.min(win1.y + win1.height, win2.y + win2.height)
    return true if dest_x2 > dest_x && dest_y2 > dest_y
    return false

  unminimize: () =>
    return unless @window != null && @box != null
    # Intentionally don't check windows to allow an empty window list,
    # which means we won't do any hit testing in that case.

    if !@window.maximized && @windows
      for w in @windows
        continue if w == @window
        if @intersects(w, @window)
          win = @window
          @window = @box = null
          if @outPorts.notunminimized.isAttached()
            @outPorts.notunminimized.send(win)
            @outPorts.notunminimized.disconnect()
          return

    windowArea = @window.get_parent()
    return unless windowArea != null

    dest = windowArea.transform_stage_point(@box.x, @box.y)

    # Update minimized position
    @window.translation_x = dest[1] - @window.x
    @window.translation_y = dest[2] - @window.y
    @window.scale_x = @box.width / @window.width
    @window.scale_y = @box.height / @window.height

    # Trigger animation
    @window.set_pivot_point(0, 0)

    @window.save_easing_state()
    @window.set_easing_duration(700)
    @window.set_easing_mode(@Clutter.AnimationMode.EASE_IN_OUT_QUINT)
    @window.translation_x = @window.translation_y = 0
    @window.scale_x = @window.scale_y = 1.0
    @window.restore_easing_state()

    @window.save_easing_state()
    @window.set_easing_duration(650)
    @window.set_easing_mode(@Clutter.AnimationMode.EASE_OUT_QUINT)
    @window.opacity = 255
    @window.restore_easing_state()

    tmp = @window

    if @outPorts.unminimizing.isAttached()
      @outPorts.unminimizing.send(tmp)
      @outPorts.unminimizing.disconnect()

    id = tmp.connect('transition-stopped::scale-x', @Lang.bind(this, () =>
      tmp.disconnect(id)
      tmp.minimized = false
      if @outPorts.unminimized.isAttached()
        @outPorts.unminimized.send(tmp)
        @outPorts.unminimized.disconnect()))

    # Wait for another couple of (window,box) before doing any
    # processing
    @window = @box = null

exports.getComponent = -> new WindowUnminimizer
