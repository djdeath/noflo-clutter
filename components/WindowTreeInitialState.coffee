noflo = require 'noflo'

class WindowTreeInitialState extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      tree: new noflo.Port 'object'

    @outPorts =
      window: new noflo.ArrayPort 'object'
      x: new noflo.ArrayPort 'number'
      y: new noflo.ArrayPort 'number'
      width: new noflo.ArrayPort 'number'
      height: new noflo.ArrayPort 'number'

    @inPorts.tree.on 'data', (tree) =>
      @outPorts.window.send(tree.window) if @outPorts.window.isAttached()
      @outPorts.x.send(tree.initialState.x) if @outPorts.x.isAttached()
      @outPorts.y.send(tree.initialState.y) if @outPorts.y.isAttached()
      @outPorts.width.send(tree.initialState.width) if @outPorts.width.isAttached()
      @outPorts.height.send(tree.initialState.height) if @outPorts.height.isAttached()

    @inPorts.tree.on 'disconnect', () =>
      for name, port of @outPorts
        port.disconnect() if port.isConnected()

exports.getComponent = -> new WindowTreeInitialState
