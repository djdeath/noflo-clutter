noflo = require 'noflo'

class WindowShowResizingBorders extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      window: new noflo.Port 'object'
      ratiox: new noflo.Port 'number'
      ratioy: new noflo.Port 'number'

    @connectDataPort('window', @inPorts.window)
    @connectDataPort('ratioX', @inPorts.ratiox)
    @connectDataPort('ratioY', @inPorts.ratioy)

  connectDataPort: (name, port) =>
    this[name] = null
    port.on 'data', (value) =>
      this[name] = value
      @showResizingBorders()
    port.on 'disconnect', () =>
      @hideResizingBorders()
      this[name] = null

  showResizingBorders: () =>
    return unless @window != null && @ratioX != null && @ratioY != null
    @window.setResizeRatios(@ratioX, @ratioY)
    @ratioX = @ratioY = null

  hideResizingBorders: () =>
    return unless @window != null
    @window.setResizeRatios(0, 0)

exports.getComponent = -> new WindowShowResizingBorders
