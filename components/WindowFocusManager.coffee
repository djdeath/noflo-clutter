noflo = require 'noflo'

class WindowFocusManager extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      windows: new noflo.Port 'object'
      select: new noflo.Port 'object'
      destroy: new noflo.Port 'object'
      create: new noflo.Port 'object'

    @outPorts =
      focusin: new noflo.ArrayPort 'object'
      focusout: new noflo.ArrayPort 'object'

    @inPorts.windows.on 'data', (windows) =>
      @windows = windows
      return if @windows.indexOf(@focus) >= 0
      @emitFocusOut()
      @emitFocusIn(@windows[@windows.length - 1])

    @inPorts.select.on 'data', (win) =>
      return if @focus == win
      @emitFocusOut()
      @emitFocusIn(win)

    @inPorts.destroy.on 'data', (win) =>
      return unless @windows # Shouldn't happen
      return unless @focus == win

      @emitFocusOut()
      for i in [@windows.length - 1.. 0] by -1
        if @windows[i] != win
          @emitFocusIn(@windows[i])
          break

    @inPorts.create.on 'data', (win) =>
      return if @focus == win
      @emitFocusOut()
      @emitFocusIn(win)

  emitFocusOut: () =>
    return unless @focus
    if @outPorts.focusout.isAttached()
      @outPorts.focusout.send(@focus) if @focus
    delete @focus if @focus

  emitFocusIn: (win) =>
    @focus = win
    @outPorts.focusin.send(@focus) if @outPorts.focusin.isAttached()

exports.getComponent = -> new WindowFocusManager
