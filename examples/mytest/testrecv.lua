local skynet = require "skynet"
require "skynet.manager"

skynet.start(function ()
    skynet.error("start:", coroutine.running())
    skynet.dispatch("lua", function ()
        
        skynet.error("1111111111:", coroutine.running())
        skynet.sleep(1000)
        --while true do end
        skynet.error("2222222222")
    end)

    skynet.name("recv", skynet.self())
end)