noflo = require 'noflo'

class PanelIconPosition extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      application: new noflo.Port 'string'

    @outPorts =
      box: new noflo.ArrayPort 'object'

    @panel = imports.ui.panel.getDefault();

    @inPorts.application.on 'data', (appId) =>
      button = @panel.getApplicationButton(appId)
      return unless button != null

      pos = button.get_transformed_position()
      size = button.get_transformed_size()
      box =
        x: pos[0]
        y: pos[1]
        width: size[0]
        height: size[1]
      if @outPorts.box.isAttached()
        @outPorts.box.send(box)
        @outPorts.box.disconnect()

exports.getComponent = -> new PanelIconPosition
