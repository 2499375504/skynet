require "functions"
local skynet = require "skynet"

local playernode = class("playernode", require("factotoryPlayerNode"))

function playernode:ctor()
    self.super.ctor(self)
    skynet.error("playernode:ctor")
end

-- 坐下的时候会调用
function playernode:Initialize()
    skynet.error("playernode:Initialize")
end

-- 离开的时候会调用
function playernode:Reset()
    skynet.error("playernode:Reset")
end

return playernode