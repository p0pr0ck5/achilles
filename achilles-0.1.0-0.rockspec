package = "achilles"
version = "0.1.0-0"
source = {
  url = "git://github.com/p0pr0ck5/achilles",
  tag = "0.1.0"
}
description = {
  summary  = "OpenResty timer manager",
  homepage = "https://github.com/p0pr0ck5/achilles",
  license  = "Apache 2.0"
}
build = {
  type    = "builtin",
  modules = {
    ["achilles"] = "lib/achilles.lua",
  }
}
