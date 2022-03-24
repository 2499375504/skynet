local playerstableMgr = {}

local playerstable = require("playerstable")

playerstableMgr.playerlist = {}
playerstableMgr.playerFreelist = {}

-- 添加一个用户
function playerstableMgr:getFreePlayer()
    local playernode = nil
    if #self.playerFreelist > 0 then
        playernode = self.playerFreelist[#self.playerFreelist]
        table.remove(self.playerFreelist)
    else
        playernode = playerstable.create()
    end
    
    return playernode
end

-- 添加一个用户
function playerstableMgr:addPlayer(playernode, userinfo)
    playerstable.Initialize(playernode)
    playerstable.SetUserInfo(playernode,userinfo);
    self.playerlist[playernode.userid] = playernode
    print("addPlayer:", playernode.userid)
end

-- 减少一个
function playerstableMgr:removePlayer(playernode)
    playerstable.Reset(playernode)
    self.playerlist[playernode.userid] = nil
    self.playerFreelist[#self.playerFreelist+1] = playernode
end

function playerstableMgr:removePlayerById(userid)
    local playernode = self.playerlist[userid]
    self:removePlayer(playernode)
end

-- 得到一个用户
function playerstableMgr:getPlayerByUserId(userid)
    for index, value in pairs(self.playerlist) do
        print("getPlayerByUserId:", index)
    end

    return self.playerlist[userid]
end

-- 是不是已经存在节点了
function playerstableMgr:isExistPlayer(userid)
    return self.playerlist[userid] ~= nil
end

return playerstableMgr
