local every  = ngx.timer.every
local insert = table.insert
local ipairs = ipairs
local pack   = table.pack
local pcall  = pcall
local unpack = table.unpack


local Achilles = {}


local buckets = {}
local running = {}


local function do_timer(time, buckets)
  ngx.log(ngx.DEBUG, "adding timer for ", time)

  if running[time] then
    ngx.log(ngx.DEBUG, time, " already running")
    return true
  end

  running[time] = true

  local _, err = every(time, function()
    for _, entry in ipairs(buckets[time]) do
      local pok, perr = pcall(entry.f, unpack(entry.p))
      if not pok then
        ngx.log(ngx.WARN, "error in achilles callback: ", perr)
      end
    end
  end)
  if err then
    return false, err
  end

  return true
end


function Achilles.every(time, f, ...)
  if type(time) ~= "number" or time <= 0 then
    return false, "time must be a number greater than 0"
  end

  if type(f) ~= "function" then
    return false, "function param must be a function type value"
  end

  if not buckets[time] then
    buckets[time] = {}
  end

  insert(buckets[time], { f = f, p = pack(...) })

  return do_timer(time, buckets)
end


return Achilles
