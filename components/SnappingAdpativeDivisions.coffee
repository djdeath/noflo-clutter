noflo = require 'noflo'

class SnappingAdpativeDivisions extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      windows: new noflo.Port 'object'
      unminimize: new noflo.Port 'object'
      areawidth: new noflo.Port 'number'
      areaheight: new noflo.Port 'number'
      xdiv: new noflo.Port 'number'
      ydiv: new noflo.Port 'number'

    @outPorts =
      xdiv: new noflo.ArrayPort 'object'
      ydiv: new noflo.ArrayPort 'object'

    @connectParamPort('xDiv', @inPorts.xdiv)
    @connectParamPort('yDiv', @inPorts.ydiv)
    @connectParamPort('areaWidth', @inPorts.areawidth)
    @connectParamPort('areaHeight', @inPorts.areaheight)
    @connectDataPort('windows', @inPorts.windows)
    @connectDataPort('unminimize', @inPorts.unminimize)

  connectParamPort: (name, port) =>
    this[name] = null
    port.on 'data', (value) =>
      this[name] = value
      @sendDivisions()

  connectDataPort: (name, port) =>
    this[name] = null
    port.on 'data', (value) =>
      this[name] = value
      @sendDivisions()
    port.on 'disconnect', () =>
      this[name] = null

  sendDivisions: () =>
    return unless @windows != null
    return unless @xDiv != null && @yDiv != null
    return unless @areaWidth != null && @areaHeight != null

    nbWindows = @windows.length
    nbWindows += 1 if @unminimize != null && @windows.indexOf(@unminimize) < 0

    if nbWindows > 0
      maxXDiv = Math.floor(@areaWidth / @xDiv)
      xDiv = Math.floor(@areaWidth / Math.min(nbWindows, maxXDiv))
      nbXDiv = Math.floor(@areaWidth / xDiv)
    else
      xDiv = @areaWidth

    nbYDiv = 1
    while ((nbXDiv * nbYDiv) < nbWindows)
      nbYDiv += 1
    maxYDiv = Math.floor(@areaHeight / @yDiv)
    yDiv = Math.floor(@areaHeight / Math.min(nbYDiv, maxYDiv))

    if @outPorts.xdiv.isAttached()
      @outPorts.xdiv.send(xDiv)
      @outPorts.xdiv.disconnect()
    if @outPorts.ydiv.isAttached()
      @outPorts.ydiv.send(yDiv)
      @outPorts.ydiv.disconnect()

exports.getComponent = -> new SnappingAdpativeDivisions
