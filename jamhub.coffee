window.J = {}

jams_data = {
  one_off: [
    {
      name: "Leaf Jam"
      start_date: "2014-04-02"
      end_date: "2014-04-05"
    }

    {
      name: "Another Leaf Jam"
      start_date: "2014-04-03"
      end_date: "2014-04-08"
    }

    {
      name: "Cool Leaf Jam"
      start_date: "2014-04-06"
      end_date: "2014-04-09"
    }

    {
      name: "Cool Jam"
      start_date: "2013-04-02"
      end_date: "2013-04-05"
    }
  ]
}

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
  deafult_color: [0, 100, 100]
  day_width: 100

  constructor: (el) ->
    window.hub = @
    @el = $ el
    @render_jams()
    @scroll_to_date new Date()

  scroll_to_date: (date) ->
    @el.scrollLeft @x_scale date

  x_scale: (date) ->
    Math.floor (date - +@start_date()) / (@end_date() - @start_date()) * @scroller.width()

  render_jams: ->
    @el.empty()
    jams = @find_visible_jams jams_data
    stacked = @stack_jams jams

    total_days = (@end_date() - @start_date()) / (1000 * 60 * 60 * 24)
    outer_width = @day_width * total_days

    @scroller = $("<div class='calendar_scrolling'></div>")
      .width(outer_width)
      .appendTo(@el)

    for row in stacked
      row_el = $("<div class='calendar_row'></div>")
        .appendTo(@scroller)

      for jam in row
        left = @x_scale jam.start_date()
        width = @x_scale(jam.end_date()) - left

        console.log jam.data.name, {
          left: left
          width: width
        }

        jam_el = jam.render()
          .appendTo(row_el)
          .css({
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
