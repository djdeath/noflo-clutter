noflo = require 'noflo'

class ApplicationLauncherGuard extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      applicationid: new noflo.Port 'string'
      windows: new noflo.Port 'object'
      areawidth: new noflo.Port 'number'
      areaheight: new noflo.Port 'number'
      xdiv: new noflo.Port 'number'
      ydiv: new noflo.Port 'number'

    @outPorts =
      applicationid: new noflo.ArrayPort 'string'

    @connectDataPort('windows', @inPorts.windows)
    @connectDataPort('areaWidth', @inPorts.areawidth)
    @connectDataPort('areaHeight', @inPorts.areaheight)
    @connectParamPort('xDiv', @inPorts.xdiv)
    @connectParamPort('yDiv', @inPorts.ydiv)

    @windows = []

    @inPorts.applicationid.on 'data', (applicationId) =>
      @processApplication(applicationId)

  connectDataPort: (name, port) =>
    this[name] = null
    port.on 'data', (value) =>
      this[name] = value
    port.on 'disconnect', () =>
      this[name] = null

  connectParamPort: (name, port) =>
    this[name] = null
    port.on 'data', (value) =>
      this[name] = value

  processApplication: (applicationId) =>
    return unless @windows != null
    return unless @areaWidth != null && @areaHeight != null
    return unless @xDiv != null && @yDiv != null

    maxWindows = Math.floor(@areaWidth / @xDiv) * Math.floor(@areaHeight / @yDiv)

    if @windows.length < maxWindows
      if @outPorts.applicationid.isAttached()
        @outPorts.applicationid.send(applicationId)
        @outPorts.applicationid.disconnect()
    else
      log('cannot open ' + applicationId + ' not enough space')

exports.getComponent = -> new ApplicationLauncherGuard
