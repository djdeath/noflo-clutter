noflo = require 'noflo'

class GetProperty extends noflo.Component
  description: 'Expose the value of a property of an object'
  constructor: ->
    @inPorts =
      object: new noflo.Port 'object'
      property: new noflo.Port 'string'

    @outPorts =
      value: new noflo.ArrayPort

    @inPorts.property.on 'data', (property) =>
      @property = property
      @notifyProperty()

    @inPorts.object.on 'data', (object) =>
      @object = object
      @notifyProperty()

    @inPorts.object.on 'disconnect', =>
      @outPorts.value.disconnect() if @outPorts.value.isConnected()
      delete @object

  notifyProperty: =>
    return unless @outPorts.value.isAttached()
    return unless @object && @property
    @outPorts.value.send(@object[@property]) if @outPorts.value.isAttached()

exports.getComponent = -> new GetProperty
