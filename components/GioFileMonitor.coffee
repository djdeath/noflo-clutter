noflo = require 'noflo'

Gio = imports.gi.Gio

class GioFileMonitor extends noflo.Component
  description: 'Monitors a file for changes'
  constructor: ->
    @inPorts =
      filename: new noflo.Port 'string'
    @outPorts =
      changed: new noflo.ArrayPort 'boolean'

    @inPorts.filename.on 'data', (filename) =>
      @stop()
      @start(filename)

  changed: (monitor, file, other_file, event_type) ->
    log(Gio.FileMonitorEvent.CHANGES_DONE_HINT)
    return if event_type != Gio.FileMonitorEvent.CHANGES_DONE_HINT
    if @outPorts.changed.isAttached()
      @outPorts.changed.send(true)
      @outPorts.changed.disconnect()

  start: (filename) ->
    file = Gio.File.new_for_path(filename)
    @monitor = file.monitor(Gio.FileMonitorFlags.NONE, null)
    @monitorId = @monitor.connect('changed', Lang.bind(this, @changed))

  stop: ->
    if @monitorId
      @monitor.disconnect(@monitorId)
      delete @monitorId

  shutdown: ->
    @stop()

exports.getComponent = -> new GioFileMonitor
