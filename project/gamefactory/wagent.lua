local skynet = require "skynet"
local websocket = require "http.websocket"
local cjson = require "cjson"
local STATUS = require "gamestatus"
require "jsonutils"
require "functions"
local sraw = require "stable.raw"
local FMSG = require "factorymessage"
local s = require "service"
sraw.init()

local REQUEST = {}
local client_fds = {}

-- local isAuthen = false
-- local playerstable = nil

local function assertfd(clientfd)
    assert(client_fds[clientfd] ~= nil, string.format("error clientfd:%d", clientfd))
end

local function send_package(clientfd, cmd, pack)
	if pack == nil then
		pack = {}
	end
	pack._cmd = cmd
	local package = cjson.encode(pack)
	dump(pack, "pack")
	websocket.write(clientfd, package)
end

local function decode_package(pack)
    local package = cjson.decode(pack)
    return package._cmd, package
end

function REQUEST.login(client_fd, args)
	if client_fds[client_fd].isAuthen then
		-- TODO 重复登陆
		s.closeSocket(client_fd)
		return
	end

	client_fds[client_fd].isAuthen = true
	local bool, userinfo = skynet.call(".login", "lua", "LoginReq", args)
	userinfo.agentAddr = skynet.self()
	userinfo.client_fd = client_fd
	userinfo.userid = tonumber(args.userid)
    userinfo.password = args.password
    userinfo.sex = 0
    userinfo.username = "u"..args.userid
    userinfo.nickname = "n"..args.userid

	if bool then
		-- 这边再判断下是因为中途可能disconnect
		if client_fds[client_fd].isAuthen then
			client_fds[client_fd].playerstable = skynet.call(".gameservice", "lua", "LoginSuccess", userinfo)
		end
	else
		-- TODO 发送账号密码错误
		s.closeSocket()
	end
end

-- 坐下
function REQUEST.sitdown(client_fd, args)
    local playerstable = client_fds[client_fd].playerstable
	assert(playerstable ~= nil and playerstable.agentAddr > 0)
	assert(playerstable.agentAddr == skynet.self() and playerstable.tableAddr == 0)
	if playerstable.gamestatus ~= STATUS.GAME_STATUS.WAIT_DESK then
		-- TODO 状态不对
		print("set error", playerstable.gamestatus)
		return
	end

	playerstable.gamestatus = STATUS.GAME_STATUS.WAIT_DESK_SURE
	-- skynet  这边可能会挂起 多线程的一定先设置状态
    s.send(".gameservice", "HandleSitDownReq", playerstable)
end

-- 准备
function REQUEST.ready(playerstable, args)
	s.send(playerstable.tableAddr, "HandleReadyReq", playerstable)
end

function REQUEST.message(playerstable, cmd, args)
	s.send(playerstable.tableAddr, "Message", cmd, args)
end


local handle = {}

function handle.connect(id)
    print("ws connect from: " .. tostring(id))
    client_fds[id] = {
        isAuthen = false,
        playerstable = nil
    }
end

function handle.handshake(id, header, url)
    local addr = websocket.addrinfo(id)
    print("ws handshake from: " .. tostring(id), "url", url, "addr:", addr)
    print("----header-----")
    for k,v in pairs(header) do
        print(k,v)
    end
    print("--------------")
    -- send_package(id, FMSG.HANDSHAKE, "123", false)
end

function handle.message(id, msg, msg_type)
    assert(msg_type == "binary" or msg_type == "text")
    print("message:", msg_type, msg)

    assertfd(id)
    local cmd, args = decode_package(msg)

    if nil == cmd then
        print("cmd not found")
        return
    end

    local isAuthen = client_fds[id].isAuthen
    local playerstable = client_fds[id].playerstable
    -- 还没有认证
	if not isAuthen and cmd ~= FMSG.LOGIN and cmd ~= FMSG.HANDSHAKE then
		-- 非法消息
		print(isAuthen, cmd)
		s.closeSocket(id)
		return
	end

	if cmd == FMSG.LOGIN then
		REQUEST.login(id, args)
	elseif cmd == FMSG.SITDOWN then
		REQUEST.sitdown(id, args)
	else
		-- 这个时候应该在房间里面了
		assert(playerstable ~= nil and playerstable.agentAddr > 0 )
		assert(playerstable.agentAddr == skynet.self() and playerstable.tableAddr > 0)
		print("message:", playerstable.userid, id, playerstable.tableAddr)
		if cmd == FMSG.READY then
			REQUEST.ready(playerstable, args)
		else
			REQUEST.message(playerstable, cmd, args)
		end
	end
    
end

function handle.ping(id)
    print("ws ping from: " .. tostring(id) .. "\n")
end

function handle.pong(id)
    print("ws pong from: " .. tostring(id))
end

local function onClose(fd)
    assertfd(fd)
    if client_fds[fd].playerstable then
		if client_fds[fd].isAuthen then
			client_fds[fd].isAuthen = false
			print("onClose fd:", fd)
			s.send(".gameservice", "disconnect", client_fds[fd].playerstable)
			client_fds[fd] = nil
		end
	end
end

function handle.close(id, code, reason)
    print("ws close from: " .. tostring(id), code, reason)
    onClose(id)
end

function handle.error(id)
    print("ws error from: " .. tostring(id))
    onClose(id)
end

-- 转发到客户端
function s.resp.send_data(address, client_fd, cmd, pack)
    print("send_data", client_fd, cmd, pack)
    send_package(client_fd, cmd, pack)
end

function s.resp.closeSocket(address, client_fd)
	s.closeSocket(client_fd)
end

function s.resp.socket(address, id, protocol, addr)
	local ok, err = websocket.accept(id, handle, protocol, addr)
	if not ok then
		print(err)
	end
end

function s.closeSocket(clientfd)
    assertfd(clientfd)
	websocket.close(clientfd)
end

s.init = function ()

end

s.start(...)
