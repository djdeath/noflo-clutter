noflo = require 'noflo'

class WindowResizeAreaLimiter extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      window: new noflo.Port 'object'
      initialx: new noflo.Port 'number'
      initialy: new noflo.Port 'number'
      initialwidth: new noflo.Port 'number'
      initialheight: new noflo.Port 'number'

      minwidth: new noflo.Port 'number'
      minheight: new noflo.Port 'number'

      areawidth: new noflo.Port 'number'
      areaheight: new noflo.Port 'number'

      x: new noflo.Port 'number'
      y: new noflo.Port 'number'
      width: new noflo.Port 'number'
      height: new noflo.Port 'number'

      ratiox: new noflo.Port 'number'
      ratioy: new noflo.Port 'number'

    @outPorts =
      x: new noflo.ArrayPort 'number'
      y: new noflo.ArrayPort 'number'
      width: new noflo.ArrayPort 'number'
      height: new noflo.ArrayPort 'number'

    @window = null
    @inPorts.window.on 'data', (win) =>
      @window = win
      @generateOutput()
    @inPorts.window.on 'disconnect', () =>
      @x = @y = @width = @height = null

    for item, port of @inPorts
      @connectPort(item, port)

  connectPort: (name, port) =>
    this[name] = null
    port.on 'data', (value) =>
      this[name] = value
      @generateOutput()
    port.on 'disconnect', () =>
      this[name] = null
      @disconnectPorts()

  disconnectPorts: () =>
    for name, port of @outPorts
      port.disconnect() if port.isConnected()

  minX: () =>
    return 0

  maxX: () =>
    return Math.min(@areawidth, @initialx + @initialwidth - @minwidth)

  boundX: () =>
    return Math.max(Math.min(@x, @maxX()), @minX())

  minY: () =>
    return 0

  maxY: () =>
    return Math.min(@areaheight, @initialy + @initialheight - @minheight)

  boundY: () =>
    return Math.max(Math.min(@y, @maxY()), @minY())

  minWidth: () =>
    return @minwidth

  maxWidth: () =>
    if @ratiox < 0
      return @areawidth - @boundX()
    return @areawidth - @initialx

  boundWidth: () =>
    dx = @boundX() - @x
    return Math.max(Math.min(@width - dx, @maxWidth()), @minWidth())

  minHeight: () =>
    return @minheight

  maxHeight: () =>
    if @ratioy < 0
      return @areaheight - @boundY()
    return @areaheight - @initialy

  boundHeight: () =>
    dy = @boundY() - @y
    return Math.max(Math.min(@height - dy, @maxHeight()), @minHeight())

  generateOutput: () =>
    return unless @window != null
    return unless @ratiox != null && @ratioy != null
    return unless @intialx != null && @initialy != null
    return unless @initialwidth != null && @initialheight != null
    return unless @minwidth != null && @minheight != null
    return unless @areawidth != null && @areaheight != null
    return unless @x != null && @y != null
    return unless @width != null && @height != null
    ret =
      x: @boundX()
      y: @boundY()
      width: @boundWidth()
      height: @boundHeight()

    for item, value of ret
      @outPorts[item].send(value) if @outPorts[item].isAttached()
    @x = @y = @width = @height = null

exports.getComponent = -> new WindowResizeAreaLimiter
