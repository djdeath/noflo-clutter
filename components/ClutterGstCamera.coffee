noflo = require 'noflo'

ClutterGst = imports.gi.ClutterGst
Mainloop = imports.mainloop
Lang = imports.lang

class ClutterGstCamera extends noflo.Component
  description: 'extracts video frame from a Camera'
  constructor: ->
    @inPorts =
      start: new noflo.Port 'boolean'
      stop: new noflo.Port 'boolean'
    @outPorts =
      started: new noflo.ArrayPort 'boolean'
      stopped: new noflo.ArrayPort 'boolean'
      frame: new noflo.ArrayPort 'object'

    @inPorts.start.on 'data', (data) =>
      @stop()
      if data
        manager = ClutterGst.CameraManager.get_default()
        devices = manager.get_camera_devices()
        return if devices.length < 1
        @start(devices[0])

    @inPorts.stop.on 'data', (data) =>
      @stop() if data

  start: (device) ->
    @camera = new ClutterGst.Camera({ device: device })
    @newFrameId = @camera.connect('new-frame', Lang.bind(this, @newFrame))
    @delayedId = Mainloop.timeout_add(0, Lang.bind(this, @delayedCameraStart))

  delayedCameraStart: () ->
    delete @delayedId
    @camera.set_playing(true)
    if @outPorts.started.isAttached()
      @outPorts.started.send(true)
      @outPorts.started.disconnect()
    return false

  stop: () ->
    return unless @camera
    if @delayedId
      Mainloop.source_remove(@delayedId)
      delete @delayedId
    if @newFrameId
      @outPorts.frame.disconnect() if @outPorts.frame.isConnected()
      @camera.disconnect(@newFrameId)
      @camera.set_playing(false)
      delete @newFrameId
    if @outPorts.stopped.isAttached()
      @outPorts.stopped.send(true)
      @outPorts.stopped.disconnect()
    delete @camera

  newFrame: (player, frame) ->
    @outPorts.frame.send(frame) if @outPorts.frame.isAttached()

  shutdown: () ->
    @stop()

exports.getComponent = -> new ClutterGstCamera
