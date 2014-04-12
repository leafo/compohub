
fs = require "fs"


describe "jamhub", ->
  for file in fs.readdirSync "jams/"
    continue unless file.match /\.json$/
    do (file) ->
      full_path = "jams/#{file}"
      it "#{full_path} should have proper syntax", ->
        JSON.parse fs.readFileSync full_path



