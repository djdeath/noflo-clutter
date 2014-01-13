noflo = require 'noflo'

class WidgetRemoveStyleClass extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      widget: new noflo.Port 'object'
      klass: new noflo.Port 'string'

    @inPorts.widget.on 'data', (widget) =>
      @widget = widget
      @removeStyleClass()

    @inPorts.widget.on 'disconnect', =>
      delete @widget

    @inPorts.klass.on 'data', (klass) =>
      @klass = klass
      @removeStyleClass()

  removeStyleClass: () =>
    return unless @widget != undefined && @klass != undefined
    @widget.remove_style_pseudo_class(@klass)

exports.getComponent = -> new WidgetRemoveStyleClass
