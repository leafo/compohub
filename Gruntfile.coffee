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
      cache_buster: "#{+new Date}"
      layout: "templates/layout.hbs"
      root: "../../.." # path to index from jam page
    }

    all_jams: {
      options: {
        root: ".."
        page_title: "All game jams"
      }
      src: "templates/all_jams.hbs"
      dest: "jams/index.html"
    }
  }

  for file in jam_files
    build_jam_pages assemble, grunt.file.readJSON file

  build_jam_root assemble

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

  J.Jams.slugify_jams jam_data.jams, params.options.jams_by_slug

  for jam in jam_data.jams
    params["jam_#{jam.slug}"] = {
      options: {
        jam: jam
        jam_json: JSON.stringify(jam)
        page_title: jam.name
      }
      src: "templates/jam.hbs"
      dest: "#{jam.local_url}/index.html"
    }

  params

build_jam_root = (params) ->
  jams = params.options.jams_by_slug

  jams_by_year = {}
  for slug of jams
    jam = jams[slug]
    [start_date] = J.parse_jam_timestamp jam.start_date
    continue unless start_date
    start_date = moment start_date
    year = start_date.year()

    wrapped = {
      start_date: +start_date.toDate()
      simple_date: start_date.format("MMM D")
      url: "#{jam.local_url}"
      jam: jam
    }

    unless jams_by_year[year]
      jams_by_year[year] = []

    jams_by_year[year].push wrapped

  year_tuples = for year of jams_by_year
    list = jams_by_year[year]
    list.sort (a, b) ->
      a.start_date - b.start_date

    { year: year, jams: list }

  year_tuples.sort (a, b) ->
    b.year - a.year

  params.all_jams.options.jams_by_year = year_tuples

