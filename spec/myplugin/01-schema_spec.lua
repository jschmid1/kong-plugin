local PLUGIN_NAME = "myplugin"


-- helper function to validate data against a schema
local validate do
  local validate_entity = require("spec.helpers").validate_plugin_config_schema
  local plugin_schema = require("kong.plugins."..PLUGIN_NAME..".schema")

  function validate(data)
    return validate_entity(data, plugin_schema)
  end
end


describe(PLUGIN_NAME .. ": (schema)", function()


  it("accepts valid headers", function()
    local ok, err = validate({
      filter_rules = {
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
    })
    assert.is_nil(err)
    assert.is_truthy(ok)
  end)


  it("does not accept invalid header formats", function()
    local ok, err = validate({
      filter_rules = {
        {
          upstream          = "italy_cluster",
          header_match      = {"foo==", "foo,bar"},
        }
      }
    })
    assert.is_falsy(ok)
    assert.is_truthy(err)
  end)


end)
