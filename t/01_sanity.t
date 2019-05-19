use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

plan tests => 3 * blocks();

my $pwd = cwd();

our $HttpConfig = <<"_EOC_";
    lua_package_path "$pwd/lib/?.lua;/usr/local/share/lua/5.1/?.lua;;";
_EOC_

no_shuffle();
run_tests();

__DATA__

=== TEST 1: valid call
--- http_config eval: $::HttpConfig
--- config
location /t {
  content_by_lua_block {
    local achilles = require "achilles"

    local ok, err = achilles.every(1, function() return true end)

    ngx.say(ok)
    ngx.say(err)
  }
}
--- request
GET /t
--- error_code: 200
--- response_body
true
nil
--- no_error_log
[error]


=== TEST 2: bad time param 1/2
--- http_config eval: $::HttpConfig
--- config
location /t {
  content_by_lua_block {
    local achilles = require "achilles"

    local ok, err = achilles.every(0, function() return true end)

    ngx.say(ok)
    ngx.say(err)
  }
}
--- request
GET /t
--- error_code: 200
--- response_body
false
time must be a number greater than 0
--- no_error_log
[error]


=== TEST 3: bad time param 3/2
--- http_config eval: $::HttpConfig
--- config
location /t {
  content_by_lua_block {
    local achilles = require "achilles"

    local ok, err = achilles.every(nil, function() return true end)

    ngx.say(ok)
    ngx.say(err)
  }
}
--- request
GET /t
--- error_code: 200
--- response_body
false
time must be a number greater than 0
--- no_error_log
[error]


=== TEST 4: bad function param
--- http_config eval: $::HttpConfig
--- config
location /t {
  content_by_lua_block {
    local achilles = require "achilles"

    local ok, err = achilles.every(1, nil)

    ngx.say(ok)
    ngx.say(err)
  }
}
--- request
GET /t
--- error_code: 200
--- response_body
false
function param must be a function type value
--- no_error_log
[error]


