class Timeline

  @rendered: (container) ->
    @$container = $(container)
    this.adjustHeader()
    this.setupBubbles(12)
    # Go to opened path directly (no animation)
    # XXX should wait until DOM is completely ready (fonts, etc.)
    Timeline.goTo(App.router.args.slug, false)

  @adjustHeader: ->
    ###
      Make timeline header 100% height
    ###
    windowHeight = Math.max($(window).height(), 400)
    top = windowHeight / 2 - 110
    @$container.find('.header').css
      paddingTop: top
      height: windowHeight - top - 50

  @setupBubbles: (offset) ->
    @$container.find('.year .bullet').bubble
      time: 0.1
      offset: offset
    @$container.find('.post .bullet, .header .bullet').bubble
      time: 0.1
      offset: offset
      target: '.head'

  @goTo: (slug, animate = true) ->
    # Scroll to a given slug
    if slug
      @scrollTo($("#timeline-#{slug}"), if animate then 0.2 else 0)

  @scrollTo: ($entry, duration) ->
    # Make sure entry exists
    return unless $entry.length
    # Get the current scroll position in order to make a transitioned movement
    startScroll = $(window).scrollTop()
    $(this).play
      time: duration
      onFrame: (ratio) =>
        # Fetch the offset of the targeted entry with every frame, in order to
        # make sure we're landing right in case it's moving its position for
        # whatever reason
        targetScroll = @getEntryPosition($entry)
        # Get next scrolling position based on the current ratio of the
        # transition, offseting from the original scrolling point from where
        # the animation begun
        nextScroll = startScroll + ratio * (targetScroll - startScroll)

        # Get current window scroll and make sure it's still on track. If an
        # abnormal change has occured (i.e. a user scroll or a pop state event
        # firing because of back/forward browser actions), cancel the scroll
        # transition in order to avoid messing with the user's input and
        # causing an overall bad UX
        currentScroll = $(window).scrollTop()
        # XXX should be a way to cancel transition altogether if number is
        # off bounds
        if @numberInRange(currentScroll, [startScroll, nextScroll])
          $('html, body').scrollTop(nextScroll)

  @openLink: (e) =>
    e.preventDefault()
    # Toggle link path if currently on it
    path = @getPathByTarget(e.currentTarget)
    if path is @getCurrentPath()
      path = @getDefaultPath()
    App.router.navigate(path, trigger: true)

  @getPathByTarget: (target) ->
    slug = $(target).data('slug')
    return "#{App.router.args.username}/#{slug}"

  @getCurrentPath: ->
    path = App.router.args.username
    if App.router.args.slug
      path = "#{path}/#{App.router.args.slug}"
    return path

  @getDefaultPath: ->
    return App.router.args.username

  @getEntryPosition: ($entry) ->
    position = $entry.offset().top
    height = $entry.outerHeight()
    # Get position of entry centered vertically, if it's a post entry and
    # only if its entire height is smaller than the window viewport
    if height < $(window).height()
      position -= Math.round(($(window).height() - height) / 2)
    return position

  @numberInRange: (number, range) ->
    range.push(number)
    # Sort all numbers ascending
    range.sort((a, b) -> a - b)
    # The subject should now be in the middle of the two range extremities
    return range[1] is number


Template.timeline.events
  'click .link': Timeline.openLink

Template.timeline.rendered = ->
  Timeline.rendered(this.firstNode)

Template.timeline.entries = ->
  # Get entries of current user only
  return Entry.getByYears(App.router.args.username)

Template.timeline.iconClass = (icon) ->
  return icon or 'icon-circle'
