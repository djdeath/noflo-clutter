noflo = require 'noflo'
{StateComponent} = require '../lib/StateComponent'
Cogl = imports.gi.Cogl

class CoglSnippet extends StateComponent
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

  process: (state) ->
    snippet = new Cogl.Snippet(Cogl.SnippetHook[state.hook], '', state.code)
    @outPorts.snippet.send(snippet) if @outPorts.snippet.isAttached()

exports.getComponent = -> new CoglSnippet
