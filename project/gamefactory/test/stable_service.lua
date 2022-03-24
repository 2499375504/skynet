local skynet = require "skynet"
require "skynet.manager"
local sraw = require "stable.raw"
sraw.init()

local playerlist
skynet.start(function ()
    skynet.dispatch("lua", function (_, _, data)
        playerlist = data.playerList

        skynet.error("data:", data.playerList)
        local node1 = sraw.get(playerlist, "1")
        -- local node2 = sraw.get(sraw, 2)

        skynet.error("node1:",node1)
        -- skynet.error("node2:"..node2.id)
    end)
end)