moment = require "moment"
{J} = require "./jamhub"

module.exports = (grunt) ->
  jam_files = [
    "jams/2011.json"
    "jams/2012.json"
    "jams/2013.json"
    "jams/2014.json"
  ]

  assemble = {}
  for file in jam_files
    build_jam_pages assemble, grunt.file.readJSON file

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
      options: { jam: jam }
      src: "templates/jam.hbs"
      dest: "#{jam.local_url}/index.html"
    }

  params
