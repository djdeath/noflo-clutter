noflo = require 'noflo'

class WindowListEventManager extends noflo.Component
  description: 'Expose lists of windows and operations you can do on them'
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
      addwindow: new noflo.ArrayPort 'object'

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
    @connectWindowManager('add-window', @Lang.bind(this, @addWindow))

    @connectWindowManager('windows-list-update', @Lang.bind(this, @windowsListUpdated))
    @connectWindowManager('visible-windows-list-update', @Lang.bind(this, @visibleWindowsListUpdated))
    @connectWindowManager('minimized-windows-list-update', @Lang.bind(this, @minimizedWindowsListUpdated))

    @connectWindowManager('windows-area-update', @Lang.bind(this, @windowsAreaChanged))

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

  addWindow: (manager, win) =>
    if @outPorts.addwindow.isAttached()
      @outPorts.addwindow.send(win)
      @outPorts.addwindow.disconnect()

  windowsListUpdated: (manager) =>
    @outPorts.windows.send(@windowManager.windows) if @outPorts.windows.isAttached()

  visibleWindowsListUpdated: (manager) =>
    @outPorts.visiblewindows.send(@windowManager.visibleWindows) if @outPorts.visiblewindows.isAttached()

  minimizedWindowsListUpdated: (manager) =>
    @outPorts.minimizedwindows.send(@windowManager.minimizedWindows) if @outPorts.minimizedwindows.isAttached()

  windowsAreaChanged: (manager, areaWidth, areaHeight) =>
    @outPorts.areawidth.send(areaWidth) if @outPorts.areawidth.isAttached()
    @outPorts.areaheight.send(areaHeight) if @outPorts.areaheight.isAttached()

exports.getComponent = -> new WindowListEventManager
