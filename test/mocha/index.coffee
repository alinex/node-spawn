chai = require 'chai'
expect = chai.expect
require('alinex-error').install()

describe "Spawn wrapper", ->

  Spawn = require '../../lib/index'

  describe "class", ->

    it "should be retrieved from factory", ->
      cmd = new Spawn 'date'
      expect(cmd, 'instance').to.exist

    it "should allow instantiation", ->

  describe "run", ->

