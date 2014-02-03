noflo = require 'noflo'

class CoglPipelineCopy extends noflo.Component
  description: 'Copy a CoglPipeline'
  constructor: ->
    super()
    @inPorts =
      in: new noflo.Port 'object'
    @outPorts =
      out: new noflo.ArrayPort 'object'

    @inPorts.in.on 'data', (pipeline) ->
      @outPorts.out.send(pipeline.copy()) if @outPorts.out.isAttached()

exports.getComponent = -> new CoglPipelineCopy
