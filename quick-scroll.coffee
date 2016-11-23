

module.exports = QuickScroll =

   activate: () ->

      @subs = []
      @components = []
      @active = true

      @onMouseWheel = @onMouseWheel.bind(@)

      window.addEventListener "wheel", @onMouseWheel

      if !@dispatching
         process.nextTick () =>
            @toggleCommandSub = atom.commands.add "atom-workspace", "quick-scroll:toggle": => @toggle()
            @menuSub = atom.menu.add @menu
            atom.menu.update()

      @subs.push(

         atom.workspace.observeTextEditors (editor) =>
            component = editor.getElement().component
            component.domNode.removeEventListener "mousewheel", component.onMouseWheel
            @components.push({component, onMouseWheel: component.onMouseWheel})
            component.onMouseWheel = () -> return null

         atom.config.observe "quick-scroll.regularSensitivity", (value) =>
            @regularSensitivity = value
         atom.config.observe "quick-scroll.regionSensitivity", (value) =>
            @regionSensitivity = value
         atom.config.observe "quick-scroll.regionSide", (value) =>
            @regionSide = value
         atom.config.observe "quick-scroll.regionSize", (value) =>
            @regionSize = value
         atom.config.observe "quick-scroll.quickSensitivity", (value) =>
            @quickSensitivity = value
         atom.config.observe "quick-scroll.overloadedSensitivity", (value) =>
            @overloadedSensitivity = value

         atom.config.observe "quick-scroll.modifierA", (value) =>
            if value == "cmd" then value = "meta"
            @modifierA = value + "Key"
            if @modifierB == @modifierA then modifierB = undefined
         atom.config.observe "quick-scroll.modifierB", (value) =>
            if value == "cmd" then value = "meta"
            @modifierB = value + "Key"
            if @modifierB == @modifierA then modifierB = undefined
         atom.config.observe "quick-scroll.horizontalModifier", (value) =>
            if value == "cmd" then value = "meta"
            @horizontalModifier = value + "Key"

         atom.config.observe "quick-scroll.zoomModifier", (value) =>
            @zoomModifier = value.split("-")
            @zoomModifier.forEach (_,i) =>
               if @zoomModifier[i] == "cmd" then @zoomModifier[i] = "meta"
               @zoomModifier[i] += "Key"

      )


   canScrollTop: (target) ->
      return true if target.scrollTop != 0
      target.scrollTop++
      return false if target.scrollTop == 0
      target.scrollTop--
      return true

   canScrollLeft: (target) ->
      return true if target.scrollLeft != 0
      target.scrollLeft++
      return false if target.scrollLeft == 0
      target.scrollLeft--
      return true


   onMouseWheel: (event) ->

      {wheelDelta, target} = event

      isEditor = false
      parent = target
      while parent
         if parent.localName == "atom-text-editor"
            isEditor = true
            target = parent
            break
         else
            parent = parent.parentNode


      if isEditor == false
         event.preventDefault()
         if event[@horizontalModifier]
            while !@canScrollLeft(target)
               target = target.parentNode
               return if !target
         else
            while !@canScrollTop(target)
               target = target.parentNode
               return if !target
         return unless target.getBoundingClientRect

      scrollSensitivity = @regularSensitivity

      if @regionSide != "none"

         {clientX} = event
         {left, right, width} = target.getBoundingClientRect()


         if @regionSide == "left"
            regionStart = left
            regionEnd = left + width*@regionSize/100

         else if @regionSide == "right"
            regionStart = right - width*@regionSize/100
            regionEnd = right

         if regionStart <= clientX <= regionEnd
            scrollSensitivity = @regionSensitivity

      if event[@modifierA] || event[@modifierB]
         if event[@modifierA] && event[@modifierB]
            scrollSensitivity += @overloadedSensitivity
         else
            scrollSensitivity += @quickSensitivity

      delta = Math.round(wheelDelta * scrollSensitivity / 100)

      if isEditor == true
         component = target.component

         if (@zoomModifier.every((mod) -> event[mod]))
            if delta > 0
               component.workspace.increaseFontSize()
            else if delta < 0
               component.workspace.decreaseFontSize()
            return

         if event[@horizontalModifier]
            previousScrollLeft = component.presenter.getScrollLeft()
            updatedScrollLeft = previousScrollLeft - delta
            event.preventDefault() if component.presenter.canScrollLeftTo(updatedScrollLeft)
            component.presenter.setScrollLeft(updatedScrollLeft)
            return
         else
            component.presenter.setMouseWheelScreenRow(component.screenRowForNode(target))
            previousScrollTop = component.presenter.getScrollTop()
            updatedScrollTop = previousScrollTop - delta
            event.preventDefault() if component.presenter.canScrollTopTo(updatedScrollTop)
            component.presenter.setScrollTop(updatedScrollTop)
            return

      else if event[@horizontalModifier]
         target.scrollLeft -= delta

      else
         target.scrollTop -= delta


   relabelAtomMenu: (searchTerms, newLabel) ->
      menu = atom.menu.template
      for searchTerm in searchTerms
         if menu
            for obj in menu
               if typeof obj.label == 'string'
                  if obj.label.replace(/&/g, "") == searchTerm
                     menu = obj.submenu
                     break
      if obj.label == searchTerms.pop()
         obj.label = newLabel
         atom.menu.update()
         return obj

   toggle: ->
      @dispatching = true
      if @active
         @deactivate()
         @relabelAtomMenu(["Packages", "QuickScroll", "Deactivate"], "Activate")
         @dispatching = false
      else
         @activate()
         @relabelAtomMenu(["Packages", "QuickScroll", "Activate"], "Deactivate")
         @dispatching = false

   deactivate: () ->
      @active = false
      sub.dispose() for sub in @subs
      window.removeEventListener "wheel", @onMouseWheel
      @revertComponents()
      if !@dispatching
         @menuSub.dispose()
         @toggleCommandSub.dispose()
         QuickScroll = null

   revertComponents: ->
      for pair in @components
         component = pair.component
         if !component then continue
         component.onMouseWheel = pair.onMouseWheel
         component.domNode.addEventListener "mousewheel", component.onMouseWheel


   menu: [
      "label": "Packages"
      "submenu": [
         "label": "QuickScroll"
         "submenu": [
            "label": "Deactivate"
            "command": "quick-scroll:toggle"
         ]
      ]
   ]

   config:
      "regularSensitivity":
         type: "number"
         default: 40
         description: "Your regular scrolling sensitivity for all scrollable items"
         order: 1
      "regionSensitivity":
         type: "number"
         default: 120
         description: "An increased scrolling sensitivity while hovering in a quick-scroll region"
         order: 2
      "regionSide":
         type: "string"
         default: "right"
         enum: ["none", "left", "right"]
         description: "The side of an element to consider a quick-scroll region"
         order: 3
      "regionSize":
         type: "number"
         default: 12
         description: "On the chosen side, the percent of the element to be considered a quick-scroll region."
         order: 4
      "quickSensitivity":
         type: "number"
         default: 120
         description: "An increased scrolling sensitivity while one modifier key is held down"
         order: 5
      "overloadedSensitivity":
         type: "number"
         default: 240
         description: "Scrolling sensitivity while both modifiers keys are held down"
         order: 6
      "modifierA":
         type: "string"
         default: "ctrl"
         enum: ["ctrl", "shift", "alt", "cmd"]
         description: "One of the two modifiers you can use to achieve quick scrolling"
         order: 7
      "modifierB":
         type: "string"
         default: "shift"
         enum: ["ctrl", "shift", "alt", "cmd"]
         description: "One of the two modifiers you can use to achieve quick scrolling"
         order: 8
      "horizontalModifier":
         type: "string"
         default: "alt"
         enum: ["ctrl", "shift", "alt", "cmd"]
         description: "Modifier to acheive horizontal scrolling"
         order: 9
      "zoomModifier":
         type: "string"
         default: "shift-alt"
         enum: ["none", "ctrl", "shift", "alt", "cmd", "ctrl-alt", "ctrl-shift",
                "shift-alt", "ctrl-cmd", "shift-cmd", "alt-cmd"]
         description: "Modifier(s) for zooming the font"
         order: 10
