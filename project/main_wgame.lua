local skynet = require "skynet"
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


	local wsocket = skynet.newservice("gamewebsocket")
	skynet.call(wsocket, "lua", "start", {
		port = 8001,
		maxclient = max_client,
		nodelay = true,
	})
	
	skynet.exit()
end)
