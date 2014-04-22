module.exports = (grunt) ->
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
      dist: {
        files: {
          "jamhub.css": "jamhub.scss"
        }
      }
    }
  }

  grunt.loadNpmTasks "assemble"
  grunt.loadNpmTasks "grunt-contrib-sass"
  grunt.loadNpmTasks "grunt-contrib-coffee"


  grunt.registerTask "default", ["coffee", "sass"]
