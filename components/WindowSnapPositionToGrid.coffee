noflo = require 'noflo'

class WindowSnapPositionToGrid extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      x: new noflo.Port 'number'
      y: new noflo.Port 'number'
      width: new noflo.Port 'number'
      height: new noflo.Port 'number'
      xsnapping: new noflo.Port 'number'
      ysnapping: new noflo.Port 'number'
      xdivsnapping: new noflo.Port 'number'
      ydivsnapping: new noflo.Port 'number'

    @outPorts =
      x: new noflo.ArrayPort 'object'
      y: new noflo.ArrayPort 'object'

    @connectParamPort('xSnapping', @inPorts.xsnapping)
    @connectParamPort('ySnapping', @inPorts.ysnapping)
    @connectParamPort('xDivSnapping', @inPorts.xdivsnapping)
    @connectParamPort('yDivSnapping', @inPorts.ydivsnapping)
    @connectDataPort('width', @inPorts.width)
    @connectDataPort('height', @inPorts.height)
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
    return unless @x != null && @y != null && @width != null && @height != null

    ret =
      x: @x
      y: @y

    ret.x = @x
    m = @x % @xDivSnapping
    if m <= @xSnapping
      ret.x -= m
    else if @xDivSnapping - m <= @xSnapping
      ret.x += @xDivSnapping - m
    else
      m = (@x + @width) % @xDivSnapping
      if m <= @xSnapping
        ret.x -= m
      else if @xDivSnapping - m <= @xSnapping
        ret.x += @xDivSnapping - m


    ret.y = @y
    m = @y % @yDivSnapping
    if m <= @ySnapping
      ret.y -= m
    else if @yDivSnapping - m <= @ySnapping
      ret.y += @yDivSnapping - m
    else
      m = (@y + @height) % @yDivSnapping
      if m <= @ySnapping
        ret.y -= m
      else if @yDivSnapping - m <= @ySnapping
        ret.y += @yDivSnapping - m

    for name, value of ret
      @outPorts[name].send(value) if @outPorts[name].isAttached()
    @x = @y = null

exports.getComponent = -> new WindowSnapPositionToGrid
