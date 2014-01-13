noflo = require 'noflo'

class WindowTreeListToWindowList extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      list: new noflo.Port 'object'
    @outPorts =
      list: new noflo.ArrayPort 'object'

    @inPorts.list.on 'data', (list) =>
      olist = []
      for tree in list
        olist.push(tree.window)
      @outPorts.list.send(olist) if @outPorts.list.isAttached()

    @inPorts.list.on 'disconnect', () =>
      @outPorts.list.disconnect() if @outPorts.list.isConnected()

exports.getComponent = -> new WindowTreeListToWindowList
