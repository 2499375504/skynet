local skynet = require "skynet"
local socket = require "skynet.socket"

local CMD = {}
function CMD.start(conf)
	local agent = {}
    for i= 1, 20 do
        agent[i] = skynet.newservice("wagent", "wagent", 1)
    end
    local balance = 1
    local protocol = "ws"
    local id = socket.listen("0.0.0.0", conf.port)
    skynet.error(string.format("Listen websocket port 0.0.0.0:%d protocol:%s", conf.port, protocol))
    socket.start(id, function(id, addr)
        skynet.error(string.format("accept client socket_id: %s addr:%s", id, addr))
        skynet.send(agent[balance], "lua", "socket", id, protocol, addr)
        balance = balance + 1
        if balance > #agent then
            balance = 1
        end
    end)
end

skynet.start(function ()
    skynet.dispatch("lua", function(session, source, cmd, ...)
        local f = assert(CMD[cmd])
        skynet.ret(skynet.pack(f(...)))
	end)
end)