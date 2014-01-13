noflo = require 'noflo'

class WindowToApplication extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      window: new noflo.ArrayPort 'object'

    @outPorts =
      application: new noflo.ArrayPort 'string'

    @inPorts.window.on 'data', (win) =>
      @outPorts.application.send(win.getApplicationId()) if @outPorts.application.isAttached()

exports.getComponent = -> new WindowToApplication
