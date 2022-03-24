local tablelogic = class("tablelogic")
local skynet = require "skynet"
local STATUS = require "gamestatus"
local FMSG = require "factorymessage"
-- 基类的玩家节点
local usernode = require "playernode"
    
function tablelogic:ctor()
    skynet.error("tablelogic.ctor")
    -- 前面需要声明不然继承失败
    self.tableAgent = nil
    self.tableCfg = nil
    self.playerNode = {}
    self.isLocked = false
    self.tablestatus = STATUS.TABLE_STATUS.WAIT_START
    self.timer = false
    self:StartTimer()
end

function tablelogic:initCfg(agent, cfg)
    skynet.error("tablelogic initLogic:", self)
    self.tableAgent = agent
    self.tableCfg = cfg
    for i = 1, self.tableCfg.playernum, 1 do
        self.playerNode[i] = usernode.new()
    end
end

-- 发送消息包
function tablelogic:sendData(playernode, cmd, pack)
    if playernode:valid() then
        local agentAddr = playernode.playernode.agentAddr
        self.tableAgent.send(agentAddr, "send_data", playernode.playernode.client_fd, cmd, pack)
    end
end

function tablelogic:sendAllDataExcept(chairid, cmd, pack)
    for k, v in ipairs(self.playerNode) do
        if chairid ~= k - 1 then
            self:sendData(v, cmd, pack)
        end
    end
end

function tablelogic:sendAllData(cmd, pack)
    for _, v in ipairs(self.playerNode) do
        self:sendData(v, cmd, pack)
    end
end

function tablelogic:getPlayerByChairId(chairid)
    return self.playerNode[chairid+1]
end

function tablelogic:getPlayerInfoByChairId(chairid)
    local playerNode = self:getPlayerByChairId(chairid)
    if playerNode:empty() then
        local player = clone(FMSG.PlayerInfo)
        player.userid = playerNode.playernode.userid
        player.nickname = playerNode.playernode.nickname
        player.coin = playerNode.playernode.coin
        player.sex = playerNode.playernode.sex
        player.chairid = playerNode.playernode.chairid
        player.gamestatus = playerNode.playernode.gamestatus
        player.disconnect = playerNode.playernode.disconnect
        return player
    end
    return nil
end

function tablelogic:getTableAllPlayerInfo()
    local players = {}
    for k, v in ipairs(self.playerNode) do
        if not v:empty() then
            local player = clone(FMSG.PlayerInfo)
            player.userid = v.playernode.userid
            player.nickname = v.playernode.nickname
            player.coin = v.playernode.coin
            player.sex = v.playernode.sex
            player.chairid = v.playernode.chairid
            player.gamestatus = v.playernode.gamestatus
            player.disconnect = v.playernode.disconnect
            table.insert(players, player)
        end
    end

    return players
end

-- 坐下
function tablelogic:HandleSitDownReq(playerstable)
    skynet.error("tablelogic.resp.HandleSitDownReq", self)
    -- 错误处理 基类逻辑层的锁住桌子
    if self.isLocked then
        return false
    end

    -- 游戏已经开始并且不能旁观了...
    if self.tablestatus == STATUS.TABLE_STATUS.WAIT_END then
        if not self.tableCfg.allowlookon then
            return false
        end
    end

    local node = nil
    for k, v in ipairs(self.playerNode) do
        if v:empty() then
            playerstable.chairid = k - 1
            playerstable.gamestatus = STATUS.GAME_STATUS.WAIT_READY
            v:addplayer(playerstable)
            node = v
            break
        end
    end

    if node then
        -- 发送桌子上的其他玩家给自己
        local msg = clone(FMSG.SitDownRes)
        msg.errorid = 0
        msg.tableid = self.tableCfg.id
        msg.chairid = playerstable.chairid
        msg.players = self:getTableAllPlayerInfo()

        self:sendData(node, FMSG.SITDOWN, msg)

        -- 告诉别的玩家有人加入成功
        msg = clone(FMSG.TablePlayerJoin)
        msg.player = clone(FMSG.PlayerInfo)
        msg.player.userid = playerstable.userid
        msg.player.nickname = playerstable.nickname
        msg.player.coin = playerstable.coin
        msg.player.sex = playerstable.sex
        msg.player.chairid = playerstable.chairid
        msg.player.gamestatus = playerstable.gamestatus
        msg.player.disconnect = 1

        self:sendAllDataExcept(playerstable.chairid, FMSG.JOIN, msg)
        
        -- 发送桌子上其他玩家信息
        self:CallBackSitDownSuccess(node)
        return true
    end

    return false
end

-- 准备
function tablelogic:HandleReadyReq(playerstable)
    skynet.error("tablelogic.HandleReadyReq:", self, playerstable.gamestatus)

    if playerstable.gamestatus ~= STATUS.GAME_STATUS.WAIT_READY then
        return
    end
    playerstable.gamestatus = STATUS.GAME_STATUS.WAIT_START

    -- 发送准备成功给所有人
    local msg = FMSG.ReadRes
    msg.errorid = 0
    msg.userid = playerstable.userid
    msg.chairid = playerstable.chairid
    msg.tableid = self.tableCfg.id

    self:sendAllData(FMSG.READY, msg)

    self:CallBackReadySuccess(self:getPlayerByChairId(playerstable.chairid))
