# Spawn wrapper class
# =================================================
# This is an object oriented implementation arround the core `process.spawn`
# command.

# Node Modules
# -------------------------------------------------

# include base modules
debug = require('debug')('spawn')
debugCmd = require('debug')('spawn:cmd')
chalk = require 'chalk'
{spawn} = require 'child_process'
EventEmitter = require('events').EventEmitter
os = require 'os'
path = require 'path'
# include alinex modules


# Class definition
# -------------------------------------------------
class Spawn extends EventEmitter

  # Machine setup
  # -------------------------------------------------
  # This maybe changed per machine.
  @LOAD: 1 # limit system load (limit will be between 0.8*LOAD and 4*LOAD)
  @WAIT: 1 # wait between WAIT seconds and WAIT minutes + queue size
  # The weight which can be started per each start period
  @WEIGHTTIME: 10 # time for each period in seconds
  @WEIGHTLIMIT: 10 # size of load allowed for each period
  # ### Specific weights for each command
  # A weight of 1 means that it normally may be started 1/sec.
  # If you have a setting above the WEIGHTLIMIT it is started only as first
  # of a time period. Best way is to have the weights < WEIGHTLIMIT to ensure
  # proper priority handling.
  @WEIGHT:
    DEFAULT: 0.1
    ffmpeg: 5
    lame: 5

  # default values
  @priority: 0.3   # default priority if none given

  # overall runtime information
  @weight: 0
  @time: null
  @queue: 0

  # ### Get load limit
  # returns the load limit (between 0.8 and 4.0 with LOAD=1) the curve
  # is strong exponential, meaning higher priorities are higher load values allowed
  @load: (p) -> (3.2 * Math.pow((Math.exp(p)-1)/(Math.E-1),2) + 0.8) * @LOAD

  # ### Priority Up
  # This method updates the priority before a timeout.
  @priorityup: (p) -> 1 - Math.pow 1-p, 1.1

  # ### Timeout
  # This gives the number of milliseconds to wait
  @loadtimeout: (p) -> (59 * (1 - p) + 1) * @WAIT * 1000

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
    return cb() if @config.priority > 1 # run immediately
    @constructor.queue--
    load = os.loadavg()[0] / os.cpus().length
    limit = @constructor.load @config.priority
    debug chalk.grey "current load is #{load.toFixed 2},
    limit is #{limit.toFixed 2} (p=#{@config.priority.toFixed 2})"
    # load is ok, but check current added weight
    if load < limit
      # reset weight if new time (unit=10s)
      ntime = ~~(+new Date / @constructor.WEIGHTTIME / 1000)
      if ntime isnt @constructor.time
        @constructor.time = ntime
        @constructor.weight = 0
      # calculate new weight
      name = path.basename(@config.cmd)
      nweight = if @constructor.WEIGHT[name]?
        @constructor.weight + @constructor.WEIGHT[name]
      else
        @constructor.weight + @constructor.WEIGHT.DEFAULT
      # check new weight > limit (timeout 1000)
      if @constructor.weight isnt 0 and nweight > @constructor.WEIGHTLIMIT
        debug chalk.grey "current weight to high (#{@constructor.weight}) at #{@constructor.time}, waiting..."
        @constructor.queue++
        return setTimeout (=> @loadcheck cb), 10000
      @constructor.weight = nweight
      debug chalk.grey "current weight limit is now #{@constructor.weight} at #{@constructor.time}"
      return cb()
    # rerun check after timeout
    @config.priority = @constructor.priorityup @config.priority
    wait =  @constructor.loadtimeout @config.priority
    wait += @constructor.queue*10 # add 10ms waiting time for each job in queue
    debug chalk.grey "wait #{~~(wait/1000)}s with process for load to go below #{limit.toFixed 2}"
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
    debug "add job #{@config.cmd} #{(@config.args ? []).join ' '}"
    @constructor.queue++
    @loadcheck =>
      debug "start job #{@config.cmd} #{(@config.args ? []).join ' '}"
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
      debugCmd "[#{@pid}] #{@config.cmd} #{(@config.args ? []).join ' '}"
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
            debugCmd chalk.grey "[#{proc.pid}] out: #{line}"
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
            debugCmd chalk.grey "[#{proc.pid}] err: #{line}"
      # cleanup buffers
      bufferClean = =>
        if stdout
          @stdout = stdout
          @emit 'stdout', stdout
          debugCmd chalk.grey "[#{proc.pid}] out: #{stdout}"
        if stderr
          @stderr = stderr
          @emit 'stderr', stderr
          debugCmd chalk.grey "[#{proc.pid}] out: #{stderr}"
      # error management
      proc.on 'error', (@err) =>
        bufferClean()
        @error = err
        @emit 'error', err
        debugCmd chalk.red "[#{proc.pid}] #{err.toString()}"
      # process finished
      proc.on 'close', (@code) =>
        @end = new Date
        bufferClean()
        debugCmd "[#{proc.pid}] exit: #{@code} after #{@end-@start}ms"
        @emit 'done', @code
        @error = @config.check @
        if cb
          cb @error, @stdout, @stderr, @code


module.exports = Spawn
