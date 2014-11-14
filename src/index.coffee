# Spawn wrapper class
# =================================================
# This is an object oriented implementation arround the core `process.spawn`
# command.

# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('spawn')
{spawn} = require 'child_process'
# include alinex modules

# Class definition
# -------------------------------------------------
class Spawn
  @loadcheck = ->

  contructor: () ->

  config = {}
  stdin = ''
  stdout = ''
  stderr = ''
  start
  date
  code
  error

  run: ->
  kill: ->

module.exports = Spawn
