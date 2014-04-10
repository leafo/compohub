window.J = {}

$.easing.easeInOutQuad = (x, t, b, c, d) ->
  return c/2*t*t + b if ((t/=d/2) < 1)
  return -c/2 * ((--t)*(t-2) - 1) + b

$.fn.draggable = (opts={}) ->
  # TODO: add touchstart, etc
  body = $ document.body
  html = $ "html"

  mouse_x = 0
  mouse_y = 0

  drag_stop = (e) =>
    body.removeClass("dragging")
    html.off("mousemove", drag_move)
    opts.stop?()

  drag_move = (e) =>
    dx = e.pageX - mouse_x
    dy = e.pageY - mouse_y

    mouse_x += dx
    mouse_y += dy

    opts.move? dx, dy

  # start, stop, move
  @on "mousedown", (e) =>
    return if body.is ".dragging"
    return if opts.skip_drag? e

    body.addClass "dragging"
    mouse_x = e.pageX
    mouse_y = e.pageY

    html.one "mouseup", drag_stop
    html.on "mousemove", drag_move
    opts.start?()

J.parse_jam_timestamp = parse_jam_timestamp = (timestamp) ->
  patterns = [
    "YYYY-MM-DD HH:mm:ss Z"
    "YYYY-MM-DD HH:mm Z"
    "YYYY-MM-DD"
  ]

  for p in patterns
    d = moment timestamp, p, true
    break if d.isValid()

    d = moment "#{timestamp} +0000", p, true
    break if d.isValid()

  d.isValid() && d.toDate()

class Jam
  box_tpl: _.template """
    <div class="jam_box<% if (image) { %> has_image<% }%>">
      <% if (image) { %>
        <a href="<%- url %>">
          <div class="cover_image" style="background-image: url(<%- image %>)"></div>
        </a>
      <% } %>

      <h3>
        <% if (url) { %>
          <a href="<%- url %>"><%- name %></a>
        <% } else { %>
          <%- name %>
        <% }%>
      </h3>

      <% if (url) { %>
        <p class="jam_link">
           <a href="<%- url %>"><%- url %></a>
        </p>
      <% }%>
      <p><%- description %></p>
      <%= time_data %>
    </div>
  """

  in_progress_tpl: _.template """
    <div class="progress_outer">
      <div class="time_labels">
        <div class="left_label"><%- start_label %></div>
        <div class="right_label"><%- end_label %></div>
      </div>

      <div class="progress">
        <div class="progress_inner" style="width: <%= percent_complete  %>%"></div>
      </div>

      <div class="remaining_label"><%- remaining_label %> left</div>
    </div>
  """

  time_tpl: _.template """
    <div class="time_data">
      <p><%- time_label %></p>
    </div>
  """

  calendar_template: _.template """
    <div class='jam_cell'>
      <span class="fixed_label">
        <a href="#"><%- name %></a>
      </span>
    </div>
  """

  constructor: (@data) ->

  length: ->
    @end_date() - @start_date()

  render_for_calendar: ->
    $(@calendar_template @data).data "jam", @

  render: ->
    $ @box_tpl $.extend {
      image: false
      time_data: @render_time_data()
    }, @data

  render_time_data: ->
    if @in_progress()
      progress = (new Date() - @start_date()) / (@end_date() - @start_date())
      @in_progress_tpl {
        percent_complete: Math.floor progress * 100
        start_label: @date_format @start_date()
        end_label: @date_format @end_date()
        remaining_label: moment(@end_date()).fromNow true
      }
    else if @before_start()
      @time_tpl {
        time_label: "Ended #{moment(@start_date()).fromNow true} ago"
      }
    else if @after_end()
      @time_tpl {
        time_label: "Starts in #{moment(@end_date()).fromNow true}"
      }

  date_format: (date) ->
    ago = moment(new Date).subtract(1, "month").toDate()
    future = moment(new Date).add(1, "month").toDate()

    if date < ago || date > future
      moment(date).format("l LT")
    else
      moment(date).format("ddd Do, LT")

  collides_with: (range_start, range_end) ->
    return false if +@start_date() > +range_end
    return false if +@end_date() < +range_start
    true

  in_progress: ->
    now = +new Date()
    now >= +@start_date() && now <= +@end_date()

  before_start: ->
    now = +new Date()
    now < +@start_date()

  after_end: ->
    now = +new Date()
    now > +@end_date()

  start_date: ->
    unless @_start_date
      @_start_date = parse_jam_timestamp @data.start_date
    @_start_date

  end_date: ->
    unless @_end_date
      @_end_date = parse_jam_timestamp @data.end_date

    @_end_date

