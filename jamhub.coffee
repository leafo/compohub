window.J = {}

$.easing.easeInOutQuad = (x, t, b, c, d) ->
  return c/2*t*t + b if ((t/=d/2) < 1)
  return -c/2 * ((--t)*(t-2) - 1) + b

parse_jam_timestamp = (timestamp) ->
  patterns = [
    "YYYY-MM-DD HH:mm Z"
    "YYYY-MM-DD Z"
  ]

  for p in patterns
    d = moment timestamp, p, true
    break if d.isValid()

    d = moment "#{timestamp} +0000", p, true
    break if d.isValid()

  d.isValid() && d.toDate()

class Jam
  constructor: (@data) ->

  length: ->
    @end_date() - @start_date()

  render: ->
    el = $("<div class='jam_cell'></div>")
      .text(@data.name)

  collides_with: (range_start, range_end) ->
    return false if +@start_date() > +range_end
    return false if +@end_date() < +range_start
    true

  start_date: ->
    unless @_start_date
      @_start_date = parse_jam_timestamp @data.start_date
    @_start_date

  end_date: ->
    unless @_end_date
      @_end_date = parse_jam_timestamp @data.end_date

    @_end_date

class J.Hub
  url: "jams.json"
  default_color: [149, 52, 58]
  day_width: 100

  constructor: (el) ->
    window.hub = @
    @el = $ el

    $.get(@url).done (res) =>
      if typeof res == "string"
        res = JSON.parse(res)

      @render_jams(res)
      @render_day_markers()

      @setup_scrollbar()
      @scroll_to_date new Date()

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

  # centers on date
  scroll_to_date: (date) ->
    @calendar.animate {
      scrollLeft: @x_scale date - (@calendar.width() / 2 / @x_ratio())
    }, 600, "easeInOutQuad"

  # pixels per ms
  x_ratio: ->
    @scroller.width() / (@end_date() - @start_date())

  # date to x coordiante
  x_scale: (date) ->
    Math.floor (date - +@start_date()) * @x_ratio()

  jam_color: (jam) ->
    unless jam.color
      @default_color[0] += 27
      [h,s,l] = @default_color
      jam.color = "hsl(#{h}, #{s}%, #{l}%)"

    jam.color

  render_day_markers: ->
    day_length = 1000 * 60 * 60 * 24

    days_el = $("<div class='day_markers'></div>")
      .appendTo(@scroller)

    curr = +@start_date()
    end = +@end_date()
    while curr < end
      date = moment curr
      marker = $("""
      <div class='day_marker'>
        <div class='day_ordinal'>#{date.format "Do"}</div>
        <div class='day_name'>#{date.format "ddd"}</div>
      </div>
      """)
        .css({
          width: "#{@day_width}px"
          left: "#{@x_scale curr}px"
        })
        .appendTo(days_el)

      curr += day_length

  render_jams: (data) ->
    @calendar = @el.find(".calendar")
    unless @calendar.length
      @calendar = $("<div class='calendar'></div>").appendTo(@el)

    @calendar.empty()

    jams = @find_visible_jams data
    stacked = @stack_jams jams

    total_days = (@end_date() - @start_date()) / (1000 * 60 * 60 * 24)
    outer_width = @day_width * total_days

    @scroller = $("<div class='calendar_scrolling'></div>")
      .width(outer_width)
      .appendTo(@calendar)

    rows_el = $("<div class='calendar_rows'></div>")
      .appendTo(@scroller)

    for row in stacked
      row_el = $("<div class='calendar_row'></div>")
        .appendTo(rows_el)

      for jam in row
        left = @x_scale jam.start_date()
        width = @x_scale(jam.end_date()) - left

        jam_el = jam.render()
          .appendTo(row_el)
          .css({
            backgroundColor: @jam_color(jam)
            left: "#{left}px"
            width: "#{width}px"
          })

  find_visible_jams: (jams) ->
    range_start = @start_date()
    range_end = @end_date()

    for jam in jams.one_off
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
    moment().utc().hours(0).minutes(0).seconds(0).milliseconds(0)

  start_date: ->
    @_today().subtract("month", 1).toDate()

  end_date: ->
    @_today().add("month", 1).toDate()
