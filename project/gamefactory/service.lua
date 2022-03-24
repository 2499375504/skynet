local skynet = require "skynet"
local cluster = require "skynet.cluster"

local M = {
    name = "",
    id = 0,
    exit = nil,
    init = nil,
    resp = {},
    msg = nil
}

local function traceback(err)
    skynet.error(tostring(err))
    skynet.error(debug.traceback())
end

local dispatch = function (session, address, cmd, ...)
    local func = M.resp[cmd]
    if not func then
        if M.msg == nil then
            skynet.ret()
            return
        end
        func = M.msg
    end

    local ret = table.pack(xpcall(func, traceback, address, ...))
    local isOk = ret[1]
    if not isOk then
        skynet.ret()
        return
    end
    skynet.retpack(table.unpack(ret, 2))
end

local function init(...)
    skynet.dispatch("lua", dispatch)
    if M.init then
        M.init(...)
    end
end

function M.call(srv, ...)
    return skynet.call(srv, "lua", ...)
end

function M.callcl(node, srv, ...)
    local mynode = skynet.getenv("node")
    if node == mynode then
        return skynet.call(srv, "lua", ...)
    else
        return cluster.call(node, srv, ...)
    end
end

function M.send(srv, ...)
    return skynet.send(srv, "lua", ...)
end

function M.sendcl(node, srv, ...)
    local mynode = skynet.getenv("node")
    if node == mynode then
        return skynet.send(srv, "lua", ...)
    else
        return cluster.send(node, srv, ...)
    end
end

function M.start(name, id, ...)
    skynet.error("name:", name, ...)
    M.name = name
    M.id = tonumber(id)
    local args = {...}
    if #args > 0 then
        skynet.error("name:", name, ", args:", args[0])
    end
    skynet.start(function() 
        init(table.unpack(args))
    end)
end


return M