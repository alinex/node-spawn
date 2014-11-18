# Spawn wrapper class
# =================================================
# This is an object oriented implementation arround the core `process.spawn`
# command.

# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('spawn')
chalk = require 'chalk'
{spawn} = require 'child_process'
EventEmitter = require('events').EventEmitter
# include alinex modules

# Class definition
# -------------------------------------------------
class Spawn extends EventEmitter
  @loadcheck = ->

  constructor: (@config) ->
    unless @config.check
      @config.check = (proc) -> proc.code? and proc.code is 0

  run: (cb) ->
    unless @config.cmd
      err = new Error "No command specified for spawn."
      @emit 'error', err
      cb err if cb
      return
    # cleanup result
    @stdout = @stderr = ''
    @end = @code = @error = null
    @start = new Date
    # create new subprocess
    proc = spawn @config.cmd, @config.args,
      cwd: @config.cwd
      env: @config.env
      uid: @config.uid
      gif: @config.gid
    @pid = proc.pid
    debug "[#{@pid}] #{@config.cmd} #{(args ? []).join ' '}"
    # collect output
    stdout = stderr = ''
    proc.stdout.setEncoding "utf8"
    proc.stdout.on 'data', (data) =>
      stdout += data.toString()
      pos = stdout.lastIndexOf '\n'
      if ~pos++
        # copy into general buffer after line completed
        text = stdout.substring 0, pos
        stdout = stdout.substring pos
        @stdout += text
        @emit 'stdout', text # send through
        for line in text.split /\n/
          debug chalk.grey "[#{proc.pid}] out: #{line}"
    proc.stderr.setEncoding "utf8"
    proc.stderr.on 'data', (data) =>
      stderr += data.toString()
      pos = stderr.lastIndexOf '\n'
      if ~pos++
        # copy into general buffer after line completed
        text = stderr.substring 0, pos
        stderr = stderr.substring pos
        @stderr += text
        @emit 'stderr', text # send through
        for line in text.split /\n/
          debug chalk.grey "[#{proc.pid}] err: #{line}"
    # cleanup buffers
    bufferClean = =>
      if stdout
        @stdout = stdout
        @emit 'stdout', stdout
        debug chalk.grey "[#{proc.pid}] out: #{stdout}"
      if stderr
        @stderr = stderr
        @emit 'stderr', stderr
        debug chalk.grey "[#{proc.pid}] out: #{stderr}"
    # error management
    proc.on 'error', (@err) =>
      bufferClean()
      @emit 'error', err
      debug chalk.red "[#{proc.pid}] #{err.toString()}"
    # process finished
    proc.on 'close', (@code) =>
      @end = new Date
      bufferClean()
      debug "[#{proc.pid}] exit: #{@code}"
      @emit 'done', @code
      if cb
        cb @error, @stdout, @stderr, @code

  success: -> @config.check @


module.exports = Spawn
