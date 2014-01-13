noflo = require 'noflo'

class PanelDrawerOpener extends noflo.Component
  description: ''
  constructor: ->
    @inPorts =
      drawerlayer: new noflo.Port 'object'
      opendrawer: new noflo.Port 'object'

    @outPorts =
      openeddrawer: new noflo.Port 'object'
      closingdrawer: new noflo.Port 'object'
      closeddrawer: new noflo.Port 'object'
      clickedapplication: new noflo.ArrayPort 'string'

    @Clutter = imports.gi.Clutter
    @Lang = imports.lang

    @inPorts.opendrawer.on 'data', (obj) =>
      return unless @drawerLayer
      return if @drawer
      @showDrawer(obj.drawer, obj.button)

    @inPorts.drawerlayer.on 'data', (drawerLayer) =>
     @drawerLayer = drawerLayer

  showDrawer: (drawer, button) =>
    @button = button
    @drawer = drawer

    @drawer.ensure_style()

    origPos = @button.get_transformed_position()
    origSize = @button.get_transformed_size()

    @drawer.show()
    @drawerLayer.reactive = true

    size = @drawer.get_preferred_size()
    finalBox =
      width: size[2]
      height: size[3]

    # layout drawer position/scale
    @drawer.x = origPos[0] - finalBox.width
    @drawer.y = Math.max(0, origPos[1] - finalBox.height / 2)
    @drawer.scale_x = origSize[0] / finalBox.width
    @drawer.scale_y = origSize[1] / finalBox.height
    @drawer.opacity = 0

    # Setup animation
    @drawer.set_pivot_point((origPos[0] - @drawer.x) / finalBox.width, (origPos[1] - @drawer.y) / finalBox.height)
    @drawer.save_easing_state()
    @drawer.set_easing_duration(150)
    @drawer.set_easing_mode(@Clutter.AnimationMode.LINEAR)
    @drawer.scale_x = @drawer.scale_y = 1
    @drawer.opacity = 255
    @drawer.restore_easing_state()

    id = @drawer.connect('transition-stopped::scale-x', @Lang.bind(this, () =>
      @drawer.disconnect(id)
      if @outPorts.openeddrawer.isAttached()
        @outPorts.openeddrawer.send(@drawer)
        @outPorts.openeddrawer.disconnect()))

    # Listen to events outside the drawer
    @outsideId = @drawerLayer.connect('event', @Lang.bind(this, (actor, event) =>
      switch event.type()
        when @Clutter.EventType.BUTTON_PRESS, @Clutter.EventType.BUTTON_RELEASE, @Clutter.EventType.TOUCH_BEGIN, @Clutter.EventType.TOUCH_END
          @hideDrawer()
          return true
        else
          return false))
    @clickedApplicationId = @drawer.connect('application-clicked', @Lang.bind(this, (widget, button, appId) =>
      if @outPorts.clickedapplication.isAttached()
        @outPorts.clickedapplication.send(appId)
        @outPorts.clickedapplication.disconnect()
      @hideDrawer()))

  hideDrawer: () =>
    @drawerLayer.disconnect(@outsideId)
    delete @outsideId
    @drawer.disconnect(@clickedApplicationId)
    delete @clickedApplicationId

    dest_pos = @button.get_transformed_position()
    dest_size = @button.get_transformed_size()

    # Set initial drawer position/scale
    @drawer.set_pivot_point((dest_pos[0] - @drawer.x) / @drawer.width, (dest_pos[1] - @drawer.y) / @drawer.height)

    @drawer.save_easing_state()
    @drawer.set_easing_duration(150)
    @drawer.set_easing_mode(@Clutter.AnimationMode.LINEAR)
    @drawer.scale_x = dest_size[0] / @drawer.width
    @drawer.scale_y = dest_size[1] / @drawer.height
    @drawer.opacity = 0
    @drawer.restore_easing_state()

    drawer = @drawer
    @button = null
    @drawer = null

    id = drawer.connect('transition-stopped::scale-x', @Lang.bind(this, () ->
      drawer.disconnect(id)
      @drawerLayer.reactive = false
      drawer.hide()
      if @outPorts.closeddrawer.isAttached()
        @outPorts.closeddrawer.send(drawer)
        @outPorts.closeddrawer.disconnect()))

    if @outPorts.closingdrawer.isAttached()
      @outPorts.closingdrawer.send(drawer)
      @outPorts.closingdrawer.disconnect()



exports.getComponent = -> new PanelDrawerOpener
