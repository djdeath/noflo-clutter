noflo = require 'noflo'

class WindowAppearAnimation extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      in: new noflo.ArrayPort 'object'

    @outPorts =
      out: new noflo.ArrayPort 'object'

    @Clutter = imports.gi.Clutter
    @Lang = imports.lang

    @inPorts.in.on 'data', (win) =>
      win.opacity = 0
      win.save_easing_state()
      win.set_easing_duration(150)
      win.set_easing_mode(@Clutter.AnimationMode.LINEAR)
      win.opacity = 255
      win.restore_easing_state()

      id = win.connect('transition-stopped::opacity', @Lang.bind(this, () =>
        win.disconnect(id)
        return unless @outPorts.out.isAttached()
        @outPorts.out.send(win)
        @outPorts.out.disconnect()))


exports.getComponent = -> new WindowAppearAnimation
