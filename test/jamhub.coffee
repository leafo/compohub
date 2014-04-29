
fs = require "fs"
moment = require "moment"

{J} = require "../jamhub"

check_date = (val) ->
  [valid, date] = J.parse_jam_timestamp val
  valid

has_attrs = (jam, attrs...) ->
  name = jam.name || "jam"
  it "`#{name}` should have required attributes", ->
    for attr in attrs
      t = typeof attr
      if t == "object"
        [attr, params] = attr

      if !jam[attr]? && !params?.optional
        throw new Error "missing attribute `#{attr}`"

      if params && jam[attr]?
        if params.type && !jam[attr] instanceof params.type
          throw new Error "type of `#{attr}` should be `#{params.type}`"

        if params.validate && !params.validate?(jam[attr], attr)
          throw new Error "`#{attr}` is invalid format"


describe "jamhub", ->
  for file in fs.readdirSync "jams/"
    continue unless file.match /\.json$/
    do (file) ->
      full_path = "jams/#{file}"
      it "`#{full_path}` should have proper syntax", ->
        JSON.parse fs.readFileSync full_path

      try
        jams = JSON.parse fs.readFileSync full_path
      catch error

      if jams
        for jam in jams.jams
          has_attrs jam, "name", "url",
            ["start_date", validate: check_date],
            ["end_date", validate: check_date],
            ["tags", optional: true, type: Array],
            ["themes", optional: true, type: Array],


