-- 认证成功后的管理类
local skynet = require "skynet"
require "skynet.manager"
require "functions"

local STATUS = require "gamestatus"
local FMSG = require "factorymessage"
local playerstableMgr = require "playerstableMgr"
local gameservice = require "service"
local tableinfo = require "tableinfo"
local tableList = {}

-- 玩家登陆成功
function gameservice.resp.LoginSuccess(addr, userinfo)
    local playernode = playerstableMgr:getPlayerByUserId(userinfo.userid)
    if playernode then
        return gameservice.onReconnect(playernode, userinfo)
    else
        return gameservice.onEnter(userinfo)
    end
end

-- 玩家坐下
function gameservice.resp.HandleSitDownReq(addr, playernode)
    print("gameservice.resp.HandleSitDownReq")
    local find = false
    -- 查找合适的桌子
    for k, v in pairs(tableList) do
        if not v:isfull() then
            v:addplayer()
            local bool = gameservice.call(v.tableservice, "HandleSitDownReq", playernode)
            if not bool then
                v:subplayer()
            else
                playernode.tableAddr = v.tableservice
                find = true
                break
            end
        end
    end

    if not find then
        -- 生成id
        -- 先简单生成
        local id = #tableList + 1
        local cfg = {
            -- 桌子号 房卡房的话就是房间号
            id = id,
            playernum = 4,
            -- 是否允许旁观
            allowlookon = false,
            -- 房间规则 
            rules = {}
        }
        local t = gameservice.createTable(cfg)
        tableList[id] = t
        t:addplayer()
        local bool = gameservice.call(t.tableservice, "HandleSitDownReq", playernode)
        if not bool then
            t:subplayer()
        else
            playernode.tableAddr = t.tableservice
            find = true
        end
    end

    -- 错误
    if not find then
        gameservice.closeSocket(addr, playernode.client_fd)
    end
end

-- 关闭
function gameservice.closeSocket(agentAddr, client_fd)
    if agentAddr > 0 then
        gameservice.send(agentAddr, "closeSocket", client_fd)
    else
        skynet.trace("gameservice.closeSocket agentAddr err")
    end
    
end

-- 玩家断线
function gameservice.resp.disconnect(addr, playernode)
    print("disconnect:", addr, playernode.agentAddr, playernode.userid)
    -- 如果已经被替换成新的agent了 不需要释放了
    if addr ~= playernode.agentAddr then
        return
    end
    
    -- 如果玩家在桌子上了
    if playernode.tableAddr > 0 then
        -- agent
        playernode.agentAddr = 0
        -- 发送给对应的id处理
        gameservice.send(playernode.tableAddr, "Disconnect", playernode)
    else
        gameservice.removePlayer(playernode)
    end
end

-- 移除连接
function gameservice.resp.removePlayer(addr, playernode)
    gameservice.removePlayer(playernode)
end

-- 桌子不让进了
function gameservice.resp.tableBusy(addr, id, busy)
    print("gameservice.resp.tableBusy:", id, busy)
    if tableList[id] then
        tableList[id].busy = busy
        print("gameservice.resp.tableBusy:", id, busy)
    else
        -- TODO 错误提示
    end
end

function gameservice.resp.subplayer(addr, id)
    print("gameservice.resp.subplayer1:", id)
    if tableList[id] then
        tableList[id]:subplayer()
        print("gameservice.resp.subplayer2:", id)
    else
        -- TODO 错误提示
    end
end

-- 发送消息包
function gameservice.sendData(playernode, cmd, pack)
    if playernode.agentAddr > 0 then
        local agentAddr = playernode.agentAddr
        print("gameservice.sendData:", agentAddr, playernode.client_fd, cmd, pack)
        gameservice.send(agentAddr, "send_data", playernode.client_fd, cmd, pack)
    end
end

-- 玩家节点加入
function gameservice.onEnter(userinfo)
    local playerstable = playerstableMgr:getFreePlayer()
    playerstableMgr:addPlayer(playerstable, userinfo)
    print("gameservice.onEnter:", userinfo.userid, playerstable.userid)
    playerstable.gamestatus = STATUS.GAME_STATUS.WAIT_DESK
    -- 发送登陆成功提示
    local msg = clone(FMSG.LoginRes)
    msg.errorid = 0
    msg.player.userid = playerstable.userid
    msg.player.nickname = playerstable.nickname
    msg.player.coin = playerstable.coin
    msg.player.sex = playerstable.sex
    msg.player.chairid = playerstable.chairid
    msg.player.gamestatus = playerstable.gamestatus
    msg.player.disconnect = playerstable.disconnect
    gameservice.sendData(playerstable, FMSG.LOGIN, msg)

    return playerstable
end

-- 玩家节点节点删除
function gameservice.removePlayer(playernode)
    local playerstable = playerstableMgr:getPlayerByUserId(playernode.userid)
    skynet.error("removePlayer:", playernode.userid, playerstable.agentAddr, playernode.agentAddr)
    if playerstable and playerstable.agentAddr == playernode.agentAddr then
        playerstableMgr:removePlayerById(playernode.userid)
    end
end

-- 断线重入
function gameservice.onReconnect(playernode, userinfo)
    print("onReconnect agentAddr:", playernode.agentAddr)
    local agentAddr = playernode.agentAddr
    local client_fd = playernode.client_fd
    playernode.agentAddr = userinfo.agentAddr
    playernode.client_fd = userinfo.client_fd
    -- 关闭老节点
    if agentAddr > 0 then
        gameservice.closeSocket(agentAddr, client_fd)
    end
    
    -- 不在游戏桌子上 直接清除掉老节点
    if playernode.tableAddr <= 0 then
        gameservice.onEnter(userinfo)
    else
        print("onReconnect tableAddr:", playernode.tableAddr)
        gameservice.send(playernode.tableAddr, "onReconnect", playernode)
    end

    return playernode
end

-- 创建桌子
function gameservice.createTable(cfg)
    local t = clone(tableinfo)
    t:init(cfg)
    print("createTable:", t.cfg)
    t.tableservice = skynet.newservice("tableservice", "tableservice", 1)
    gameservice.send(t.tableservice, "init", t.cfg)
    return t
end

gameservice.init = function ()
    skynet.register ".gameservice"
end

gameservice.start(...)