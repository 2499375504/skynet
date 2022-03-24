local M = {}

local STATUS = require "gamestatus"

M.LOGIN = "login"
M.SITDOWN = "sitdown"
M.READY = "ready"
M.HANDSHAKE = "handshake"
M.JOIN = "join"
M.LEAVE = "leave"
M.DISCONNECT = "disconnect"
M.AGAINLOGIN = "AgainLogin"
M.AGAINLOGIN_OTHER = "AgainLoginOther"

M.PlayerInfo = {
    userid = 0,
    nickname = "",
    coin = 0,
    sex = 0,
    chairid = -1,
    gamestatus = STATUS.GAME_STATUS.WAIT_USERINFO,
    disconnect = 0,
}

M.LoginRes = {
    errorid = 0,
    player = {},
}

-- 坐下成功的回掉
M.SitDownRes = {
    errorid = 0,
    tableid = -1,
    chairid = -1,
    -- 上面的玩家信息
    players = {},
}

-- 准备
M.ReadRes = {
    errorid = 0,
    userid = -1,
    tableid = -1,
    chairid = -1,
}

-- 断线重入回掉
M.AgainLoginRes = {
    userid = 0,
    servertime = 0,
    tableid = -1,
    chairid = -1,
    -- 上面的玩家信息
    players = {},
}

M.AgainReconnect = {
    userid = 0,
}

M.TablePlayerJoin = {
    chairid = -1,
    player = {}
}

M.TablePlayerLeave = {
    userid = 0,
}

M.TablePlayerDisconnect = {
    userid = 0,
}

return M