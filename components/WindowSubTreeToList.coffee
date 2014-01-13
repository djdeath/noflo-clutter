noflo = require 'noflo'

class WindowSubTreeToList extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      tree: new noflo.Port 'object'
    @outPorts =
      list: new noflo.ArrayPort 'object'

    @inPorts.tree.on 'data', (tree) =>
      @list = {}
      @treeToList(tree, 0, '')
      ret = []
      for k, v of @list
        ret.push(v)
      @outPorts.list.send(ret) if @outPorts.list.isAttached()
      @list = {}

    @inPorts.tree.on 'disconnect', () =>
      @outPorts.list.disconnect() if @outPorts.list.isConnected()

  treeToList: (tree, level, axis) =>
    #log(@levelToSpace(level) + axis + ' - ' +  tree.id)
    return [] if @list[tree.id]
    @list[tree.id] = tree if level != 0
    return if tree.xImpacts.length < 1 && tree.yImpacts.length < 1
    for subtree in tree.xImpacts
      @treeToList(subtree, level + 1, 'axis-x')
    for subtree in tree.yImpacts
      @treeToList(subtree, level + 1, 'axis-y')

exports.getComponent = -> new WindowSubTreeToList