class J.Hub
  url: "jams.all.json"
  default_color: [149, 52, 58]
  day_width: 100

  constructor: (el) ->
    window.hub = @
    @el = $ el
    @setup_events()

    $.get(@url).done (res) =>
      if typeof res == "string"
        res = JSON.parse(res)

      @render_jams(res)
      @render_day_markers()
      @render_month_markers()
      @render_elapsed_time()

      @setup_scrollbar()
      @setup_fixed_labels()
      @scroll_to_date new Date()

      @setup_dragging()

      list = $ ".jam_list"
      for jam in @jams
        list.append jam.render()

  setup_events: ->
    @el.on "click", ".jam_cell a", (e) =>
      target = $(e.currentTarget).closest ".jam_cell"
      console.log "click", target.data "jam"
      e.preventDefault()

  setup_scrollbar: ->
    scrollbar_outer = $("""
    <div class="scrollbar_outer">
      <div class="scrollbar"></div>
    </div>
    """).appendTo(@el)

    @scrollbar = scrollbar_outer.find(".scrollbar")
    setTimeout (=> @scrollbar.addClass "visible"), 0

    update_scroll = =>
      left = @calendar.scrollLeft()
      width = @calendar.width()
      inner_width = @scroller.width()

      @scrollbar.css {
        left: "#{Math.floor (left / inner_width) * width}px"
        right: "#{Math.floor ((inner_width - (left + width)) / inner_width) * width}px"
      }

    @calendar.on "scroll", update_scroll
    update_scroll()

  move_calendar: (dx, dy) ->
    @calendar.scrollLeft @calendar.scrollLeft() - dx
    @update_labels?()

  setup_dragging: (el) ->
    @calendar.draggable {
      skip_drag: (e) =>
        return true if $(e.target).closest("a").length

      move: (dx, dy) =>
        @move_calendar dx, dy
    }

    @el.find(".scrollbar").draggable {
      move: (dx, dy) =>
        scale = @scroller.width() / @calendar.width()
        @move_calendar dx * -scale, dy
    }

    @el.on "click", ".scrollbar_outer", (e) =>
      return if $(e.target).is ".scrollbar"
      left = $(e.currentTarget).find(".scrollbar").offset().left
      left_mouse = e.pageX
      width = Math.floor @scroller.width() / 10

      if left_mouse < left
        @move_calendar width, 0
      else
        @move_calendar -width, 0

  setup_fixed_labels: ->
    @update_labels = =>
      viewport_left = @calendar.scrollLeft()
      viewport_right = viewport_left + @calendar.width()

      @fixed_labels ||= ($(el) for el in @calendar.find ".fixed_label")

      for label in @fixed_labels
        parent = label.parent()
        left = parent.position().left
        right = left + parent.width()
        visible = right >= viewport_left && left <= viewport_right
        parent.toggleClass "visible", visible

        label_width = label.outerWidth()

        margin_left = viewport_left - left

        margin_left = if margin_left > 0
          max_right = (right - left) - label_width
          margin_left = Math.min margin_left, max_right
          "#{margin_left}px"
        else
          ""

        label.css "marginLeft", margin_left

    @update_labels()

  # centers on date
  scroll_to_date: (date) ->
    @calendar.animate {
      scrollLeft: @x_scale date - (@calendar.width() / 2 / @x_ratio())
    }, {
      duration: 600
      easing: "easeInOutQuad"
      progress: =>
        @update_labels?()
    }

  # pixels per ms
  x_ratio: ->
    @scroller.width() / (@end_date() - @start_date())

  # date to x coordiante
  x_scale: (date) ->
    Math.floor (date - +@start_date()) * @x_ratio()

  x_scale_truncated: (date) ->
    Math.min @scroller.width(), Math.max 0, @x_scale(date)

  jam_color: (jam) ->
    unless jam.color
      @default_color[0] += 27
      [h,s,l] = @default_color
      jam.color = "hsl(#{h}, #{s}%, #{l}%)"

    jam.color

  render_elapsed_time: ->
    el = $("""<div class="elapsed_time"></div>""")
      .css("width", @x_scale(new Date))
      .appendTo @scroller

  render_month_markers: ->
    markers = $("<div class='month_markers'></div>")
      .appendTo(@scroller)

    curr = moment(@start_date())
      .date(1).hours(0).minutes(0).seconds(0).milliseconds(0)

    end = +@end_date()
    while +curr.toDate() < end
      curr_end = curr.clone().add("month", 1)

      left = @x_scale_truncated curr.toDate()
      right = @x_scale_truncated curr_end.toDate()

      marker = $("""
        <div class="month_marker">
          <span class="fixed_label">
            #{curr.format("MMMM")}
          </span>
        </div>
      """)
        .css({
          left: "#{left}px"
          width: "#{right - left}px"
        })
        .appendTo(markers)

      curr = curr_end

  render_day_markers: ->
    day_length = 1000 * 60 * 60 * 24

    markers = $("<div class='day_markers'></div>")
      .appendTo(@scroller)

    curr = moment @start_date()

    end = +@end_date()
    while +curr.toDate() < end
      curr_end = curr.clone().add("day", 1)

      left = @x_scale_truncated curr.toDate()
      right = @x_scale_truncated curr_end.toDate()

      marker = $("""
      <div class='day_marker'>
        <div class='day_ordinal'>#{curr.format "Do"}</div>
        <div class='day_name'>#{curr.format "ddd"}</div>
      </div>
      """)
        .css({
          width: "#{right - left}px"
          left: "#{left}px"
        })
        .appendTo(markers)

      curr = curr_end

  render_jams: (data) ->
    @calendar = @el.find(".calendar")
    unless @calendar.length
      @calendar = $("<div class='calendar'></div>").appendTo(@el)

    @calendar.empty()

    @jams = @find_visible_jams data
    stacked = @stack_jams @jams

    total_days = (@end_date() - @start_date()) / (1000 * 60 * 60 * 24)
    outer_width = @day_width * total_days

    @scroller = $("<div class='calendar_scrolling'></div>")
      .width(outer_width)
      .height(40*3 + 6 + stacked.length * (40+3))
      .appendTo(@calendar)

    rows_el = $("<div class='calendar_rows'></div>")
      .appendTo(@scroller)

    for row in stacked
      row_el = $("<div class='calendar_row'></div>")
        .appendTo(rows_el)

      for jam in row
        left = @x_scale_truncated jam.start_date()
        width = @x_scale_truncated(jam.end_date()) - left

        jam_el = jam.render_for_calendar()
          .appendTo(row_el)
          .css({
            backgroundColor: @jam_color(jam)
            left: "#{left}px"
            width: "#{width}px"
          })

        if jam_el.find(".fixed_label").width() > jam_el.width()
          jam_el.addClass "small_text"

  find_visible_jams: (data) ->
    range_start = @start_date()
    range_end = @end_date()

    for jam in data.jams
      jam = new Jam jam
      continue unless jam.collides_with range_start, range_end
      jam

  sort_by_length: (jams) ->
    jams.sort (a,b) ->
      b.length() - a.length()

  stack_jams: (jams) ->
    rows = []
    @sort_by_length jams

    for jam in jams
      placed = false

      for row in rows
        collided = false
        for other_jam in row
          collided = jam.collides_with other_jam.start_date(), other_jam.end_date()
          break if collided

        unless collided
          row.push jam
          placed = true
          break

      unless placed
        rows.push [jam]

    rows

  _today: ->
    moment().hours(0).minutes(0).seconds(0).milliseconds(0)

  start_date: ->
    @_today().subtract("month", 1).toDate()

  end_date: ->
    @_today().add("month", 1).toDate()
