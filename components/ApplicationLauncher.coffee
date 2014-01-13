noflo = require 'noflo'

class ApplicationLauncher extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      start: new noflo.Port 'string'

    @outPorts =
      started: new noflo.ArrayPort 'string'

    @applicationManager = imports.applicationManager.getDefault()

    @inPorts.start.on 'data', (applicationId) =>
      @applicationManager.startApplication(applicationId)
      @outPorts.started.send(applicationId) if @outPorts.started.isAttached()

exports.getComponent = -> new ApplicationLauncher
