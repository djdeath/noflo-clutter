noflo = require 'noflo'

ClutterGst = imports.gi.ClutterGst
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
      manager = ClutterGst.CameraManager.get_default()
      devices = manager.get_camera_devices()
      return if devices.length < 1
      @start(devices[0])

    @inPorts.stop.on 'data', (data) =>
      @stop()

  start: (device) ->
    @camera = new ClutterGst.Camera({ device: device })
    @camera.set_playing(true)
    @newFrameId = @camera.connect('new-frame', Lang.bind(this, @newFrame))
    if @outPorts.started.isAttached()
      @outPorts.started.send(true)
      @outPorts.started.disconnect()

  stop: () ->
    if @newFrameId
      @outPorts.frame.disconnect() if @outPorts.frame.isConnected()
      @camera.disconnect(@newFrameId)
      @camera.set_playing(false)
      delete @newFrameId
      delete @camera
    if @outPorts.stopped.isAttached()
      @outPorts.stopped.send(true)
      @outPorts.stopped.disconnect()

  newFrame: (player, frame) ->
    @outPorts.frame.send(frame) if @outPorts.frame.isAttached()

  shutdown: () ->
    @stop()

exports.getComponent = -> new ClutterGstCamera
