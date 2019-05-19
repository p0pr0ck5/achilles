use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

plan tests => 3 * blocks() + 5;

my $pwd = cwd();

our $HttpConfig = <<"_EOC_";
    lua_package_path "$pwd/lib/?.lua;/usr/local/share/lua/5.1/?.lua;;";
_EOC_

our $MaxConfig = <<"_EOC_";
    lua_max_pending_timers 128;
_EOC_

no_shuffle();
run_tests();

__DATA__

=== TEST 1: every with a function-less param
--- http_config eval: $::HttpConfig
--- config
location /t {
  content_by_lua_block {
    local achilles = require "achilles"

    local x = 0

    local ok, err = achilles.every(0.001, function() x = x + 1 end)

    ngx.sleep(0.001)

    ngx.say(x)
  }
}
--- request
GET /t
--- error_code: 200
--- response_body
1
--- no_error_log
[error]


=== TEST 2: every with a function param
--- http_config eval: $::HttpConfig
--- config
location /t {
  content_by_lua_block {
    local achilles = require "achilles"

    local t = {}
    t.x = 0

    local ok, err = achilles.every(0.001, function(t) t.x = t.x + 1 end, t)

    ngx.sleep(0.002)

    ngx.say(t.x)
  }
}
--- request
GET /t
--- error_code: 200
--- response_body
1
--- no_error_log
[error]


=== TEST 3: every with two functions in a bucket
--- http_config eval: $::HttpConfig
--- config
location /t {
  content_by_lua_block {
    local achilles = require "achilles"

    local x = 0
    local y = 0

    local function f1()
      x = x + 1
    end
    local function f2()
      y = y + 1
    end

    achilles.every(0.001, f1)
    achilles.every(0.001, f2)

    ngx.sleep(0.001)

    ngx.say(x)
    ngx.say(y)
  }
}
--- request
GET /t
--- error_code: 200
--- response_body
1
1
--- no_error_log
[error]


=== TEST 4: every handles exceptions in functions
--- http_config eval: $::HttpConfig
--- config
location /t {
  content_by_lua_block {
    local achilles = require "achilles"

    local x = 0

    local function f1()
      error("nope!")
    end
    local function f2()
      x = x + 1
    end

    achilles.every(0.001, f1)
    achilles.every(0.001, f2)

    ngx.sleep(0.001)

    ngx.say(x)
  }
}
--- request
GET /t
--- error_code: 200
--- response_body
1
--- error_log
error in achilles callback
--- no_error_log
[error]


=== TEST 5: every handles more functions than lua_max_pending_timers
--- http_config eval: $::HttpConfig . $::MaxConfig
--- config
location /s {
  content_by_lua_block {
    local achilles = require "achilles"

    local failed = false

    for i = 1, 1024 do
      local ok, err = ngx.timer.at(0.001, function() return true end)
      if not ok and err == "too many pending timers" then
        failed = true
      end
    end

    ngx.say(failed)
  }
}
location /t {
  content_by_lua_block {
    ngx.sleep(0.5) -- flush from the previous request

    local achilles = require "achilles"

    local x = 0

    local function f1()
      ngx.log(ngx.DEBUG, x)
      x = x + 1
    end

    for i = 1, 1024 do
      local ok, err = achilles.every(0.001, f1)
    end

    ngx.sleep(0.001)

    ngx.say(x)
    ngx.say(ngx.timer.running_count())
    ngx.say(ngx.timer.pending_count())
  }
}
--- request eval
["GET /s", "GET /t"]
--- error_code eval
[200, 200]
--- response_body eval
["true\n", "1024\n0\n1\n"]
--- no_error_log
[error]


=== TEST 6: every with a function added to an existing bucket after execution
--- http_config eval: $::HttpConfig
--- config
location /t {
  content_by_lua_block {
    local achilles = require "achilles"

    local x = 0

    local function f1()
      x = x + 1
    end

    achilles.every(0.001, f1)

    ngx.sleep(0.001)

    ngx.say(x)

    achilles.every(0.001, f1)

    ngx.sleep(0.001)

    ngx.say(x)
  }
}
--- request
GET /t
--- error_code: 200
--- response_body
1
3
--- error_log
0.001 already running
--- no_error_log
[error]


=== TEST 7: every with a function added to a new bucket after execution
--- http_config eval: $::HttpConfig
--- config
location /t {
  content_by_lua_block {
    local achilles = require "achilles"

    local x = 0

    local function f1()
      x = x + 1
    end

    achilles.every(0.001, f1)

    ngx.sleep(0.001)

    ngx.say(x)

    achilles.every(0.002, f1)

    ngx.sleep(0.002)

    ngx.say(x)
  }
}
--- request
GET /t
--- error_code: 200
--- response_body
1
3
--- no_error_log
[error]


=== TEST 8: every calls the same function from multiple buckets
--- http_config eval: $::HttpConfig
--- config
location /t {
  content_by_lua_block {
    local achilles = require "achilles"

    local x = 0

    local function f1()
      x = x + 1
    end

    achilles.every(0.001, f1)
    achilles.every(0.002, f1)

    ngx.sleep(0.002)

    ngx.say(x)
    ngx.say(ngx.timer.pending_count())
  }
}
--- request
GET /t
--- error_code: 200
--- response_body
2
2
--- no_error_log
[error]


