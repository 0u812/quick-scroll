

module.exports = QuickScroll =

   activate: ->

      @subs = []
      @components = []

      @onMouseWheel = @onMouseWheel.bind(@)

      window.addEventListener 'wheel', @onMouseWheel

      @subs.push(

         atom.workspace.observeTextEditors (editor) =>
            component = editor.getElement().component
            component.domNode.removeEventListener 'mousewheel', component.onMouseWheel
            @componentOnMouseWheelCache ?= component.onMouseWheel
            component.onMouseWheel = () -> return null
            @components.push(component)

         atom.config.observe 'quick-scroll.regularSensitivity', (value) =>
            @regularSensitivity = value
         atom.config.observe 'quick-scroll.quickSensitivity', (value) =>
            @quickSensitivity = value
         atom.config.observe 'quick-scroll.overloadedSensitivity', (value) =>
            @overloadedSensitivity = value

         atom.config.observe 'quick-scroll.modifierA', (value) =>
            if value == 'cmd' then value = 'meta'
            @modifierA = value + 'Key'
            if @modifierB == @modifierA then modifierB = undefined
         atom.config.observe 'quick-scroll.modifierB', (value) =>
            if value == 'cmd' then value = 'meta'
            @modifierB = value + 'Key'
            if @modifierB == @modifierA then modifierB = undefined
         atom.config.observe 'quick-scroll.horizontalModifier', (value) =>
            if value == 'cmd' then value = 'meta'
            @horizontalModifier = value + 'Key'

         atom.config.observe 'quick-scroll.zoomModifier', (value) =>
            @zoomModifier = value.split('-')
            @zoomModifier.forEach (_,i) =>
               if @zoomModifier[i] == 'cmd' then @zoomModifier[i] = 'meta'
               @zoomModifier[i] += 'Key'

      )

   revertComponents : () ->
      for component in @components
         if component
            component.onMouseWheel = @componentOnMouseWheelCache
            component.domNode.addEventListener 'mousewheel', component.onMouseWheel


   deactivate: ->
      sub.dispose() for sub in @subs
      window.removeEventListener 'wheel', @onMouseWheel
      @revertComponents()
      QuickScroll = null

   config:
      'regularSensitivity':
         type: 'number'
         default: 40
         description: 'Your regular scrolling sensitivity for all scrollable items'
         order: 1
      'quickSensitivity':
         type: 'number'
         default: 120
         description: 'An increased scrolling sensitivity while one modifier key is held down'
         order: 2
      'overloadedSensitivity':
         type: 'number'
         default: 240
         description: 'Scrolling sensitivity while both modifiers keys are held down'
         order: 3
      'modifierA':
         type: 'string'
         default: 'ctrl'
         enum: ['ctrl', 'shift', 'alt', 'cmd']
         description: 'One of the two modifiers you can use to achieve quick scrolling'
         order: 4
      'modifierB':
         type: 'string'
         default: 'shift'
         enum: ['ctrl', 'shift', 'alt', 'cmd']
         description: 'One of the two modifiers you can use to achieve quick scrolling'
         order: 5
      'horizontalModifier':
         type: 'string'
         default: 'alt'
         enum: ['ctrl', 'shift', 'alt', 'cmd']
         description: 'Modifier to acheive horizontal scrolling'
         order: 6
      'zoomModifier':
         type: 'string'
         default: 'shift-alt'
         enum: ['none', 'ctrl', 'shift', 'alt', 'cmd', 'ctrl-alt', 'ctrl-shift',
                'shift-alt', 'ctrl-cmd', 'shift-cmd', 'alt-cmd']
         description: 'Modifier(s) for zooming the font'
         order: 7



   onMouseWheel: (event) ->

      {wheelDelta, target} = event
      event.preventDefault()

      if event[@modifierA] || event[@modifierB]
         if event[@modifierA] && event[@modifierB]
            scrollSensitivity = @overloadedSensitivity
         else
            scrollSensitivity = @quickSensitivity
      else
         scrollSensitivity = @regularSensitivity

      delta = Math.round(wheelDelta * scrollSensitivity / 100)

      ed = atom.workspace.getActiveTextEditor()
      if ed then el = ed.getElement()

      if target == el
         component = el.component

         if (@zoomModifier.every((mod) -> event[mod]))
            if delta > 0
               component.workspace.increaseFontSize()
            else if delta < 0
               component.workspace.decreaseFontSize()
            return

         if event[@horizontalModifier]
            previousScrollLeft = component.presenter.getScrollLeft()
            component.presenter.setScrollLeft(previousScrollLeft - delta)
            return
         else
            component.presenter.setMouseWheelScreenRow(component.screenRowForNode(target))
            previousScrollTop = component.presenter.getScrollTop()
            component.presenter.setScrollTop(previousScrollTop - delta)
            return
      else

         if event[@horizontalModifier]
            target.dispatchEvent new WheelEvent('wheel', wheelDeltaX: delta)
         else
            target.dispatchEvent new WheelEvent('wheel', wheelDeltaY: delta)

