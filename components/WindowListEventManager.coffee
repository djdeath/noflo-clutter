noflo = require 'noflo'

class WindowManager extends noflo.Component
  description: 'Expose the value of a property of an object'
  constructor: ->
    @inPorts =
      start: new noflo.ArrayPort 'boolean'
      maximized: new noflo.ArrayPort 'object'
      unmaximized: new noflo.ArrayPort 'object'
      minimized: new noflo.ArrayPort 'object'
      unminimized: new noflo.ArrayPort 'object'
      destroywindow: new noflo.ArrayPort 'object'
      raisewindow: new noflo.ArrayPort 'object'

    @outPorts =
      movebegin: new noflo.ArrayPort 'object'
      moveend: new noflo.ArrayPort 'object'
      moveupdatex: new noflo.ArrayPort 'number'
      moveupdatey: new noflo.ArrayPort 'number'

      resizebegin: new noflo.ArrayPort 'object'
      resizeend: new noflo.ArrayPort 'object'
      resizeupdatex: new noflo.ArrayPort 'number'
      resizeupdatey: new noflo.ArrayPort 'number'

      preresizewindow: new noflo.ArrayPort 'object'

      resizeratiox: new noflo.ArrayPort 'number'
      resizeratioy: new noflo.ArrayPort 'number'

      clickedwindow: new noflo.ArrayPort 'object'

      closewindow: new noflo.ArrayPort 'object'
      addwindow: new noflo.ArrayPort 'object'

      maximizewindow: new noflo.ArrayPort 'object'
      unmaximizewindow: new noflo.ArrayPort 'object'

      minimizewindow: new noflo.ArrayPort 'object'

      windows: new noflo.ArrayPort 'object'
      visiblewindows: new noflo.ArrayPort 'object'
      minimizedwindows: new noflo.ArrayPort 'object'

      areawidth: new noflo.ArrayPort 'number'
      areaheight: new noflo.ArrayPort 'number'

    @Lang = imports.lang
    @windowManager = imports.windowManager.getDefault()
    @windowManagerIds = []

    @inPorts.maximized.on 'data', (win) =>
      @windowManager.maximized(win)
    @inPorts.unmaximized.on 'data', (win) =>
      @windowManager.unmaximized(win)
    @inPorts.minimized.on 'data', (win) =>
      @windowManager.minimized(win)
    @inPorts.unminimized.on 'data', (win) =>
      @windowManager.unminimized(win)
    @inPorts.destroywindow.on 'data', (win) =>
      @windowManager.destroyWindow(win)
    @inPorts.raisewindow.on 'data', (win) =>
      @windowManager.raiseWindow(win)

    # Initialization (propagate default values into the graph)
    @inPorts.start.on 'data', () =>
      @startup()


  startup: ->
    @stop()
    @connectWindowManager('move-begin', @Lang.bind(this, @moveBegin))
    @connectWindowManager('move-end', @Lang.bind(this, @moveEnd))
    @connectWindowManager('move-update', @Lang.bind(this, @moveUpdate))

    @connectWindowManager('resize-begin', @Lang.bind(this, @resizeBegin))
    @connectWindowManager('resize-end', @Lang.bind(this, @resizeEnd))
    @connectWindowManager('resize-update', @Lang.bind(this, @resizeUpdate))

    @connectWindowManager('add-window', @Lang.bind(this, @addWindow))
    @connectWindowManager('close-window', @Lang.bind(this, @closeWindow))

    @connectWindowManager('clicked-window', @Lang.bind(this, @clickedWindow))

    @connectWindowManager('maximize-window', @Lang.bind(this, @maximizeWindow))
    @connectWindowManager('unmaximize-window', @Lang.bind(this, @unmaximizeWindow))

    @connectWindowManager('minimize-window', @Lang.bind(this, @minimizeWindow))

    @connectWindowManager('windows-list-update', @Lang.bind(this, @windowsListUpdated))
    @connectWindowManager('visible-windows-list-update', @Lang.bind(this, @visibleWindowsListUpdated))
    @connectWindowManager('minimized-windows-list-update', @Lang.bind(this, @minimizedWindowsListUpdated))

    @connectWindowManager('windows-area-update', @Lang.bind(this, @windowsAreaChanged))

    @connectWindowManager('pre-resize-begin', @Lang.bind(this, @preResizeBegin))
    @connectWindowManager('pre-resize-end', @Lang.bind(this, @preResizeEnd))

    @windowManager.reinit()

  stop: ->
    for id in @windowManagerIds
      @windowManager.disconnect(id)
    @windowManagerIds = []

  shutdown: ->
    @stop()

  connectWindowManager: (signalName, callback) =>
    id = @windowManager.connect(signalName, callback)
    @windowManagerIds.push(id)

  moveBegin: (manager, win) =>
    @moveUpdate(manager, win, 0, 0)
    @resizeUpdate(manager, win, 0, 0)
    if @outPorts.movebegin.isAttached()
      @outPorts.movebegin.beginGroup(win.getId())
      @outPorts.movebegin.send(win)
      @outPorts.movebegin.endGroup()

  moveEnd: (manager, win) =>
    @outPorts.movebegin.disconnect() if @outPorts.movebegin.isConnected()
    @outPorts.moveupdatex.disconnect() if @outPorts.moveupdatex.isConnected()
    @outPorts.moveupdatey.disconnect() if @outPorts.moveupdatey.isConnected()
    if @outPorts.moveend.isAttached()
      @outPorts.moveend.beginGroup(win.getId())
      @outPorts.moveend.send(win)
      @outPorts.moveend.endGroup()
      @outPorts.moveend.disconnect()

  moveUpdate: (manager, win, dx, dy) =>
    if @outPorts.moveupdatex.isAttached()
      @outPorts.moveupdatex.beginGroup(win.getId())
      @outPorts.moveupdatex.send(dx)
      @outPorts.moveupdatex.endGroup()
    if @outPorts.moveupdatey.isAttached()
      @outPorts.moveupdatey.beginGroup(win.getId())
      @outPorts.moveupdatey.send(dy)
      @outPorts.moveupdatey.endGroup()

  resizeBegin: (manager, win, ratioX, ratioY) =>
    @moveUpdate(manager, win, 0, 0)
    @resizeUpdate(manager, win, 0, 0)
    @outPorts.resizeratiox.send(ratioX) if @outPorts.resizeratiox.isAttached()
    @outPorts.resizeratioy.send(ratioY) if @outPorts.resizeratioy.isAttached()
    if @outPorts.resizebegin.isAttached()
      @outPorts.resizebegin.beginGroup(win.getId())
      @outPorts.resizebegin.send(win)
      @outPorts.resizebegin.endGroup()

  resizeEnd: (manager, win) =>
    @outPorts.resizebegin.disconnect() if @outPorts.resizebegin.isConnected()
    @outPorts.resizeupdatex.disconnect() if @outPorts.resizeupdatex.isConnected()
    @outPorts.resizeupdatey.disconnect() if @outPorts.resizeupdatey.isConnected()
    @outPorts.resizeratiox.disconnect() if @outPorts.resizeratiox.isConnected()
    @outPorts.resizeratioy.disconnect() if @outPorts.resizeratioy.isConnected()
    if @outPorts.resizeend.isAttached()
      @outPorts.resizeend.beginGroup(win.getId())
      @outPorts.resizeend.send(win)
      @outPorts.resizeend.endGroup()
      @outPorts.resizeend.disconnect()

  resizeUpdate: (manager, win, dx, dy) =>
    if @outPorts.resizeupdatex.isAttached()
      @outPorts.resizeupdatex.beginGroup(win.getId())
      @outPorts.resizeupdatex.send(dx)
      @outPorts.resizeupdatex.endGroup()
    if @outPorts.resizeupdatey.isAttached()
      @outPorts.resizeupdatey.beginGroup(win.getId())
      @outPorts.resizeupdatey.send(dy)
      @outPorts.resizeupdatey.endGroup()

  preResizeBegin: (manager, win, ratioX, ratioY) =>
    @outPorts.resizeratiox.send(ratioX) if @outPorts.resizeratiox.isAttached()
    @outPorts.resizeratioy.send(ratioY) if @outPorts.resizeratioy.isAttached()
    @outPorts.preresizewindow.send(win) if @outPorts.preresizewindow.isAttached()

  preResizeEnd: (manager, win) =>
    @outPorts.resizeratiox.disconnect() if @outPorts.resizeratiox.isConnected()
    @outPorts.resizeratioy.disconnect() if @outPorts.resizeratioy.isConnected()
    @outPorts.preresizewindow.disconnect() if @outPorts.preresizewindow.isConnected()

  addWindow: (manager, win) =>
    if @outPorts.addwindow.isAttached()
      @outPorts.addwindow.send(win)
      @outPorts.addwindow.disconnect()

  closeWindow: (manager, win) =>
    if @outPorts.closewindow.isAttached()
      @outPorts.closewindow.send(win)
      @outPorts.closewindow.disconnect()

  maximizeWindow: (manager, win) =>
    if @outPorts.maximizewindow.isAttached()
      @outPorts.maximizewindow.send(win)
      @outPorts.maximizewindow.disconnect()

  unmaximizeWindow: (manager, win) =>
    if @outPorts.unmaximizewindow.isAttached()
      @outPorts.unmaximizewindow.send(win)
      @outPorts.unmaximizewindow.disconnect()

  minimizeWindow: (manager, win) =>
    if @outPorts.minimizewindow.isAttached()
      @outPorts.minimizewindow.send(win)
      @outPorts.minimizewindow.disconnect()

  clickedWindow: (manager, win) =>
    if @outPorts.clickedwindow.isAttached()
      @outPorts.clickedwindow.send(win)
      @outPorts.clickedwindow.disconnect()

  windowsListUpdated: (manager) =>
    @outPorts.windows.send(@windowManager.windows) if @outPorts.windows.isAttached()

  visibleWindowsListUpdated: (manager) =>
    @outPorts.visiblewindows.send(@windowManager.visibleWindows) if @outPorts.visiblewindows.isAttached()

  minimizedWindowsListUpdated: (manager) =>
    @outPorts.minimizedwindows.send(@windowManager.minimizedWindows) if @outPorts.minimizedwindows.isAttached()

  windowsAreaChanged: (manager, areaWidth, areaHeight) =>
    @outPorts.areawidth.send(areaWidth) if @outPorts.areawidth.isAttached()
    @outPorts.areaheight.send(areaHeight) if @outPorts.areaheight.isAttached()

exports.getComponent = -> new WindowManager
