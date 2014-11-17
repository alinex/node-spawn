chai = require 'chai'
expect = chai.expect
require('alinex-error').install()

describe "Spawn wrapper", ->

  Spawn = require '../../lib/index'

  describe "class", ->

    it "should be retrieved from factory", ->
      proc = new Spawn
        cmd: 'date'
      expect(proc, 'instance').to.exist
      expect(proc.config, 'config').to.exist
      expect(proc.config.cmd, 'command').to.equal 'date'

  describe "run", ->

    it "should work with callback", (done) ->
      proc = new Spawn
        cmd: 'date'
      proc.run (err, stdout, stderr, code) ->
        expect(err, 'error').to.not.exist
        expect(stdout, 'standard output').to.have.length.above 0
        expect(stderr, 'error output').to.equal ''
        expect(code, 'exit code').to.equal 0
        done()

    it "should work with events", (done) ->
      proc = new Spawn
        cmd: 'date'
      proc.run()
      stdout = ''
      proc.on 'stdout', (data) ->
        stdout += data
      proc.on 'done', ->
        expect(stdout, 'standard output').to.have.length.above 0
        expect(stdout, 'standard output').to.equal proc.stdout
        expect(proc.stderr, 'error output').to.equal ''
        expect(proc.code, 'exit code').to.equal 0
        done()

