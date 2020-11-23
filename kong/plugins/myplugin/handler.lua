local plugin = {
  PRIORITY = 1000, -- set the plugin priority, which determines plugin execution order
  VERSION = "0.1",
}


function requestHeaderContains(set, key)
  kong.log.notice("Checking if request headers contain: ", key)
  -- Headers are in format HeaderName:HeaderValue
  -- This splits it in order to compare it with the request header table
  -- Which is in table format ['key'] = Value
  local header_name, header_value = key:match("([^,]+):([^,]+)")

  for request_header, request_header_value in pairs(set) do
    kong.log.notice("Checking request_header and request header value -> ", request_header, " ", request_header_value)
    -- header_names are being represented as lowercase.
    if request_header == header_name:lower() then
      kong.log.notice("Found matching headers names")
      -- check if request_header equals the matcher header
      if request_header_value == header_value then
        kong.log.notice("Found matching headers values")
        return true
      end
    end
  end
  return false
end

function proxy_request_to(upstream)
  -- function to abstract error handling and logging for `set_upstream`
  local ok, err = kong.service.set_upstream(upstream)
  if not ok then
    kong.log.err(err)
    return
  end
  kong.log.notice("Proxying request to upstream: ", upstream)
  return
end

function find_default_target(conf)
  -- Function to find the default target(upstream)
  -- in the plugin's config. The config validates
  -- that at least one default_target exists
  -- so we can safely assume that we find one.
  kong.log.notice("Finding default target")
  for _, data in ipairs(conf.filter_rules) do
    if data.default_target == true then
      kong.log.notice("Found default target -> ", data.upstream)
      return data.upstream
    end
  end
end

-- runs in the 'access_by_lua_block'
function plugin:access(plugin_conf)

  local default_target = find_default_target(plugin_conf)

  -- get all headers from current request
  local headers = kong.request.get_headers()

  for _, data in ipairs(plugin_conf.filter_rules) do
    kong.log.notice("Checking filter_rules for upstream -> ", data.upstream)
    -- iterating through header_match table
    for _, filter_header in pairs(data.header_match) do
      if not requestHeaderContains(headers, filter_header) then
        -- if any of the headers that are required isn't in the request headers
        -- proxy to default upstream
        kong.log.notice('Could not find header -> ', filter_header, " in request headers. Proxying to default upstream")
        return proxy_request_to(default_target)
      end
    end
      -- if all items that are in _header_match_ are also in `headers`
      -- set the upstream of data.upstream
    return proxy_request_to(data.upstream)
    end
end 


-- return our plugin object
return plugin
