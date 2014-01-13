noflo = require 'noflo'

class DisplayArea extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      parent: new noflo.Port 'object'
      x: new noflo.Port 'number'
      y: new noflo.Port 'number'
      width: new noflo.Port 'number'
      height: new noflo.Port 'number'
      box: new noflo.Port 'object'
      styleclass: new noflo.Port 'string'

    @St = imports.gi.St

    for name, port of @inPorts
      @connectPort(name, port)

    @inPorts.parent.on 'disconnect', () =>
      if @actor
        @actor.destroy()
        delete @actor

    @inPorts.box.on 'disconnect', () =>
      if @actor
        @actor.destroy()
        delete @actor

  connectPort: (item, port) =>
    this[item] = null
    port.on 'data', (value) =>
      this[item] = value
      @display()

  display: () =>
    return unless @parent != null
    return unless @styleclass != null
    return unless (@x != null && @y != null && @width != null && @height != null) || @box != null

    if @actor == undefined
      @actor = new @St.Widget({ style_class: @styleclass, })
      @parent.add_child(@actor)

    if @box != null
      box =
        @box
    else
      box =
        x: @x
        y: @y
        width: @width
        height: @height

    for k, v of box
      @actor[k] = v
    @parent.set_child_below_sibling(@actor, null)

exports.getComponent = -> new DisplayArea
