noflo = require 'noflo'

class Stub extends noflo.Component
  description: 'Stub inputs'
  constructor: ->
    @outPorts =
      out: new noflo.ArrayPort 'all'

exports.getComponent = -> new Stub
