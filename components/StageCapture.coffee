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

    @capturedId = @stage.connect('captured-event', @Lang.bind(this, @capturedEvent))

  shutdown: ->
    if @capturedId
      @stage.disconnect(@capturedId)
      delete @capturedId

  capturedEvent: (actor, event) =>
    switch event.type()
      when @Clutter.EventType.MOTION
        [x, y] = event.get_coords()
        @outPorts.x.send(x) if @outPorts.x.isAttached()
        @outPorts.y.send(y) if @outPorts.y.isAttached()
        return true
      else
        return false

exports.getComponent = -> new StageCapture
