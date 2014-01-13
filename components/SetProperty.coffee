noflo = require 'noflo'

class SetProperty extends noflo.Component
  description: 'Set the value of a property of an object'
  constructor: ->
    @inPorts =
      object: new noflo.Port 'object'
      property: new noflo.Port 'string'
      value: new noflo.Port

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
    if (object != undefined && property != undefined)
      object[property] = value if value != undefined

exports.getComponent = -> new SetProperty
