noflo = require 'noflo'

class ApplicationFinder extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      windows: new noflo.Port 'object'
      applicationid: new noflo.Port 'string'

    @outPorts =
      start: new noflo.ArrayPort 'string'
      raise: new noflo.ArrayPort 'object'
      unminimize: new noflo.ArrayPort 'object'

    @applicationManager = imports.applicationManager.getDefault()
    @windowsToAppIds = {}

    @inPorts.windows.on 'data', (windows) =>
      @windowsToAppIds = {}
      for w in windows
        @windowsToAppIds[w.getApplicationId()] = w

    @inPorts.applicationid.on 'data', (applicationId) =>
      w = @windowsToAppIds[applicationId]
      if w
        if w.minimized
          if @outPorts.unminimize.isAttached()
            @outPorts.unminimize.send(w)
            @outPorts.unminimize.disconnect()
        else
          if @outPorts.raise.isAttached()
            @outPorts.raise.send(w)
            @outPorts.raise.disconnect()
      else
        log('no window found for ' + applicationId)
        if @outPorts.start.isAttached()
          @outPorts.start.send(applicationId)
          @outPorts.start.disconnect()

exports.getComponent = -> new ApplicationFinder
