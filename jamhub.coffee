window.J = {}

jams = {
  one_off: [
    {
      name: "Leaf Jam"
      start_date: "2014-04-02"
      end_date: "2014-04-05"
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
    +@end_date() - +@start_date()

  collides_with: (range_start, range_end) ->
    return false if +@start_date() > +range_end
    return false if +@end_date() < +range_start
    true

  start_date: ->
    unless @_end_date
      @_end_date = parse_jam_timestamp @data.start_date

    @_end_date

  end_date: ->
    unless @_end_date
      @_end_date = parse_jam_timestamp @data.start_date

    @_end_date

class J.Hub
  constructor: (el) ->
    window.hub = @

    @el = $ el
    console.log @start_date()
    console.log @end_date()
    console.log @find_visible_jams(jams)


  find_visible_jams: (jams) ->
    range_start = @start_date()
    range_end = @end_date()

    for jam in jams.one_off
      jam = new Jam jam
      continue unless jam.collides_with range_start, range_end
      jam

  sort_by_length: ->

  _today: ->
    moment().utc().hours(0).minutes(0).seconds(0).milliseconds(0)

  start_date: ->
    @_today().subtract("month", 1).toDate()

  end_date: ->
    @_today().add("month", 1).toDate()
