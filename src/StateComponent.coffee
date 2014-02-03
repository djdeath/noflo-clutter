noflo = require 'noflo'

class StateComponent extends noflo.Component
  description: 'Component retaining some state'

  constructor: ->
    @param_state = {}
    @data_state = {}

  connectParamPort: (name, port) =>
    @param_state[name] = null
    port.on 'data', (value) =>
      @param_state[name] = value
      @process()

  connectDataPort: (name, port) =>
    @data_state[name] = null
    port.on 'data', (value) =>
      @data_state[name] = value
      if @can_process(@data_state)
        @process(@data_state)
        @data_state = {}
    port.on 'disconnect', () =>
      @data_state[name] = null

exports.getComponent = -> new StateComponent
