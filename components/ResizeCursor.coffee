noflo = require 'noflo'

class ResizeCursor extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      ratiox: new noflo.Port 'number'
      ratioy: new noflo.Port 'number'

    @Gdk = imports.gi.Gdk
    @display = @Gdk.Display.get_default()
    @screen = @display.get_screen(0)

    @connectDataPort('ratioX', @inPorts.ratiox)
    @connectDataPort('ratioY', @inPorts.ratioy)

  connectDataPort: (name, port) =>
    this[name] = null
    port.on 'data', (value) =>
      this[name] = value
      @showResizingCursor()
    port.on 'disconnect', () =>
      @hideResizingCursor()
      this[name] = null

  showResizingCursor: () =>
    return unless @ratioX != null && @ratioY != null
    gdkWindow = @screen.get_active_window()
    cursorType = @Gdk.CursorType.LEFT_PTR
    if @ratioX < 0
      if @ratioY > 0
        cursorType = @Gdk.CursorType.BOTTOM_LEFT_CORNER
      else if @ratioY < 0
        cursorType = @Gdk.CursorType.TOP_LEFT_CORNER
      else
        cursorType = @Gdk.CursorType.LEFT_SIDE
    else if @ratioX > 0
      if @ratioY > 0
        cursorType = @Gdk.CursorType.BOTTOM_RIGHT_CORNER
      else if @ratioY < 0
        cursorType = @Gdk.CursorType.TOP_RIGHT_CORNER
      else
        cursorType = @Gdk.CursorType.RIGHT_SIDE
    else if @ratioX == 0
      if @ratioY < 0
        cursorType = @Gdk.CursorType.TOP_SIDE
      else if @ratioY > 0
        cursorType = @Gdk.CursorType.BOTTOM_SIDE
    gdkWindow.set_cursor(Gdk.Cursor.new_for_display(display, cursorType))
    @ratioX = @ratioY = null

  hideResizingCursor: () =>
    return unless @window != null
    gdkWindow = @screen.get_active_window()
    gdkWindow.set_cursor(@Gdk.Cursor.new_for_display(display, @Gdk.CursorType.LEFT_PTR))

exports.getComponent = -> new ResizeCursor
