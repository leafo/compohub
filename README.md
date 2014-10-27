# Compohub

[![Build Status](https://travis-ci.org/leafo/compohub.svg?branch=master)](https://travis-ci.org/leafo/compohub)

A community run listing of game jams.

## Adding a new jam

Instructions for adding a new jam: <https://github.com/leafo/compohub/tree/master/jams#how-to-add-a-new-jam>

## Running locally

### Node.js server with Grunt
Running the project in a local Node.js server with Grunt should get around any `XMLHttpRequest` errors that may come up when trying to run index.html through `file://`. It also compiles changes to jamhub.js and jamhub.css whenever you make changes.

First start by installing [Node.js](http://nodejs.org/). After installing Node.js, you should be able to start a local server by running the following commands in your command prompt:

    npm install -g grunt-cli
    npm install
    grunt serve

This will:

1. Globally install the grunt-cli package, giving you access to the `grunt` command used to run Grunt tasks.
2. Locally install any Node.js packages required by the project.
3. Run the `serve` Grunt task, which will compile the coffee and sass files, run a local server and listen for any file changes.

### Manually
After checking out the repository you'll need a
[CoffeeScript](http://coffeescript.org/) compiler and a [SCSS
compiler](http://sass-lang.com/). Compile the `coffee` and `scss` files in the
main directory then you can view `index.html` in your browser to see the jams.

## Issues and bugs

Found something wrong or want to see a new feature? Add an issue to the [issues
tracker](https://github.com/leafo/compohub/issues).
