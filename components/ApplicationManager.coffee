noflo = require 'noflo'

class ApplicationManager extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      windows: new noflo.Port 'object'
      start: new noflo.Port 'string'

    @outPorts =
      window: new noflo.ArrayPort 'object'

    @applicationManager = imports.applicationManager.getDefault()
    @windowsToAppIds = {}

    @inPorts.windows.on 'data', (windows) =>
      @windowsToAppIds = {}
      for w in windows
        @windowsToAppIds[w.getApplicationId()] = w

    @inPorts.start.on 'data', (applicationId) =>
      w = @windowsToAppIds[applicationId]
      if w
        @outPorts.window.send(w) if @outPorts.window.isAttached()
      else
        log('no window found for ' + applicationId)
        @applicationManager.startApplication(applicationId)

exports.getComponent = -> new ApplicationManager
