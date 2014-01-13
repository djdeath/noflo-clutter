noflo = require 'noflo'

class Add extends noflo.Component
  constructor: ->
    @augend = null
    @addend = null
    @inPorts =
      augend: new noflo.Port
      addend: new noflo.Port
    @outPorts =
      sum: new noflo.Port

    @augend = null
    @addend = null

    @inPorts.augend.on 'data', (data) =>
      @augend = data
      @add() unless @addend == null
    @inPorts.addend.on 'data', (data) =>
      @addend = data
      @add() unless @augend == null

    @inPorts.augend.on 'disconnect', () =>
      @augend = null
    @inPorts.addend.on 'disconnect', () =>
      @addend = null

  add: ->
    @outPorts.sum.send(@augend + @addend) if @outPorts.sum.isAttached()

exports.getComponent = -> new Add
