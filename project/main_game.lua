local skynet = require "skynet"
local sprotoloader = require "sprotoloader"
local cjson = require "cjson"

local max_client = 64

skynet.start(function()
	skynet.error("Server start")
	skynet.uniqueservice("protoloader")
	if not skynet.getenv "daemon" then
		local console = skynet.newservice("console")
	end
	skynet.newservice("debug_console",8000)
	skynet.newservice("loginservice", "loginservice", 1)
	skynet.newservice("gameservice", "gameservice", 1)

	local watchdog = skynet.newservice("watchdog")
	skynet.call(watchdog, "lua", "start", {
		port = 8001,
		maxclient = max_client,
		nodelay = true,
	})
	skynet.error("Watchdog listen on", 8001)

	local d = cjson.encode({
		cmd=1
	})

	skynet.error("d:", d)

	d = cjson.decode(d)
	skynet.error("d:", d)
	
	skynet.exit()
end)
