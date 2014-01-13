noflo = require 'noflo'

class WindowMinimizer extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      minimize: new noflo.Port 'object'
      box: new noflo.Port 'object'

    @outPorts =
      minimizing: new noflo.ArrayPort 'object'
      minimized: new noflo.ArrayPort 'object'

    @Clutter = imports.gi.Clutter
    @Lang = imports.lang

    @connectPort('minimized', @inPorts.minimize)
    @connectPort('box', @inPorts.box)

  connectPort: (name, port) =>
    this[name] = null
    port.on 'data', (value) =>
      this[name] = value
      @minimize()

  minimize: () =>
    return unless @minimized != null && @box != null

    windowArea = @minimized.get_parent()
    return unless windowArea != null

    dest = windowArea.transform_stage_point(@box.x, @box.y)

    log('transform to window area coords fails!') unless dest[0]

    @minimized.set_pivot_point(0, 0)

    @minimized.save_easing_state()
    @minimized.set_easing_duration(700)
    @minimized.set_easing_mode(@Clutter.AnimationMode.EASE_IN_OUT_QUINT)
    @minimized.translation_x = dest[1] - @minimized.x
    @minimized.scale_x = @box.width / @minimized.width
    @minimized.translation_y = dest[2] - @minimized.y
    @minimized.scale_y = @box.height / @minimized.height
    @minimized.restore_easing_state()

    @minimized.save_easing_state()
    @minimized.set_easing_duration(650)
    @minimized.set_easing_mode(@Clutter.AnimationMode.EASE_IN_QUAD)
    @minimized.opacity = 0
    @minimized.restore_easing_state()

    tmp = @minimized

    if @outPorts.minimizing.isAttached()
      @outPorts.minimizing.send(tmp)
      @outPorts.minimizing.disconnect()

    id = tmp.connect('transition-stopped::scale-x', @Lang.bind(this, () =>
      tmp.disconnect(id)
      tmp.minimized = true
      if @outPorts.minimized.isAttached()
        @outPorts.minimized.send(tmp)
        @outPorts.minimized.disconnect()))

    # wait for another couple of value before doing any processing
    @minimized = @box = null

exports.getComponent = -> new WindowMinimizer
