noflo = require 'noflo'

class SetProperty extends noflo.Component
  description: 'Set the value of a property of an object'
  constructor: ->
    @inPorts =
      object: new noflo.Port 'object'
      property: new noflo.Port 'string'
      value: new noflo.Port 'all'
    @outPorts =
      object: new noflo.Port 'object'

    @inPorts.property.on 'data', (property) =>
      @property = property
      @setValue(@object, @property, @value)

    @inPorts.object.on 'data', (object) =>
      @object = object
      @setValue(@object, @property, @value)

    @inPorts.value.on 'data', (value) =>
      @value = value
      @setValue(@object, @property, @value)

  setValue: (object, property, value) =>
    return unless object != undefined && property != undefined && value != undefined
    object[property] = value
    if @outPorts.object.isAttached()
      @outPorts.object.send(object)
      @outPorts.object.disconnect()

exports.getComponent = -> new SetProperty
