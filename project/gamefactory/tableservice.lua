local skynet = require "skynet"
local s = require "service"

-- 桌子信息
local tableframe = require("tableframe").new()
-- 桌子上的玩家
s.resp.init = function (addr, cfg)
    tableframe:initCfg(s, cfg)
end

s.resp.disconnect = function (addr, playerstable)
    print("tableservice disconnect")
end

s.resp.HandleSitDownReq = function (addr, playerstable)
    print("s.resp.HandleSitDownReq")
    return tableframe:HandleSitDownReq(playerstable)
end

s.resp.HandleReadyReq = function (addr, playerstable)
    print("s.resp.HandleReadyReq")
    tableframe:HandleReadyReq(playerstable)
end

s.resp.onReconnect = function (addr, playerstable)
    print("s.resp.onReconnect")
    tableframe:onReconnect(playerstable)
end

s.resp.Disconnect = function (addr, playerstable)
    print("Disconnect:", playerstable)
    tableframe:Disconnect(playerstable)
end

s.resp.Message = function (addr, cmd, data)
    print("s.resp.Message:", cmd, data)
end

s.start(...)
