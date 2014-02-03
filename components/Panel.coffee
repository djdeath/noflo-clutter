noflo = require 'noflo'

class Panel extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      start: new noflo.Port 'boolean'
      closed: new noflo.Port 'string'
      opened: new noflo.Port 'string'
      minimized: new noflo.Port 'string'
      unminimized: new noflo.Port 'string'

    @outPorts =
      clickeddrawer: new noflo.ArrayPort 'object'
      clickedapplication: new noflo.ArrayPort 'string'

    @Lang = imports.lang
    @panelIds = []

    @inPorts.closed.on 'data', (appId) =>
     @panel.setRunning(appId, false)
    @inPorts.opened.on 'data', (appId) =>
     @panel.setRunning(appId, true)
    @inPorts.minimized.on 'data', (appId) =>
     @panel.setMinimized(appId, true)
    @inPorts.unminimized.on 'data', (appId) =>
     @panel.setMinimized(appId, false)

    @inPorts.start.on 'data', () =>
      @stop()
      @start()

  start: ->
    @panel = imports.ui.panel.getDefault();
    @connectPanel('drawer-clicked', @Lang.bind(this, (panel, button, drawer) =>
      obj =
        button: button
        drawer: drawer
      if @outPorts.clickeddrawer.isAttached()
        @outPorts.clickeddrawer.send(obj)
        @outPorts.clickeddrawer.disconnect()))
    @connectPanel('application-clicked', @Lang.bind(this, (panel, appId) =>
       if @outPorts.clickedapplication.isAttached()
        @outPorts.clickedapplication.send(appId)
        @outPorts.clickedapplication.disconnect()))

  stop: ->
    for id in @panelIds
      @panel.disconnect(id)
    @panelIds = []

  shutdown: ->
    @stop()

  connectPanel: (signalName, callback) =>
    id = @panel.connect(signalName, callback)
    @panelIds.push(id)


exports.getComponent = -> new Panel
