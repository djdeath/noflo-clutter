noflo = require 'noflo'

class WindowSelector extends noflo.Component
  description: 'Choose the current window depending'
  constructor: ->
    @inPorts =
      newwindow: new noflo.Port 'object'

      movebegin: new noflo.Port 'object'
      moveend: new noflo.Port 'object'
      moveupdatex: new noflo.Port 'number'
      moveupdatey: new noflo.Port 'number'

      resizebegin: new noflo.Port 'object'
      resizeend: new noflo.Port 'object'
      resizeupdatex: new noflo.Port 'number'
      resizeupdatey: new noflo.Port 'number'

      resizeratiox: new noflo.Port 'number'
      resizeratioy: new noflo.Port 'number'

      click: new noflo.Port 'object'

    @outPorts =
#      selectedwindow: new noflo.ArrayPort 'object'
      movewindow: new noflo.ArrayPort 'object'
      resizewindow: new noflo.ArrayPort 'object'

      moveupdatex: new noflo.ArrayPort 'number'
      moveupdatey: new noflo.ArrayPort 'number'
      resizeupdatex: new noflo.ArrayPort 'number'
      resizeupdatey: new noflo.ArrayPort 'number'
      resizeratiox: new noflo.ArrayPort 'number'
      resizeratioy: new noflo.ArrayPort 'number'

    @forwardPortIfMatchCurrent('movebegin', 'movewindow')
    @forwardPortIfMatchCurrent('moveupdatex')
    @forwardPortIfMatchCurrent('moveupdatey')
    @forwardPortIfMatchCurrent('resizebegin', 'resizewindow')
    @forwardPortIfMatchCurrent('resizeupdatex')
    @forwardPortIfMatchCurrent('resizeupdatey')
    @forwardPortIfMatchCurrent('resizeratiox')
    @forwardPortIfMatchCurrent('resizeratioy')

    @acceptedGroup = null
    @currentGroup = null

    # move
    @inPorts.movebegin.on 'begingroup', (group) =>
      @storeGroupIfEmpty('move-' + group)

    @inPorts.moveend.on 'endgroup', (group) =>
      @outPorts.movewindow.disconnect() if @removeGroupIfMatch('move-' + group) && @outPorts.movewindow.isConnected()

    # resize
    @inPorts.resizebegin.on 'begingroup', (group) =>
      @storeGroupIfEmpty('resize-' + group)

    @inPorts.resizeend.on 'endgroup', (group) =>
      @outPorts.resizewindow.disconnect() if @removeGroupIfMatch('resize-' + group) && @outPorts.resizewindow.isConnected()

    # click
    @inPorts.click.on 'begingroup', (group) =>
      @storeGroupIfEmpty('click-' + group)

    @inPorts.click.on 'endgroup', (group) =>
      @removeGroupIfMatch('click-' + group)

  canSendCurrentGroup: () =>
    return @currentGroup == @acceptedGroup

  forwardPortIfMatchCurrent: (inName, outName) =>
    outName = inName if outName == undefined

    @inPorts[inName].on 'data', (value) =>
      @outPorts[outName].send(value) if @canSendCurrentGroup() && @outPorts[outName].isAttached()

  storeGroupIfEmpty: (group) =>
    @currentGroup = group
    return false if @acceptedGroup != null
    @acceptedGroup = @currentGroup
    @currentNotified = false
    true

  removeGroupIfMatch: (group) =>
    @currentGroup = null
    return false if group != @acceptedGroup
    @acceptedGroup = null
    true

  notifyIfNeeded: (win) =>
    return @currentGroup == @acceptedGroup

exports.getComponent = -> new WindowSelector
