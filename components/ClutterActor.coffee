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
    @mapInOutPort('pivot-x', 'pivot-point', 'number', 'pointXToPoint', 'pointToPointX')
    @mapInOutPort('pivot-y', 'pivot-point', 'number', 'pointYToPoint', 'pointToPointY')
    @mapInOutPort('pivot-z', 'pivot-point-z', 'number')
    @mapInOutPort('rotation-x', 'rotation-angle-x', 'number')
    @mapInOutPort('rotation-y', 'rotation-angle-y', 'number')
    @mapInOutPort('rotation-z', 'rotation-angle-z', 'number')
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

  deactivateActor: () ->
    actor = @getActor()
    parent = actor.get_parent()
    return unless parent != null
    parent.remove_child(actor)

  destroyActor: () ->
    return unless @actor
    @deactivateActor()
    @actor.destroy()
    delete @actor

  convertPortIfNeeded: (portName, value) ->
    return value unless @portToObject[portName].convert
    return this[@portToObject[portName].convert](value)

  convertPropertyIfNeeded: (property, value) ->
    return value unless @objectToPort[property].convert
    return this[@objectToPort[property].convert](value)

  mapInOutPort: (portName, property, type, convertIn, convertOut) ->
    inPort = @inPorts[portName] = new noflo.Port type
    outPort = @outPorts[portName] = new noflo.Port type

    @objectToPort[property] =
      portName: portName
      convert: convertOut
    @portToObject[portName] =
      property: property
      convert: convertIn

    inPort.on 'data', (data) =>
      @getActor()[property] = @convertPortIfNeeded(portName, data)
    outPort.on 'attach', (socket) =>
      socket.send(@convertPropertyIfNeeded(property, @getActor()[property]))
      socket.disconnect()

  onPropertyNotify: (actor, spec) ->
    portMapping = @objectToPort[spec.name]
    return unless portMapping
    port = @outPorts[portMapping.portName]
    return unless port.isAttached()
    property = spec.name
    port.send(@convertPropertyIfNeeded(property, @getActor()[property]))
    port.disconnect()

  pointToPointY: (value) ->
    return value.y

  pointToPointX: (value) ->
    return value.x

  pointXToPoint: (value) ->
    pivotPoint = @getActor().pivot_point
    pivotPoint.x = value
    return pivotPoint

  pointYToPoint: (value) ->
    pivotPoint = @getActor().pivot_point
    pivotPoint.y = value
    return pivotPoint

  shutdown: () ->
    @destroyActor()

exports.getComponent = -> new ClutterActor
