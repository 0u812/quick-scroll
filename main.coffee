
module.exports = QuickScroll =

   activate: ->
      @sensitivity = 120
      @native = atom.config.get 'editor.scrollSensitivity'

      atom.workspace.observeTextEditors (editor) ->
         process.nextTick () ->
            editor.element.addEventListener 'wheel', quickScroll

      quickScroll = (event) =>
         return unless event.altKey
         atom.config.set 'editor.scrollSensitivity', atom.config.get 'quick-scroll.sensitivity'
         event.target.component.onMouseWheel(event)
         atom.config.set 'editor.scrollSensitivity', @native

   deactivate: ->
      return null

   config:
      'sensitivity':
         type: 'number'
         default: 120
         description: 'The increase in scrolling sensitivity while alt key is held'