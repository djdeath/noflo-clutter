noflo = require 'noflo'

Clutter = imports.gi.Clutter
Lang = imports.lang

class ClutterActor extends noflo.Component
  description: 'A ClutterActor on the Stage'
  constructor: ->
    @inPorts =
      active: new noflo.Port 'boolean'

    @outPorts =
      object: new noflo.Port 'object'

    @portToObject = {}
    @objectToPort = {}
    @actor = null

    @mapInOutPort('x', 'x', 'number')
    @mapInOutPort('y', 'y', 'number')
    @mapInOutPort('z', 'z-position', 'number')
    @mapInOutPort('scalex', 'scale-x', 'number')
    @mapInOutPort('scaley', 'scale-y', 'number')
    @mapInOutPort('width', 'width', 'number')
    @mapInOutPort('height', 'height', 'number')
    @mapInOutPort('opacity', 'opacity', 'number')
    @mapInOutPort('content', 'content', 'object')
    @mapInOutPort('reactive', 'reactive', 'boolean')

    @inPorts.active.on 'data', (active) =>
      if active
        @activateActor()
      else
        @deactivateActor()
    @outPorts.object.on 'attach', (socket) =>
      socket.send(@getActor())
      socket.disconnect()

  getActor: () ->
    return @actor if @actor
    @actor = new Clutter.Actor()
    @notifyId = @actor.connect('notify', Lang.bind(this, @onPropertyNotify))
    if @outPorts.object.isAttached()
      @outPorts.object.send(@actor)
      @outPorts.object.disconnect()
    return @actor

  activateActor: () ->
    return if @getActor().get_parent() != null
    stageManager = Clutter.StageManager.get_default()
    stage = stageManager.list_stages()[0]

    actor = @getActor()
    stage.add_child(actor)
    if @outPorts.object.isAttached()
      @outPorts.object.send(actor)
      @outPorts.object.disconnect()

  dectivateActor: () ->
    actor = @getActor()
    parent = actor.get_parent()
    return unless parent != null
    parent.remove_child(actor)

  destroyActor: () ->
    return unless @actor
    @dectivateActor()
    @actor.destroy()
    delete @actor

  mapInOutPort: (portName, property, type) ->
    inPort = @inPorts[portName] = new noflo.Port type
    outPort = @outPorts[portName] = new noflo.Port type
    inPort.on 'data', (data) =>
      @getActor()[property] = data
    outPort.on 'attach', (socket) =>
      socket.send(@getActor()[property])
      socket.disconnect()
    @objectToPort[property] = portName
    @portToObject[portName] = property

  onPropertyNotify: (actor, spec) ->
    portName = @objectToPort[spec.name]
    return unless portName
    port = @outPorts[portName]
    return unless port.isAttached()
    port.send(@getActor()[spec.name])
    port.disconnect()

  shutdown: () ->
    @destroyActor()

exports.getComponent = -> new ClutterActor
