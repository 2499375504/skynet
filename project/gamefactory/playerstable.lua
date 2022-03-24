local STATUS = require "gamestatus"
local sraw = require "stable.raw"
sraw.init()

local playerInfo = {
    agentAddr = 0,
    client_fd = 0,
    tableAddr = 0,
    chairid = -1,
    gamestatus = STATUS.GAME_STATUS.WAIT_USERINFO,
    kickout = false,

    userid = 0,
    password = "",
    sex = 0,
    username = {},
    nickname = "",
}

local playerstable = {}

function playerstable.create()
    local node = sraw.create(playerInfo)
    playerstable.Initialize(node)
    return node
end

function playerstable.Initialize(node)
    playerstable.Reset(node)
end

function playerstable.Reset(node)
    node.agentAddr = 0
    node.client_fd = 0
    node.tableAddr = 0
    node.chairid = -1
    node.gamestatus = STATUS.GAME_STATUS.WAIT_USERINFO
    node.kickout = false

    node.userid = 0
    node.password = ""
    node.sex = 0
    node.username = ""
    node.nickname = ""
end

function playerstable.SetUserInfo(node, info)
    node.agentAddr = info.agentAddr
    node.userid = info.userid
    node.password = info.password
    node.client_fd = info.client_fd
    -- node.sex = info.sex
    -- node.username = info.username
    -- node.nickname = info.nickname
end

return playerstable