window.J = {}

jams = {
  one_off: [
    {
      name: "Leaf Jam"
      start_date: "2014-4-2"
      end_date: "2014-4-5"
    }
  ]
}


class J.Hub
  constructor: (el) ->
    @el = $ el
    console.log @start_date()
    console.log @end_date()

  find_visible_jams: (jams) =>
    jams = []

    for jam in jams.one_off
      null

  _today: ->
    moment().utc().hours(0).minutes(0).seconds(0).milliseconds(0)

  start_date: ->
    @_today().subtract("month", 1)
    

  end_date: ->
    @_today().add("month", 1)
