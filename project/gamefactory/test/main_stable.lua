local skynet = require "skynet"
local playernode = require "playernode"
local sraw = require "stable.raw"
sraw.init()

skynet.start(function()
    local playerlist = {}
    sraw.settable(playerlist, "node", playernode.new())
    -- playerlist.node = playernode
    skynet.error("playernode:", sraw.get(playerlist, "node"))
    sraw.decref(playerlist.node)
    -- skynet.error("playernode:", sraw.getref(playerlist.node.id))

    skynet.fork(function ()
        skynet.sleep(100)
        skynet.error("playernode:", playerlist.node)
    end)
    
    -- local id = "1"
    -- playernode:initialize(id)
    -- sraw.set(playerlist, tostring(id), playernode)
    -- skynet.error("playernode:",playernode)

    -- local node1 = sraw.get(playerlist, "1")
    -- -- local node2 = sraw.get(sraw, 2)
    -- skynet.error("node1:",node1)
    -- skynet.error("node3:",playerlist["3"])

    local ser = skynet.newservice("stable_service")

    -- skynet.send(ser, "lua", {playerList=playerlist})


end)