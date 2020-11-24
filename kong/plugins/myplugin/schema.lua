local typedefs = require "kong.db.schema.typedefs"
local validate_header_name = require("kong.tools.utils").validate_header_name

-- Grab pluginname from module name
local plugin_name = ({...})[1]:match("^kong%.plugins%.([^%.]+)")


local function validate_headers(pair, validate_value)
  local name, value = pair:match("^([^:]+):*(.-)$")
  if validate_header_name(name) == nil then
    return nil, string.format("'%s' is not a valid header", tostring(name))
  end

  if validate_value then
    if validate_header_name(value) == nil then
      return nil, string.format("'%s' is not a valid header", tostring(value))
    end
  end
  return true
end


local function validate_colon_headers(pair)
  return validate_headers(pair, true)
end

-- For testing, remove with release
local DEFAULT_FILTER_RULES = {
  {
    upstream          = "italy_cluster",
    header_match      = {"X-Region:Abruzzo", "X-City:Pescara"},
  },
  {
    upstream          = "europe_cluster",
    header_match      = {},
    default_target    = true
  },
}


return {
  name = plugin_name,
  fields = {
    { consumer = typedefs.no_consumer },  -- this plugin cannot be configured on a consumer (typical for auth plugins)
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        default = { filter_rules = DEFAULT_FILTER_RULES },
        fields = {
          { filter_rules = {
              type     = "array",
              required = true,
              default  = DEFAULT_FILTER_RULES,
              elements = {
                type = "record",
                fields = {
                -- TODO: add entitiy check that there is only one default_target
                --       but at least one
                { default_target = { type = "boolean", default = false }, },
                { upstream = { type = "string", required = true }, },
                -- Allows to set headers and header values that will cause a request to proxied to this upstream
                -- only proxies if _ALL_ headers/value pairs are present
                { header_match = { type = "array", elements = { type = "string", 
                                                                match = "^.*[^:]$", 
                                                                custom_validator = validate_colon_headers,
                                                              }, },
                },
                -- TODO: add entitiy checks to prevent equal header_match for two different upstreams.

                -- entity_checks = {
                --   { only_one_of = { "config.filter_rules.default_target" }, },
                --   { at_least_one_of = { "config.filter_rules.default_target"}, },
                -- },
                -- Probably better with a custom validator
 }, }, }, }, }, }, },
}}