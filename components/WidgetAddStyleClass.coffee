noflo = require 'noflo'

class WidgetAddStyleClass extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      widget: new noflo.Port 'object'
      klass: new noflo.Port 'string'

    @inPorts.widget.on 'data', (widget) =>
      @widget = widget
      @addStyleClass()

    @inPorts.widget.on 'disconnect', =>
      delete @widget

    @inPorts.klass.on 'data', (klass) =>
      @klass = klass
      @addStyleClass()

  addStyleClass: () =>
    return unless @widget != undefined && @klass != undefined
    @widget.add_style_pseudo_class(@klass)

exports.getComponent = -> new WidgetAddStyleClass
