noflo = require 'noflo'

class WindowSnapToGrid extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      x: new noflo.Port 'number'
      y: new noflo.Port 'number'
      width: new noflo.Port 'number'
      height: new noflo.Port 'number'
      ratiox: new noflo.Port 'number'
      ratioy: new noflo.Port 'number'
      xsnapping: new noflo.Port 'number'
      ysnapping: new noflo.Port 'number'
      xdivsnapping: new noflo.Port 'number'
      ydivsnapping: new noflo.Port 'number'

    @outPorts =
      x: new noflo.ArrayPort 'object'
      y: new noflo.ArrayPort 'object'
      width: new noflo.Port 'number'
      height: new noflo.Port 'number'

    @connectParamPort('xSnapping', @inPorts.xsnapping)
    @connectParamPort('ySnapping', @inPorts.ysnapping)
    @connectParamPort('xDivSnapping', @inPorts.xdivsnapping)
    @connectParamPort('yDivSnapping', @inPorts.ydivsnapping)
    @connectDataPort('ratioX', @inPorts.ratiox)
    @connectDataPort('ratioY', @inPorts.ratioy)
    for name, port of @outPorts
      @connectDataPort(name, @inPorts[name])

  connectParamPort: (name, port) =>
    this[name] = null
    port.on 'data', (value) =>
      this[name] = value

  connectDataPort: (name, port) =>
    this[name] = null
    port.on 'data', (value) =>
      this[name] = value
      @sendSnapped(name)
    port.on 'disconnect', () =>
      this[name] = null

  sendSnapped: (name) =>
    return unless @xSnapping != null && @ySnapping != null
    return unless @xDivSnapping != null && @yDivSnapping != null
    return unless @ratioX != null && @ratioY != null
    return unless @x != null && @y != null && @width != null && @height != null

    ret = {}

    # x
    ret.x = @x
    if @ratioX < 0
      m = ret.x % @xDivSnapping
      ret.x -= m if m <= @xSnapping
      ret.x += @xDivSnapping - m if @xDivSnapping - m <= @xSnapping
    # y
    ret.y = @y
    if @ratioY < 0
      m = ret.y % @yDivSnapping
      ret.y -= m if m <= @ySnapping
      ret.y += @yDivSnapping - m if @yDivSnapping - m <= @ySnapping
    # width
    ret.width = @width - (ret.x - @x)
    if @ratioX > 0
      m = (ret.x + ret.width) % @xDivSnapping
      ret.width -= m if m <= @xSnapping
      ret.width += @xDivSnapping - m if @xDivSnapping - m <= @xSnapping
    # height
    ret.height = @height - (ret.y - @y)
    if @ratioY > 0
      m = (ret.y + ret.height) % @yDivSnapping
      ret.height -= m if m <= @ySnapping
      ret.height += @yDivSnapping - m if @yDivSnapping - m <= @ySnapping

    for name, value of ret
      @outPorts[name].send(value) if @outPorts[name].isAttached()
    @x = @y = @width = @height = null

exports.getComponent = -> new WindowSnapToGrid
