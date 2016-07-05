
module.exports = QuickScroll =

   activate: ->
      @sensitivity = atom.config.get 'quick-scroll.quickSensitivity'
      @native = atom.config.get 'quick-scroll.regularSensitivity'
      @editors = []

      @editorSub = atom.workspace.observeTextEditors (editor) =>
         @editors.push(editor)
         process.nextTick () ->
            editor.element.addEventListener 'wheel', quickScroll

      @revertEditors = () =>
         for editor in @editors
            process.nextTick () ->
               editor?.element?.removeEventListener 'wheel', quickScroll

      quickScroll = (event) =>
         return unless event.altKey
         atom.config.set 'editor.scrollSensitivity', @sensitivity
         event.target.component.onMouseWheel(event)
         atom.config.set 'editor.scrollSensitivity', @native

      @sensitivitySub = atom.config.onDidChange 'quick-scroll.quickSensitivity', ({newValue}) =>
         @sensitivity = newValue
      @nativeSub = atom.config.onDidChange 'quick-scroll.regularSensitivity', ({newValue}) =>
         atom.config.set 'editor.scrollSensitivity', newValue
         @native = newValue

   deactivate: ->
      @editorSub.dispose()
      @sensitivitySub.dispose()
      @nativeSub.dispose()
      @revertEditors()
      @editors = null

   config:
      'quickSensitivity':
         type: 'number'
         default: 120
         description: 'The increase in scrolling sensitivity while alt key is held'
      'regularSensitivity':
         type: 'number'
         default: 40
         description: 'Your regular scrolling sensitivity'