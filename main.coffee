
module.exports = QuickScroll =

   activate: ->
      atom.workspace.observeTextEditors (editor) ->
         process.nextTick () ->
            editor.element.addEventListener 'wheel', quickScroll

      quickScroll = (event) =>
         return unless event.altKey
         atom.config.set 'editor.scrollSensitivity', atom.config.get 'quick-scroll.quickSensitivity'
         event.target.component.onMouseWheel(event)
         atom.config.set 'editor.scrollSensitivity', atom.config.get 'quick-scroll.regularSensitivity'

      atom.config.onDidChange 'quick-scroll.regularSensitivity', ({newValue}) ->
         atom.config.set 'editor.scrollSensitivity', newValue

   deactivate: ->
      return null

   config:
      'quickSensitivity':
         type: 'number'
         default: 120
         description: 'The increase in scrolling sensitivity while alt key is held'
      'regularSensitivity':
         type: 'number'
         default: 40
         description: 'Your regular scrolling sensitivity'