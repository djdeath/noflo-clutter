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
    @cache = {}
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
      return if active && @actor
      return if !active && !@actor
      if active
        @createActor()
      else
        @destroyActor()
    @outPorts.object.on 'attach', (socket) =>
      return unless @actor
      socket.send(actor)
      socket.disconnect()

  createActor: () ->
    return if @actor
    stageManager = Clutter.StageManager.get_default()
    stage = stageManager.list_stages()[0]

    @actor = new Clutter.Actor()
    @initializeObject()
    stage.add_child(@actor)
    if @outPorts.object.isAttached()
      @outPorts.object.send(@actor)
      @outPorts.object.disconnect()
    @notifyId = @actor.connect('notify', Lang.bind(this, @onPropertyNotify))
    @initialNotify()

  destroyActor: () ->
    return unless @actor
    @actor.disconnect(@notifyId)
    parent = @actor.get_parent()
    parent.remove_child(@actor)
    @actor.destroy()
    delete @actor

  initializeObject: () ->
    for prop, value of @cache
      @actor[prop] = value

  initialNotify: () ->
    for name, port of @outPorts
      continue unless port.isAttached()
      port.send(@actor[@portToObject[name]])
      port.disconnect()

  mapInOutPort: (portName, property, type) ->
    inPort = @inPorts[portName] = new noflo.Port type
    outPort = @outPorts[portName] = new noflo.Port type
    inPort.on 'data', (data) =>
      @cache[property] = data
      @actor[property] = data if @actor
    outPort.on 'attach', (socket) =>
      return unless @actor
      socket.send(@actor[property])
      socket.disconnect()
    @objectToPort[property] = portName
    @portToObject[portName] = property

  onPropertyNotify: (actor, spec) ->
    portName = @objectToPort[spec.name]
    return unless portName
    port = @outPorts[portName]
    return unless port.isAttached()
    port.send(@actor[spec.name])
    port.disconnect()

  shutdown: () ->
    @destroyActor()

exports.getComponent = -> new ClutterActor
