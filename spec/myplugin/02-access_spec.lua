local helpers = require "spec.helpers"


local PLUGIN_NAME = "myplugin"


for _, strategy in helpers.each_strategy() do
  describe(PLUGIN_NAME .. ": (access) [#" .. strategy .. "]", function()
    local client

    lazy_setup(function()

      local bp = helpers.get_db_utils(strategy, nil, { PLUGIN_NAME })

      -- Inject a test route. No need to create a service, there is a default
      -- service which will echo the request.
      local route1 = bp.routes:insert({
        hosts = { "test1.com" },
      })
      -- add the plugin to test to the route we created
      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route1.id },
        config = {
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
        },
      }

      -- start kong
      assert(helpers.start_kong({
        -- set the strategy
        database   = strategy,
        -- use the custom test template to create a local mock server
        nginx_conf = "spec/fixtures/custom_nginx.template",
        -- make sure our plugin gets loaded
        plugins = "bundled," .. PLUGIN_NAME,
      }))
    end)

    lazy_teardown(function()
      helpers.stop_kong(nil, true)
    end)

    before_each(function()
      client = helpers.proxy_client()
    end)

    after_each(function()
      if client then client:close() end
    end)

    describe("request", function()
      it("verify if request got routed via the expected upstream", function()
        local r = client:get("/request", {
          headers = {
            ["Host"] = 'test1.com',
            ["X-Region"] = "Abruzzo",
            ["X-City"] = "Pescara",
          }
        })
        -- validate that the request succeeded, response status 200
        assert.response(r).has.status(200)

        -- TODO:
        -- How to properly test if upstreams were hit?
        -- 1. Setup upstreams with mock targets
        -- 2. Verify if target got a request based on the headers?
      end)
    end)

  end)
end
