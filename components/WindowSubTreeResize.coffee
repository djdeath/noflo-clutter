noflo = require 'noflo'

class WindowSubTreeResize extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      tree: new noflo.Port 'object'
      box: new noflo.Port 'object'
      ratiox: new noflo.Port 'number'
      ratioy: new noflo.Port 'number'

    @connectPort('tree', @inPorts.tree)
    @connectPort('box', @inPorts.box)
    @connectPort('ratioX', @inPorts.ratiox)
    @connectPort('ratioY', @inPorts.ratioy)

  connectPort: (name, port) =>
    this[name] = null
    port.on 'data', (value) =>
      this[name] = value
      @resizeSubTree()
    port.on 'disconnect', () =>
      this[name] = null

  resizeSubTree: () =>
    return unless @tree != null && @box != null
    return unless @ratioX != null && @ratioY != null
    @tree.resizeSubTreeTo(@box, @ratioX, @ratioY, 0)

exports.getComponent = -> new WindowSubTreeResize
