local skynet = require "skynet"

skynet.start(function ()
    skynet.send("recv", "lua", 111)
    skynet.sleep(100)
    skynet.send("recv", "lua", 222)
end)