end

-- 重入
function tablelogic:onReconnect(playerstable)
    skynet.error("tablelogic:onReconnect:", playerstable)

    if playerstable.chairid >= 0 then
        skynet.error("tablelogic:onReconnect2:", playerstable.chairid)
    else
        skynet.error("tablelogic:onReconnect3:", playerstable)
    end

    local playernode = self:getPlayerByChairId(playerstable.chairid)
    -- 通知自己信息和桌子上的其他玩家信息
    local msg = clone(FMSG.AgainLoginRes)
    msg.userid = playerstable.userid
    msg.servertime = 0
    msg.tableid = self.tableCfg.id
    msg.chairid = playerstable.chairid
    -- 上面的玩家信息
    msg.players = self:getTableAllPlayerInfo()
    self:sendData(playernode, FMSG.AGAINLOGIN, msg)

    -- 通知桌子上别的玩家有人断线回来
    msg = clone(FMSG.AgainReconnect)
    msg.userid = playerstable.userid
    self:sendAllDataExcept(playerstable.chairid, FMSG.AGAINLOGIN_OTHER, msg)
    self:CallBackReconnect(playernode)
end

function tablelogic:Disconnect(playerstable)
    skynet.error("tablelogic:Disconnect", playerstable)
    self:CallBackDisconnect(self:getPlayerByChairId(playerstable.chairid))
    -- 游戏中掉线
    if playerstable.gamestatus == STATUS.GAME_STATUS.WAIT_END then
        -- 发送玩家掉线消息
        local msg = clone(FMSG.TablePlayerDisconnect)
        msg.userid = playerstable.userid
        self:sendAllData(FMSG.DISCONNECT, msg)
    else
        -- 非游戏中掉线 离开
        self:PlayerLeave(self:getPlayerByChairId(playerstable.chairid))
    end
end

function tablelogic:PlayerLeave(playernode)
    -- 检测是否有没有计费的和日志写入
    skynet.error("tablelogic:PlayerLeave:", playernode.playernode.userid)
    self:CallBackPlayerLeave(playernode)
    local msg = clone(FMSG.TablePlayerLeave)
    msg.userid = playernode.playernode.userid
    self:sendAllData(FMSG.LEAVE, msg)

    self.tableAgent.send(".gameservice", "removePlayer", playernode.playernode)
    -- 通知
    self.tableAgent.send(".gameservice", "subplayer", self.tableCfg.id)
    playernode:clear()

end

-- 锁住桌子
function tablelogic:LockTable(bool)
    self.isLocked = bool
    self.tableAgent.send(".gameservice", "tableBusy", self.tableCfg.id, bool)
end

-- 基类调用
function tablelogic:GameStart()
    self.tablestatus = STATUS.TABLE_STATUS.WAIT_END
    for _, v in ipairs(self.playerNode) do
        if not v:empty() then
            if v.playernode.gamestatus == STATUS.GAME_STATUS.WAIT_START then
                v.playernode.gamestatus = STATUS.GAME_STATUS.WAIT_END
            end
        end
    end
end

function tablelogic:GameEnd()
    self.tablestatus = STATUS.TABLE_STATUS.WAIT_START
    skynet.error("tablelogic:GameEnd")
    -- TODO 计费 日志

    -- 状态改变
    -- 清除掉线玩家
    for _, v in ipairs(self.playerNode) do
        if not v:empty() then
            v.playernode.gamestatus = STATUS.GAME_STATUS.WAIT_READY
            if v:isDisconnect() then
                self:PlayerLeave(v)
            end
        end
    end
end

function tablelogic:StartTimer()
    if self.timer == false then
        self.timer = true
        skynet.fork(function ()
            while true do
                skynet.sleep(100)
                self:onTimer()
            end
        end)
    end
end

function tablelogic:StopTimer()
    self.timer = false
end

------------------------------------------------------------------------------------
function tablelogic:onTimer()
    
end

function tablelogic:CallBackSitDownSuccess(playernode)
    skynet.error("tablelogic.CallBackSitDownSuccess:", self, playernode.playernode.gamestatus)
end

function tablelogic:CallBackReadySuccess(playernode)
    skynet.error("tablelogic.CallBackReadySuccess:", self, playernode.playernode.gamestatus)
end

function tablelogic:CallBackDisconnect(playernode)
    skynet.error("tablelogic.CallBackDisconnect:", self, playernode.playernode.gamestatus)
end

function tablelogic:CallBackReconnect(playernode)
    skynet.error("tablelogic.CallBackReconnect:", self, playernode.playernode.gamestatus)
end

function tablelogic:CallBackPlayerLeave(playernode)
    skynet.error("tablelogic.CallBackDisconnect:", self, playernode.playernode.gamestatus)
end

return tablelogic
