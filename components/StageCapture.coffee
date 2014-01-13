noflo = require 'noflo'

class StageCapture extends noflo.Component
  description: 'Change the position of a ClutterActor'
  constructor: ->
    @inPorts = []
    @outPorts =
      x: new noflo.Port 'number'
      y: new noflo.Port 'number'

    @Clutter = imports.gi.Clutter
    @Lang = imports.lang
    @stageManager = @Clutter.StageManager.get_default()
    @stage = @stageManager.list_stages()[0]

    @stage.connect('captured-event', @Lang.bind(this, @capturedEvent))

  capturedEvent: (actor, event) =>
    switch event.type()
      when @Clutter.EventType.MOTION
        [x, y] = event.get_coords()
        @outPorts.x.send x
        @outPorts.y.send y
        return true
      else
        return false

exports.getComponent = -> new StageCapture
