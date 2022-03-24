require "functions"
local playernode = class("playernode", require("factotoryPlayerNode"))

function playernode:ctor()
    self.super.ctor(self)
    print("playernode:ctor")
end

-- 坐下的时候会调用
function playernode:Initialize()
    print("playernode:Initialize")
end

-- 离开的时候会调用
function playernode:Reset()
    print("playernode:Reset")
end

return playernode