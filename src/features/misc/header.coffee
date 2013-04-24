Header =
  init: ->
    @menu = new UI.Menu 'header'
    @menuButton = $.el 'span',
      className: 'menu-button'
      innerHTML: '<i></i>'

    barFixedToggler  = $.el 'label',
      innerHTML: '<input type=checkbox name="Fixed Header"> Fixed Header'
    headerToggler = $.el 'label',
      innerHTML: '<input type=checkbox name="Header auto-hide"> Auto-hide header'
    barPositionToggler = $.el 'label',
      innerHTML: '<input type=checkbox name="Bottom header"> Bottom header'
    customNavToggler = $.el 'label',
      innerHTML: '<input type=checkbox name="Custom Board Navigation"> Custom board navigation'
    footerToggler = $.el 'label',
      innerHTML: "<input type=checkbox #{unless Conf['Bottom Board List'] then 'checked' else ''}> Bottom original board list"
    editCustomNav = $.el 'a',
      textContent: 'Edit custom board navigation'
      href: 'javascript:;'

    @barFixedToggler    = barFixedToggler.firstElementChild
    @barPositionToggler = barPositionToggler.firstElementChild
    @headerToggler      = headerToggler.firstElementChild
    @footerToggler      = footerToggler.firstElementChild
    @customNavToggler   = customNavToggler.firstElementChild

    $.on @menuButton,         'click',  @menuToggle
    $.on @barFixedToggler,    'change', @toggleBarFixed
    $.on @barPositionToggler, 'change', @toggleBarPosition
    $.on @headerToggler,      'change', @toggleBarVisibility
    $.on @footerToggler,      'change', @toggleFooterVisibility
    $.on @customNavToggler,   'change', @toggleCustomNav
    $.on editCustomNav,       'click',  @editCustomNav

    @setBarFixed      Conf['Fixed Header']
    @setBarVisibility Conf['Header auto-hide']

    $.sync 'Fixed Header',     Header.setBarFixed
    $.sync 'Bottom Header',    Header.setBarPosition
    $.sync 'Header auto-hide', Header.setBarVisibility

    @addShortcut Header.menuButton

    $.event 'AddMenuEntry',
      type: 'header'
      el: $.el 'span',
        textContent: 'Header'
      order: 105
      subEntries: [
        {el: barFixedToggler}
        {el: headerToggler}
        {el: barPositionToggler}
        {el: footerToggler}
        {el: customNavToggler}
        {el: editCustomNav}
      ]

    $.on window, 'load hashchange', Header.hashScroll
    $.on d, 'CreateNotification', @createNotification

    $.asap (-> d.body), =>
      return unless Main.isThisPageLegit()
      # Wait for #boardNavMobile instead of #boardNavDesktop,
      # it might be incomplete otherwise.
      $.asap (-> $.id('boardNavMobile') or d.readyState is 'complete'), Header.setBoardList
      $.prepend d.body, @bar
      @setBarPosition Conf['Bottom Header']

    $.ready =>
      if a = $ "a[href*='/#{g.BOARD}/']", $.id 'boardNavDesktopFoot'
        a.className = 'current'

      $.add d.body, Header.hover
      Header.footer = footer = $.id 'boardNavDesktopFoot'
      @footer = $.id 'boardNavDesktopFoot'
      Header.setFooterVisibility Conf['Footer auto-hide']
      $.sync 'Footer auto-hide', Header.setFooterVisibility
      $.sync 'Bottom Board List', Header.setFooterVisibility

  bar: $.el 'div',
    id: 'header-bar'

  notify: $.el 'div',
    id: 'notifications'

  shortcuts: $.el 'span',
    id: 'shortcuts'

  hover: $.el 'div',
    id: 'hoverUI'

  toggle: $.el 'div',
    id: 'scroll-marker'

  setBoardList: ->
    fourchannav = $.id 'boardNavDesktop'
    if a = $ "a[href*='/#{g.BOARD}/']", fourchannav
      a.className = 'current'

    boardList = $.el 'span',
      id: 'board-list'
      innerHTML: "<span id=custom-board-list></span><span id=full-board-list hidden><span class='hide-board-list-button brackets-wrap'><a href=javascript:;> - </a></span>#{fourchannav.innerHTML}</span>"
    fullBoardList = $ '#full-board-list', boardList
    btn = $ '.hide-board-list-button', fullBoardList
    $.on btn, 'click', Header.toggleBoardList

    $.rm $ '#navtopright', fullBoardList
    $.add boardList, fullBoardList
    $.add Header.bar, [boardList, Header.shortcuts, Header.notify, Header.toggle]

    Header.setCustomNav Conf['Custom Board Navigation']
    Header.generateBoardList Conf['boardnav']

    $.sync 'Custom Board Navigation', Header.setCustomNav
    $.sync 'boardnav', Header.generateBoardList

  generateBoardList: (text) ->
    list = $ '#custom-board-list', Header.bar
    $.rmAll list
    return unless text
    as = $$('#full-board-list a', Header.bar)[0...-2] # ignore the Settings and Home links
    nodes = text.match(/[\w@]+(-(all|title|replace|full|index|catalog|text:"[^"]+"))*|[^\w@]+/g).map (t) ->
      if /^[^\w@]/.test t
        return $.tn t
      if /^toggle-all/.test t
        a = $.el 'a',
          className: 'show-board-list-button'
          textContent: (t.match(/-text:"(.+)"/) || [null, '+'])[1]
          href: 'javascript:;'
        $.on a, 'click', Header.toggleBoardList
        return a
      board = if /^current/.test t
        g.BOARD.ID
      else
        t.match(/^[^-]+/)[0]
      for a in as
        if a.textContent is board
          a = a.cloneNode true
          if /-title/.test t
            a.textContent = a.title
          else if /-replace/.test t
            if $.hasClass a, 'current'
              a.textContent = a.title
          else if /-full/.test t
            a.textContent = "/#{board}/ - #{a.title}"
          else if /-(index|catalog|text)/.test t
            if m = t.match /-(index|catalog)/
              a.setAttribute 'data-only', m[1]
              a.href = "//boards.4chan.org/#{board}/"
              a.href += 'catalog' if m[1] is 'catalog'
            if m = t.match /-text:"(.+)"/
              a.textContent = m[1]
          else if board is '@'
            $.addClass a, 'navSmall'
          return a
      $.tn t
    $.add list, nodes

  toggleBoardList: ->
    {bar}  = Header
    custom = $ '#custom-board-list', bar
    full   = $ '#full-board-list',   bar
    showBoardList = !full.hidden
    custom.hidden = !showBoardList
    full.hidden   =  showBoardList

  setBarPosition: (bottom) ->
    Header.barPositionToggler.checked = bottom
    if bottom
      $.rmClass  doc, 'top'
      $.addClass doc, 'bottom'
      $.after Header.bar, Header.notify
    else
      $.rmClass  doc, 'bottom'
      $.addClass doc, 'top'
      $.add Header.bar, Header.notify

  toggleBarPosition: ->
    $.event 'CloseMenu'

    Header.setBarPosition @checked

    Conf['Bottom Header'] = @checked
    $.set 'Bottom Header',  @checked

  setBarFixed: (fixed) ->
    Header.barFixedToggler.checked = fixed
    if fixed
      $.addClass doc, 'fixed'
      $.addClass Header.bar, 'dialog'
    else
      $.rmClass doc, 'fixed'
      $.rmClass Header.bar, 'dialog'

  toggleBarFixed: ->
    $.event 'CloseMenu'

    Header.setBarFixed @checked

    Conf['Fixed Header'] = @checked
    $.set 'Fixed Header',  @checked

  setBarVisibility: (hide) ->
    Header.headerToggler.checked = hide
    $.event 'CloseMenu'
    (if hide then $.addClass else $.rmClass) Header.bar, 'autohide'

  toggleBarVisibility: (e) ->
    return if e.type is 'mousedown' and e.button isnt 0 # not LMB
    hide = if @nodeName is 'INPUT'
      @checked
    else
      !$.hasClass Header.bar, 'autohide'
    Conf['Header auto-hide'] = hide
    $.set 'Header auto-hide', hide
    Header.setBarVisibility hide
    message = if hide
      'The header bar will automatically hide itself.'
    else
      'The header bar will remain visible.'
    new Notification 'info', message, 2

  setFooterVisibility: (hide) ->
    Header.footerToggler.checked = hide
    Header.footer.hidden = hide

  toggleFooterVisibility: ->
    $.event 'CloseMenu'
    hide = if @nodeName is 'INPUT'
      @checked
    else
      !!Header.footer.hidden
    Header.setFooterVisibility hide
    $.set 'Bottom Board List', hide
    message = if hide
      'The bottom navigation will now be hidden.'
    else
      'The bottom navigation will remain visible.'
    new Notification 'info', message, 2

  setCustomNav: (show) ->
    Header.customNavToggler.checked = show
    cust = $ '#custom-board-list', Header.bar
    full = $ '#full-board-list',   Header.bar
    btn = $ '.hide-board-list-button', full
    [cust.hidden, full.hidden] = if show
      [false, true]
    else
      [true, false]

  toggleCustomNav: ->
    $.cb.checked.call @
    Header.setCustomNav @checked

  editCustomNav: ->
    Settings.open 'Rice'
    settings = $.id 'fourchanx-settings'
    $('input[name=boardnav]', settings).focus()

  hashScroll: ->
    return unless (hash = @location.hash) and post = $.id hash[1..]
    return if (Get.postFromRoot post).isHidden
    Header.scrollToPost post

  scrollToPost: (post) ->
    {top} = post.getBoundingClientRect()
    if Conf['Fixed Header'] and not Conf['Bottom Header']
      headRect = Header.bar.getBoundingClientRect()
      top += - headRect.top - headRect.height
    (if $.engine is 'webkit' then d.body else doc).scrollTop += top

  addShortcut: (el) ->
    shortcut = $.el 'span',
      className: 'shortcut'
    $.add shortcut, [$.tn(' ['), el, $.tn(']')]
    $.prepend Header.shortcuts, shortcut

  menuToggle: (e) ->
    Header.menu.toggle e, @, g

  createNotification: (e) ->
    {type, content, lifetime, cb} = e.detail
    notif = new Notification type, content, lifetime
    cb notif if cb