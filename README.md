achilles
========

[![Build Status](https://travis-ci.org/p0pr0ck5/achilles.svg?branch=master)](https://travis-ci.org/p0pr0ck5/achilles)

OpenResty timer manager

# Table of Contents

* [Status](#status)
* [Overview](#overview)
* [Dependencies](#dependencies)
* [Synopsis](#synopsis)
* [Usage](#usage)
  * [every](#every)
* [License](#license)

# Status

This module is still in early development.

# Overview

This module seeks to provide a more robust and efficient mechanism for manager
OpenResty timers. At present, it provides a mechanism to run multiple recurring
timers of the same period, thereby reducing the number of pending timers and
avoiding taking too many resources when needing to run a large number of background
tasks.

# Synopsis

```lua
local achilles = require "achilles"

achilles.every(1, function() ngx.log(ngx.DEBUG, "first function" end))
achilles.every(1, function(n) ngx.log(ngx.DEBUG, "second function, passed ", n) end, true)

ngx.timer.pending_count() -- 1
```

# Usage

## every

`syntax: ok, err = ngx.timer.every(delay, callback, user_arg1, user_arg2, ...)`

Similar to the [ngx.timer.every](https://github.com/openresty/lua-nginx-module#ngxtimerevery)
API, except that it returns a boolean first param indicating success, rather than
the timer handle.

This function groups callbacks with matching `delay` values into the same recurring
`ngx.timer.every` call. Callbacks are executed in the order they are defined via
calls to this function.

# License

Copyright 2019 Robert Paprocki.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
