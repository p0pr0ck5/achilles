std             = "ngx_lua"
redefined       = false
max_line_length = 80

files["lib/achilles.lua"] = {
  read_globals = {
    "table.pack",
    "table.unpack",
  }
}
