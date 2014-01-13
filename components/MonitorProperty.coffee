noflo = require 'noflo'

class MonitoryProperty extends noflo.Component
  description: 'Expose the value of a property of an object'
  constructor: ->
    @inPorts =
      object: new noflo.Port 'object'
      property: new noflo.Port 'string'

    @outPorts =
      value: new noflo.ArrayPort

    @Lang = imports.lang

    @inPorts.property.on 'data', (property) =>
      @property = property
      resetWatcher()

    @inPorts.object.on 'data', (object) =>
      @object = object
      resetWatcher()

  notifyProperty: =>
    @outPorts.value.send(@object[@property])

  resetWatcher: =>
    if @propertyId
      @object.disconnect(@propertyId)
      @propertyId = null
    if @object && @property
      @object.connect('notify::' + @property, @Lang.bind(this, @notifyProperty))
      @outPorts.value.send(@object[@property])

exports.getComponent = -> new MonitoryProperty
