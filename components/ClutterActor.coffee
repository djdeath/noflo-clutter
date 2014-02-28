noflo = require 'noflo'

Clutter = imports.gi.Clutter
Lang = imports.lang

class ClutterActor extends noflo.Component
  description: 'A ClutterActor on the Stage'
  constructor: ->
    @inPorts =
      active: new noflo.Port 'boolean'
      x: new noflo.Port 'number'
      y: new noflo.Port 'number'
      z: new noflo.Port 'number'
      scalex: new noflo.Port 'number'
      scaley: new noflo.Port 'number'
      width: new noflo.Port 'number'
      height: new noflo.Port 'number'
      opacity: new noflo.Port 'number'

    @outPorts =
      object: new noflo.Port 'object'
      x: new noflo.Port 'number'
      y: new noflo.Port 'number'
      z: new noflo.Port 'number'
      scalex: new noflo.Port 'number'
      scaley: new noflo.Port 'number'
      width: new noflo.Port 'number'
      height: new noflo.Port 'number'
      opacity: new noflo.Port 'number'

    @mapping = {}
    @cache = {}
    @mapInOutPort('x', 'x')
    @mapInOutPort('y', 'y')
    @mapInOutPort('z', 'z-position')
    @mapInOutPort('scalex', 'scale-x')
    @mapInOutPort('scaley', 'scale-y')
    @mapInOutPort('width', 'width')
    @mapInOutPort('height', 'height')
    @mapInOutPort('opacity', 'opacity')

    @inPorts.active.on 'data', (active) =>
      return if active && @actor
      return if !active && !@actor
      if active
        @createActor()
      else
        @destroyActor()

  createActor: () ->
    return if @actor
    stageManager = Clutter.StageManager.get_default()
    stage = stageManager.list_stages()[0]

    @actor = new Clutter.Actor()
    @notifyId = @actor.connect('notify', Lang.bind(this, @onPropertyNotify))
    stage.add_child(@actor)
    @outPorts.object.send(@actor) if @outPorts.object.isAttached()
    for el of @cache
      @actor[el] = @cache[el]

  destroyActor: () ->
    return unless @actor
    @actor.disconnect(@notifyId)
    parent = @actor.get_parent()
    parent.remove_child(@actor)
    delete @actor
    @outPorts.object.disconnect() if @outPorts.object.isConnected()

  mapInOutPort: (portName, property) ->
    @inPorts[portName].on 'data', (data) =>
      @cache[property] = data
      @actor[property] = data if @actor
    @mapping[property] = portName

  onPropertyNotify: (actor, spec) ->
    portName = @mapping[spec.name]
    return unless portName
    log('notify ' + portName + ' : ' + @actor[spec.name])
    port = @outPorts[portName]
    port.send(@actor[spec.name]) if port.isAttached()

  shutdown: () ->
    @destroyActor()

exports.getComponent = -> new ClutterActor
