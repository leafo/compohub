moment = require "moment"
ical = require "ical-generator"

{J} = require "./jamhub"

module.exports = (grunt) ->
  require("load-grunt-tasks")(grunt)

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

  build_tag_pages assemble
  build_jam_root_page assemble

  grunt.initConfig {
    pkg: grunt.file.readJSON "package.json"

    watch: {
      coffee: {
        files: ['jamhub.coffee']
        tasks: ['coffee']
        options: {
          spawn: false
        }
      }

      sass: {
        files: ['jamhub.scss']
        tasks: ['sass']
        options: {
          spawn: false
        }
      }
    }

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

  grunt.registerTask "ical", "create ical feed", ->
    build_ical_feed assemble

  grunt.registerTask "default", ["coffee", "sass"]

build_ical_feed = (params) ->
  calendar = ical()
  calendar.setDomain('compohub.net')
  calendar.setName('Compohub Game Jams')

  #Get a list of jams in sorted order
  jams = []
  for slug, jam of params.options.jams_by_slug
    jams.push(jam)
    jams.sort (a, b) ->
      b.start_date - a.start_date

  #iCal library does not propery escape carriage returns
  escape_carriage_return = (str) ->
    str.replace(/\r/g, (match) -> "" )

  #Iterate through jams, adding it to ical builder
  for jam in jams
    #Parse dates
    [start_date] = J.parse_jam_timestamp jam.start_date
    [end_date] = J.parse_jam_timestamp jam.end_date

    #Escape Summary and Description
    summary = if jam.name? then escape_carriage_return(jam.name) else ""
    description = if jam.description? then escape_carriage_return(jam.description) else ""

    #Ensure that there is both a start_date and end_date for this event
    continue unless start_date
    continue unless end_date

    calendar.addEvent {
      start: start_date,
      end: end_date,
      summary: summary,
      description: description,
      url: jam.url,
      uid: jam.slug
    }

  calendar.saveSync("feed.ics")

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

format_jam_for_list = (jam, start_date) ->
  {
    start_date: +start_date.toDate()
    simple_date: start_date.format("MMM D")
    url: "#{jam.local_url}"
    jam: jam
  }

build_tag_pages = (params) ->
  jams = params.options.jams_by_slug

  jams_by_tag = {}

  for slug of jams
    jam = jams[slug]
    [start_date] = J.parse_jam_timestamp jam.start_date
    continue unless start_date
    start_date = moment start_date

    wrapped = {
      start_date: +start_date.toDate()
      simple_date: start_date.format("YYYY-MM-DD")
      url: "#{jam.local_url}"
      jam: jam
    }

    if jam.tags
      for tag in jam.tags
        jams_by_tag[tag] ||= []
        jams_by_tag[tag].push wrapped

  for tag of jams_by_tag
    jams = jams_by_tag[tag]
    jams.sort (a, b) ->
      b.start_date - a.start_date

    params["tag_#{tag}"] = {
      options: {
        tag: tag
        jams: jams
        page_title: "Jams taged '#{tag}'"
        root: "../.."
      }

      src: "templates/tag.hbs"
      dest: "tags/#{tag}/index.html"
    }

build_jam_root_page = (params) ->
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

