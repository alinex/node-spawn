Package: alinex-spawn
=================================================

[![Build Status] (https://travis-ci.org/alinex/node-spawn.svg?branch=master)](https://travis-ci.org/alinex/node-spawn)
[![Coverage Status] (https://coveralls.io/repos/alinex/node-spawn/badge.png?branch=master)](https://coveralls.io/r/alinex/node-spawn?branch=master)
[![Dependency Status] (https://gemnasium.com/alinex/node-spawn.png)](https://gemnasium.com/alinex/node-spawn)

This is an object oriented implementation around the core `process.spawn`
command. It's benefits are:

- automatic error control
- automatic retry in case of error
- automatic delying in case of high server load
- completely adjustable

It is one of the modules of the [Alinex Universe](http://alinex.github.io/node-alinex)
following the code standards defined there.


Install
-------------------------------------------------

The easiest way is to let npm add the module directly:

    > npm install alinex-spawn --save

[![NPM](https://nodei.co/npm/alinex-spawn.png?downloads=true&stars=true)](https://nodei.co/npm/alinex-spawn/)


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
