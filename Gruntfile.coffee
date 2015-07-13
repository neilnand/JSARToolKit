module.exports = (grunt) ->


  npmPackage = grunt.file.readJSON "package.json"


  # Grunt Tasks
  gruntTaskList = {
    default: [
      "coffeelint:dev"
      "coffee:demo"
      "sass:demo"
      "jade:demo"
      "exec:dev"
    ]
    devwatch: [
      "watch:demo"
    ]
  }


  # Configuration
  grunt.initConfig
    name: npmPackage.name

    # Ensure we're using good coding standards
    coffeelint:
      dev: [
        "server.coffee"
      ]
      options:
        max_line_length:
          value: 120

    # Convert JADE to HTML
    jade:
      demo:
        options:
          pretty: true
          data:
            debug: true
        expand: true
        src: "demos/**/*.jade"
        ext: ".html"

    # Convert SASS into CSS
    sass:
      demo:
        files: [{
          expand: true
          cwd: "demos"
          src: ["**/*.sass"]
          dest: "demos"
          ext: ".css"
        }]
        options:
          style: "expanded"

    # Convert CoffeeScript into JavaScript
    coffee:
      demo:
        expand: true,
        cwd: "demos"
        src: "**/*.coffee"
        dest: "demos"
        ext: ".js"

    # Watch for changes in development
    watch:
      options:
        livereload: npmPackage.ports.livereload
      demo:
        files: [
          "demos/**/*.coffee"
          "demos/**/*.jade"
          "demos/**/*.sass"
        ]
        tasks: [
          "coffeelint:dev"
          "coffee:demo"
          "jade:demo"
          "sass:demo"
        ]

    # Terminal Commands
    exec:
      dev: "coffee server.coffee #{npmPackage.ports.main}"


  # Load NPM modules
  matchdep = require "matchdep"
  matchdep.filterDev("grunt-*").forEach(grunt.loadNpmTasks)

  # Register Tasks
  for taskName, taskList of gruntTaskList
    grunt.registerTask taskName, taskList