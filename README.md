Package: alinex-spawn
=================================================

[![Build Status] (https://travis-ci.org/alinex/node-spawn.svg?branch=master)](https://travis-ci.org/alinex/node-spawn)
[![Coverage Status] (https://coveralls.io/repos/alinex/node-spawn/badge.png?branch=master)](https://coveralls.io/r/alinex/node-spawn?branch=master)
[![Dependency Status] (https://gemnasium.com/alinex/node-spawn.png)](https://gemnasium.com/alinex/node-spawn)

This is an object oriented implementation around the core `process.spawn`
command. It's benefits are:

- automatic error control
- automatic retry in case of error
- automatic delaying in case of high server load
- completely adjustable
- use priorities (also on OS level)

It is one of the modules of the [Alinex Universe](http://alinex.github.io/node-alinex)
following the code standards defined there.


Install
-------------------------------------------------

The easiest way is to let npm add the module directly:

    > npm install alinex-spawn --save

[![NPM](https://nodei.co/npm/alinex-spawn.png?downloads=true&stars=true)](https://nodei.co/npm/alinex-spawn/)


Usage
-------------------------------------------------
You may connect to the process using a callback method on the `run()` call or
use the events.

First you have to load the class package.

    Spawn = require('alinex-spawn');

Now you may setup an external process like:

    proc = new Spawn {
      cmd: 'date'
    };

You may also change the configuration afterwards like:

    proc.config.cmd = 'date';

Now you have multiple ways to work and control your process.

### Run with Callback

To run this simple process call the run-method:

    proc.run(function(err, stdout, stderr, code) {
      // work with the results
    });

After the process has completed its task the callback will be called with the
most used data. But you may access all details through the `proc` object.

### Run using Events

With events you can monitor what's going on while the process works.

    proc.run();

    stdout = '';
    proc.on('stdout', function(data) {
      return stdout += data;
    });

    proc.on('done', function() {
      // analyse the results
    });

### Check for Success

You may give a check method in the configuration which will be used to check
whether the process succeeded and return an Error or undefined:

    proc.config.check = function(proc) {
      if (!((proc.code != null) && proc.code === 0)) {
        return new Error("Got exit code of " + proc.code + ".");
      }
    };

The above given check function is the default if nothing set.

This check will automatically be called on normal process close. If you want to
know if it got an error you can use the event or callback value or check for:

    if (proc.error != null) {
      // something went wrong
    }


API
-------------------------------------------------

### Global setup

- `LOAD` (integer) - specifies

### Instantiate

    new Spawn(config);

This will create a new process to be run later. You may define it directly on
instantiation or through it's `config` property afterwards.
A spawn instance may also be reused to run again or run with some modification
again.

See the `config` property below for what to be configured here.

### Methods

- `run(cb)` - to start a preconfigured process

### Properties

- `config` - setup for the process
  - cmd (string) - the command to run
  - args (array) - all arguments to be given to the command
  - cwd (string) - current working directory
  - env (object) - environment key-value pairs
  - uid (integer) - user identity of the process
  - gid (integer) - group identity of the process
  - check (function) - to check whether process succeeded
  - priority (float) - between 0..1

Data from the last run:

- `pid` - process pid which has been given
- `start` - date when the process started
- `end` - date when the process finished
- `code` - return code of the process
- `stdout` - output of the process
- `stderr` - error output of the process
- `error` - Error object if one occurred

### Events

- `error` (object) - if an error occurred
- `stdout` (string) - if a line is outputted
- `stderr` (string) - if a error line is outputted
- `done` (integer) - if the process finished giving exit code


License
-------------------------------------------------

Copyright 2014 Alexander Schilling

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

>  <http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
