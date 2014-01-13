noflo = require 'noflo'

class ActorSetProperties extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      actor: new noflo.Port 'object'
      properties: new noflo.Port 'object'

    @outPorts =
      actor: new noflo.ArrayPort 'object'

    @connectPort('actor', @inPorts.actor)
    @connectPort('properties', @inPorts.properties)

  connectPort: (item, port) =>
    this[item] = null
    port.on 'data', (value) =>
      this[item] = value
      @applyProperties()
    port.on 'disconnect', () =>
      this[item] = null

  applyProperties: () =>
    return unless @actor != null && @properties != null

    for k, v of @properties
      @actor[k] = v

    # Wait for another couple of (actor,properties) before doing any
    # processing
    actor = @actor
    @actor = @properties = null

    if @outPorts.actor.isAttached()
      @outPorts.actor.send(actor)
      @outPorts.actor.disconnect()

exports.getComponent = -> new ActorSetProperties
