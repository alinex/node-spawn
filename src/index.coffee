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
os = require 'os'
path = require 'path'
# include alinex modules

# General setup
# -------------------------------------------------
# This maybe changed per machine.
LOAD = 1 # default priority run till load of 1
WAIT = 10 # wait between 10s and 10m
# The weight which can be started per each second
WEIGHTLIMIT = 1000
WEIGHT =
  DEFAULT: 10
  media: 500
  ffmpeg: 500
  SITMarkAVMultiContainerFFmpeg: 500
  SITMarkAudioAPEmbedderCLI: 1000
  SITMarkAudioMP3Container: 100
  SITMarkAudioAPDetectorCLI: 1000

# Class definition
# -------------------------------------------------
class Spawn extends EventEmitter

  # default values
  @priority: 0.3   # default priority if none given

  # overall runtime information
  @weight: 0
  @time: null
  @queue: 0

  # ### Get load limit
  # returns the load limit (between 0.8 and 4.0 with LOAD=1) the curve
  # is strong exponential, meaning higher priorities are higher load values allowed
  @load: (p) -> (3.2 * Math.pow((Math.exp(p)-1)/(Math.E-1),2) + 0.8) * LOAD

  # ### Priority Up
  # This method updates the priority before a timeout.
  @priorityup: (p) -> 1 - Math.pow 1-p, 1.1

  # ### Timeout
  # This gives the number of milliseconds to wait
  @loadtimeout: (p) -> (59 * (1 - p) + 1) * WAIT * 1000

  # Instance methods
  # -------------------------------------------------

  # ### Create instance
  constructor: (@config) ->
    unless @config.check
      @config.check = (proc) ->
        unless proc.code? and proc.code is 0
          new Error "Got exit code of #{proc.code}."

  # ### Check if it can start
  loadcheck: (cb) =>
    @constructor.queue--
    load = os.loadavg()[0] / os.cpus().length
    limit = @constructor.load @config.priority
    debug "current load is #{load.toFixed 2},
    limit is #{limit.toFixed 2} (p=#{@config.priority.toFixed 2})"
    # load is ok, but check current added weight
    if load < limit
      # reset weight if new time
      ntime = ~~(+new Date / 1000)
      if ntime isnt @constructor.time
        @constructor.time = ntime
        @constructor.weight = 0
      # check current weight > limit (timeout 1000)
      if @constructor.weight > WEIGHTLIMIT
        debug "current weight to high (#{@constructor.weight}) at #{@constructor.time}, waiting..."
        @constructor.queue++
        return setTimeout (=> @loadcheck cb), 1000
      # add weight
      name = path.basename(@config.cmd)
      @constructor.weight += if WEIGHT[name]? then WEIGHT[name] else WEIGHT.DEFAULT
      debug "new weight is #{@constructor.weight} at #{@constructor.time}"
      return cb()
    # rerun check after timeout
    @config.priority = @constructor.priorityup @config.priority
    wait =  @constructor.loadtimeout @config.priority
    wait += @constructor.queue*10 # add 10ms waiting time for each job in queue
    debug "wait #{~~(wait/1000)}s with process for load to go below #{@config.priority}"
    @constructor.queue++
    setTimeout (=> @loadcheck cb), wait

  # ### Start the process
  run: (cb) ->
    # check configuration
    unless @config.cmd
      err = new Error "No command specified for spawn."
      @emit 'error', err
      cb err if cb
      return
    @config.priority ?= @constructor.priority
    # check system load
    @constructor.queue++
    @loadcheck =>
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
      debug "[#{@pid}] #{@config.cmd} #{(@config.args ? []).join ' '}"
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
        @error = err
        @emit 'error', err
        debug chalk.red "[#{proc.pid}] #{err.toString()}"
      # process finished
      proc.on 'close', (@code) =>
        @end = new Date
        bufferClean()
        debug "[#{proc.pid}] exit: #{@code} after #{@end-@start}ms"
        @emit 'done', @code
        @error = @config.check @
        if cb
          cb @error, @stdout, @stderr, @code


module.exports = Spawn
