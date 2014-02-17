noflo = require 'noflo'

class StateComponent extends noflo.Component
  description: 'Component retaining some state'

  constructor: ->
    @data_state = {}
    @input_required = {}
    @data_state_name = {}

  canProcess: () =>
    for el of @input_required
      if @data_state[el] == null
        return false
    return true

  cleanData: () =>
    for el of @data_state_names
      @data_state[el] = null

  connectParamPort: (name, port) =>
    @data_state[name] = null
    @input_required[name] = true
    port.on 'data', (value) =>
      @data_state[name] = value
      @process(@data_state) if @canProcess()

  connectDataPort: (name, port) =>
    @data_state[name] = null
    @input_required[name] = true
    @data_state_name[name] = true
    port.on 'data', (value) =>
      @data_state[name] = value
      if @canProcess()
        @process(@data_state)
        @cleanData()
    port.on 'disconnect', () =>
      @data_state[name] = null

exports.StateComponent = StateComponent
