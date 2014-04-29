moment = require "moment"
{J} = require "./jamhub"

module.exports = (grunt) ->
  jam_files = [
    "jams/2011.json"
    "jams/2012.json"
    "jams/2013.json"
    "jams/2014.json"
  ]

  assemble = {
    options: {
      layout: "templates/layout.hbs"
    }
  }

  for file in jam_files
    assemble = build_jam_pages assemble, grunt.file.readJSON file

  grunt.initConfig {
    pkg: grunt.file.readJSON "package.json"

    coffee: {
      compile: {
        files: {
          "jamhub.js": "jamhub.coffee"
        }
      }
    }

    sass: {
      compile: {
        files: {
          "jamhub.css": "jamhub.scss"
        }
      }
    }

    assemble: assemble
  }

  grunt.loadNpmTasks "assemble"
  grunt.loadNpmTasks "grunt-contrib-sass"
  grunt.loadNpmTasks "grunt-contrib-coffee"

  grunt.registerTask "default", ["coffee", "sass"]

build_jam_pages = (params, jam_data) ->
  params.options ||= {}

  # images is reserved name
  params.options.jams_by_slug ||= {
    images: true
  }

  jams_by_slug = params.options.jams_by_slug

  for jam in jam_data.jams
    jam.slug = J.slugify jam.name
    [start_date] = J.parse_jam_timestamp jam.start_date
    start_date = moment start_date

    # name taken
    if jams_by_slug[jam.slug]
      jam.slug += "-#{start_date.year()}-#{start_date.format("MMMM")}".toLowerCase()

    # name still taken, add day
    if jams_by_slug[jam.slug]
      jam.slug += "-#{start_date.date()}".toLowerCase()

    if jams_by_slug[jam.slug]
      throw "jam name still taken"

    jams_by_slug[jam.slug] = jam

    params["jam_#{jam.slug}"] = {
      options: { jam: jam }
      src: "templates/jam.hbs"
      dest: "jams/#{start_date.year()}/#{jam.slug}/index.html"
    }

  params
