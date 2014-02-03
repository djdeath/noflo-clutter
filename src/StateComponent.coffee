noflo = require 'noflo'

class StateComponent extends noflo.Component
  description: 'Component retaining some state'

  constructor: ->
    @param_state = {}
    @data_state = {}

  canProcess: () =>
    for el of @input_required
      return false if @data_state[el] == null && @param_state[el] == null
    return true

  connectParamPort: (name, port) =>
    @param_state[name] = null
    @input_required[name] = true
    port.on 'data', (value) =>
      @param_state[name] = value
      @process() if @canProcess()

  connectDataPort: (name, port) =>
    @data_state[name] = null
    @input_required[name] = true
    port.on 'data', (value) =>
      @data_state[name] = value
      if @canProcess()
        @process(@data_state)
        @data_state = {}
    port.on 'disconnect', () =>
      @data_state[name] = null

exports.getComponent = -> new StateComponent
