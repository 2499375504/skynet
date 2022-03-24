local factotoryPlayerNode = class("factotoryPlayerNode")

local playerstable = require "playerstable"
-- 玩家节点数据 c++ stable数据
factotoryPlayerNode.playernode = nil

function factotoryPlayerNode:ctor()
    print("factotoryPlayerNode:ctor")
end

-- 坐下的时候会调用
function factotoryPlayerNode:Initialize()
    
end

-- 离开的时候会调用
function factotoryPlayerNode:Reset()
    
end

function factotoryPlayerNode:addplayer(playernode)
    self.playernode = playernode
    self:Initialize()
end

function factotoryPlayerNode:empty()
    return self.playernode == nil
end

function factotoryPlayerNode:isDisconnect()
    if not self:empty() and self.playernode.agentAddr == 0 then
        return true
    end

    return false
end

function factotoryPlayerNode:valid()
    return self.playernode ~= nil and self.playernode.agentAddr ~= 0
end

function factotoryPlayerNode:clear()
    if self.playernode then
        self:Reset()
        self.playernode = nil
    end
end

return factotoryPlayerNode