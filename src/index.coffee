# Spawn wrapper class
# =================================================
# This is an object oriented implementation arround the core `process.spawn`
# command.

# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('spawn')
debugCmd = require('debug')('spawn:cmd')
debugOut = require('debug')('spawn:out')
debugErr = require('debug')('spawn:err')
debugBalance = require('debug')('spawn:balance')
chalk = require 'chalk'
{spawn} = require 'child_process'
EventEmitter = require('events').EventEmitter
os = require 'os'
path = require 'path'
carrier = require 'carrier'
# include alinex modules
Config = require 'alinex-config'
# internal helpers
configcheck = require './configcheck'


# the expression to find detailed error messages in unknown processes
ERRORDETECT = /Error:\s((\w| )+)/i


# Class definition
# -------------------------------------------------
class Spawn extends EventEmitter

  @configsearch: [
    path.resolve path.dirname(__dirname), 'var/src/config'
    path.resolve path.dirname(__dirname), 'var/local/config'
  ]

  @init: (config = 'spawn', cb) ->
    return cb?() if @config # already loaded
    @_configSource ?= config # store what to load
    # start resolving configuration
    Config.get @_configSource, @configsearch, configcheck, (err, @config) =>
      # results stored, now check for errors
      console.error err if err
      cb err if cb?

  # overall runtime information
  @weight: 0
  @time: null
  @queue: 0

  # ### Get load limit
  # returns the load limit (between 0.8 and 4.0 with LOAD=1) the curve
  # is strong exponential, meaning higher priorities are higher load values allowed
  @load: (p) -> (3.2 * Math.pow((Math.exp(p)-1)/(Math.E-1),2) + 0.8) * @config.load.limit

  # ### Priority Up
  # This method calculates the new priority before a timeout.
  @priorityup: (p) -> 1 - Math.pow 1-p, 1.1

  # ### Priority Down
  # This method calculates the new priority before a retry.
  @prioritydown: (p) -> Math.pow p, 0.8

  # ### Timeout
  # This gives the number of milliseconds to wait
  @loadtimeout: (p, diff) ->
    q = switch
      when diff < 1.05 then 10
      when diff < 1.1 then 5
      when diff < 1.2 then 2
      else 1
    (59 * (1 - p) + 1) * @config.load.wait / q

  # ### Retry timeout
  @retrytimeout: (p, count) -> Math.pow(count, 3) * 1000

  # ### Nice value
  # This brings the priorities to the operating system
  @nice: (p) ->
    v = if p > 1 then 0 else 1-p
    min = unless process.getuid() then -20 else 0
    ~~(v*(19-min) + min)

  # ### General check methods

  # This is used if no other check method given.
  @checkExitCode = (proc) ->
    unless proc.code? and proc.code is 0
      msg = "Got exit code of #{proc.code}"
      # try to get detailed error message
      if proc.stderr.length
        match = proc.stderr.match ERRORDETECT
        msg += ' caused by ' + match[1] if match
      else
        match = proc.stdout.match ERRORDETECT
        msg += ' caused by ' + match[1] if match
      # create error message
      return new Error "#{msg} in '#{proc.name}'."

  @checkNoStderr = (proc) ->
    if proc.stderr
      msg = proc.stderr.trim().replace /^Error:\s*/i, ''
      return new Error "#{msg} in '#{proc.name}'."

  # Instance methods
  # -------------------------------------------------

  # ### Create instance
  constructor: (@config) ->
    @config.check = @constructor.checkExitCode unless @config.check
    throw new Error "No command given for spawn" unless @config.cmd

  # ### Check if it can start
  loadcheck: (cb) =>
    return cb() unless @config.balance # run immediately
    @constructor.queue--
    load = os.loadavg()[0] / os.cpus().length
    limit = @constructor.load @priority
    # load is ok, but check current added weight
    if load < limit
      # reset weight if new time (unit=10s)
      ntime = ~~(+new Date / @constructor.config.start.interval)
      if ntime isnt @constructor.time
        @constructor.time = ntime
        @constructor.weight = 0
      # calculate new weight
      name = path.basename(@config.cmd)
      nweight = if @constructor.config.weight[name]?
        @constructor.weight + @constructor.config.weight[name]
      else
        @constructor.weight + @constructor.config.weight.DEFAULT
      # check new weight > limit (timeout 1000)
      if @constructor.weight isnt 0 and nweight > @constructor.config.start.limit
        debugBalance chalk.grey "current weight #{nweight} > #{@constructor.config.start.limit},
        waiting #{~~(@constructor.config.start.interval/1000)}s..."
        @constructor.queue++
        @emit 'wait', @constructor.config.start.interval
        return setTimeout (=> @loadcheck cb), @constructor.config.start.interval
      @constructor.weight = nweight
      return cb()
    # rerun check after timeout
    @priority = @constructor.priorityup @priority
    wait =  @constructor.loadtimeout @priority, load/limit
    wait += @constructor.queue*10 # add 10ms waiting time for each job in queue
    debugBalance chalk.grey "load #{load.toFixed 2} > #{limit.toFixed 2} (p=#{@priority.toFixed 2}),
    waiting #{~~(wait/1000)}s"
    @constructor.queue++
    @emit 'wait', wait
    setTimeout (=> @loadcheck cb), wait

  # ### Start the process
  run: (cb) ->
    @constructor.init null, (err) =>
      return cb err if err
      # update config
      @config.balance ?= @constructor.config.defaults.balance
      @config.priority ?= @constructor.config.defaults.priority
      @config.retry ?= @constructor.config.defaults.retry
      # init internal variables
      @retrycount = 0
      @priority = @config.priority
      @name = @config.name ? "#{path.basename @config.cmd} #{(@config.args ? []).join ' '}".trim()
      @_run cb

  _run: (cb) ->
    # check configuration
    unless @config.cmd
      err = new Error "No command specified for spawn."
      @emit 'error', err
      cb err if cb
      return
    @constructor.queue++
    @loadcheck =>
      debug "start job #{@name}"
      # cleanup result
      @stdout = @stderr = ''
      @end = @code = @error = null
      @start = new Date
      # create new subprocess
      cmd = @config.cmd
      args = []
      args = @config.args.slice 0 if @config.args?
      if process.platform is 'linux'
        # add support for nice call
        nice = @constructor.nice @priority
        args.unshift @config.cmd # command
        args.unshift @constructor.nice @priority # nice setting
        args.unshift '-n'
        cmd = 'nice'
      @proc = spawn cmd, args,
        cwd: @config.cwd
        env: @config.env
        uid: @config.uid
        gid: @config.gid
        input: @config.input
        stdio: @config.stdio
      @pid = @proc.pid
      # output debug line
      cmdline = "[#{@pid}] "
      for n,e of @config.env
        cmdline += " #{n}=#{e}"
      cmdline += " #{cmd}"
      for a in args
        if typeof a is 'string'
          cmdline += " #{a.replace /[ ]/, '\ '}"
        else
          cmdline += " #{a}"
      debugCmd cmdline
      # collect output
      stdout = stderr = ''
      carrier.carry @proc.stdout, (line) =>
        @stdout += "#{line}\n"
        @emit 'stdout', line # send through
        debugOut chalk.grey "[#{@pid}] #{line}"
        @config.stdout? line
      , 'utf-8', /\r?\n|\r(?!\n)/ # match also single \r
      carrier.carry @proc.stderr, (line) =>
        @stderr += "#{line}\n"
        @emit 'stderr', line # send through
        debugErr chalk.grey "[#{@pid}] #{line}"
        @config.stderr? line
      , 'utf-8', /\r?\n|\r(?!\n)/ # match also single \r
      # error management
      @proc.on 'error', (@err) =>
        if err.message is 'spawn EMFILE'
          debug chalk.grey "too much processes are opened, waiting 1s..."
          @emit 'wait', 1000
          return setTimeout (=> @_run cb), 1000
        @error = err
        @retry cb
      # process finished
      @proc.on 'close', (@code, signal) =>
        @end = new Date
        if @code
          debugCmd "[#{@pid}] exit: code #{@code} after #{@end-@start}ms"
        else unless @code?
          debugCmd "[#{@pid}] exit: signal #{signal} after #{@end-@start}ms"
          @code = -1
        @emit 'done', @code
        @error = @config.check @
        return @retry cb if @error
        cb @error, @stdout.trim(), @stderr.trim(), @code if cb

  # ### Retry process call after error
  retry: (cb) ->
    @priority = @constructor.prioritydown @priority
    if  @retrycount < @config.retry
      wait = @constructor.retrytimeout @priority, ++@retrycount
      debug "retry #{@retrycount}/#{@config.retry} in #{~~(wait/1000)}s caused by #{@error}"
      @emit 'retry', wait
      return setTimeout (=> @_run cb), wait
    # end of retries
    @emit 'fail', @error
    if @retrycount
      @error.message = @error.message.replace(/\.\s*$/, '') + " (after #{@retrycount+1} tries)."
    debug chalk.red "[#{@pid}] #{@error.toString()}"
    cb @error, @stdout, @stderr, @code if cb


module.exports = Spawn
