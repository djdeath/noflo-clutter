noflo = require 'noflo'

class ListDifference extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      in: new noflo.Port 'object'

    @outPorts =
      added: new noflo.ArrayPort 'object'
      removed: new noflo.ArrayPort 'object'

    @objs = {}

    @inPorts.in.on 'data', (newList) =>
      newObjs = {}
      for obj in newList
        newObjs[obj.toString()] = obj
      # compute added elements
      added = []
      for id, obj of newObjs
        added.push(obj) unless @objs[id]
      @outPorts.added.send(added) if @outPorts.added.isAttached()
      # compute removed elements
      removed = []
      for id, obj of @objs
        removed.push(obj) unless newObjs[id]
      @outPorts.removed.send(removed) if @outPorts.removed.isAttached()
      # store new elements
      @objs = newObjs

    @inPorts.in.on 'disconnect', () =>
      for name, port in @outPorts
        port.disconnect() if port.isConnected()
      @objs = {}

exports.getComponent = -> new ListDifference
