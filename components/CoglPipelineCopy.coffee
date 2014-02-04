noflo = require 'noflo'

class CoglPipelineCopy extends noflo.Component
  description: 'Copy a CoglPipeline'
  constructor: ->
    super()
    @inPorts =
      pipeline: new noflo.Port 'object'
    @outPorts =
      pipeline: new noflo.ArrayPort 'object'

    @inPorts.pipeline.on 'data', (pipeline) =>
      @outPorts.pipeline.send(pipeline.copy()) if @outPorts.pipeline.isAttached()

exports.getComponent = -> new CoglPipelineCopy
