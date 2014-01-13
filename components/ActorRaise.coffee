noflo = require 'noflo'

class ActorRaise extends noflo.Component
  description: 'Raise a ClutterActor'
  constructor: ->
    @inPorts =
      actor: new noflo.Port 'object'

    @inPorts.actor.on 'data', (actor) =>
      parent = actor.get_parent()
      parent.set_child_above_sibling(actor, null) if parent

exports.getComponent = -> new ActorRaise
