noflo_clutter = require 'noflo-clutter'

class CoglSnippet extends noflo_clutter.StateComponent
  description: 'CoglSnippet'
  constructor: ->
    super()
    @inPorts =
      code: new noflo.Port 'string'
      hook: new noflo.Port 'string'
    @outPorts =
      snippet: new noflo.ArrayPort 'object'

    @connectParamPort('hook', @inPorts.hook)
    @connectDataPort('code', @inPorts.code)
    @Cogl = imports.gi.Cogl

  process: (state) ->
    snippet = new @Cogl.Snippet(Cogl.SnippetHook[state.hook], '', state.code)
    @outPorts.snippet.send(snippet) if @outPorts.snippet.isAttached()

exports.getComponent = -> new CoglSnippet
