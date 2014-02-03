noflo = require 'noflo'

Lang = imports.lang
GObject = imports.gi.GObject
Clutter = imports.gi.Clutter

st =
  Name: 'PipelineContent'
  Extends: GObject.Object
  Implements: [ Clutter.Content ]
  _init: () ->
    @parent()
  vfunc_paint_content: (actor, parent) ->
    box = actor.get_allocation_box()
    node = new Clutter.PipelineNode(@pipeline)
    node.add_rectangle(box)
    parent.add_child(node)
Content = new Lang.Class(st)

class ClutterPipelineContent extends noflo.Component
  description: 'Create a ClutterContent object for a CoglPipeline'
  constructor: ->
    @inPorts =
      pipeline: new noflo.Port 'object'
    @outPort =
      content: new noflo.Port 'object'

    @inPorts.pipeline.on 'data', () ->
      if @outPort.content.isAttached()
        content = new Content()
        content.pipeline = state.pipeline
        @outPort.content.send(content)
        @outPort.content.disconnect()

exports.getComponent = -> new ClutterPipelineContent
