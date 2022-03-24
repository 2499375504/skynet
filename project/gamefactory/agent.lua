local s = require "service"
local skynet = require "skynet"
local socket = require "skynet.socket"
local cjson = require "cjson"
local STATUS = require "gamestatus"
local netpack = require "skynet.netpack"
require "jsonutils"
local sraw = require "stable.raw"
local FMSG = require "factorymessage"
sraw.init()

local WATCHDOG

local REQUEST = {}
local client_fd
local isAuthen = false
local playerstable = nil

local function send_package(clientfd, cmd, pack)
	skynet.error("send_package", clientfd, cmd, pack)
	assert(clientfd == client_fd, string.format("error clientfd:%d,%d", clientfd, client_fd))
	local package = Json_pack(cmd, pack)
	socket.write(clientfd, package)
end

function REQUEST.login(args)
	if isAuthen then
		-- TODO 重复登陆
		s.closeSocket()
		return
	end

	isAuthen = true
	local bool, userinfo = skynet.call(".login", "lua", "LoginReq", args)
	userinfo.agentAddr = skynet.self()
	userinfo.client_fd = client_fd
	userinfo.userid = 123
    userinfo.password = ""
    userinfo.sex = 0
    userinfo.username = ""
    userinfo.nickname = ""

	if bool then
		-- 这边再判断下是因为中途可能disconnect
		if isAuthen then
			playerstable = skynet.call(".gameservice", "lua", "LoginSuccess", userinfo)
		end
	else
		-- TODO 发送账号密码错误
		s.closeSocket()
	end
end

-- 坐下
function REQUEST.sitdown(args)
	assert(playerstable ~= nil and playerstable.agentAddr > 0)
	assert(playerstable.agentAddr == skynet.self() and playerstable.tableAddr == 0)
	if playerstable.gamestatus ~= STATUS.GAME_STATUS.WAIT_DESK then
		-- TODO 状态不对
		skynet.error("set error", playerstable.gamestatus)
		return
	end

	playerstable.gamestatus = STATUS.GAME_STATUS.WAIT_DESK_SURE
	-- skynet  这边可能会挂起 多线程的一定先设置状态
    s.send(".gameservice", "HandleSitDownReq", playerstable)
end

-- 准备
function REQUEST.ready(args)
	s.send(playerstable.tableAddr, "HandleReadyReq", playerstable)
end

function REQUEST.handshake()
	send_package(client_fd, FMSG.HANDSHAKE)
end

function REQUEST.message(cmd, args)
	s.send(playerstable.tableAddr, "Message", cmd, args)
end

function REQUEST.quit()
	skynet.call(WATCHDOG, "lua", "close", client_fd)
end

local function request(cmd, args)
	-- 还没有认证
	if not isAuthen and cmd ~= FMSG.LOGIN and cmd ~= FMSG.HANDSHAKE then
		-- 非法消息
		s.closeSocket()
		return
	end

	if cmd == FMSG.LOGIN then
		REQUEST.login(args)
	elseif cmd == FMSG.SITDOWN then
		REQUEST.sitdown(args)
	elseif cmd == FMSG.HANDSHAKE then
		REQUEST.handshake()
	else
		-- 这个时候应该在房间里面了
		assert(playerstable ~= nil and playerstable.agentAddr > 0 )
		assert(playerstable.agentAddr == skynet.self() and playerstable.tableAddr > 0)
		if cmd == FMSG.READY then
			REQUEST.ready(args)
		else
			REQUEST.message(cmd, args)
		end
	end
end

function s.resp.start(address, conf)
	local fd = conf.client
	local gate = conf.gate
	WATCHDOG = conf.watchdog
	skynet.fork(function()
		while true do
			send_package(client_fd, "heartbeat")
			skynet.sleep(500)
		end
	end)

	client_fd = fd
	skynet.call(gate, "lua", "forward", fd)
end

-- 转发到客户端
function s.resp.send_data(_, client_fd, cmd, pack)
    send_package(client_fd, cmd, pack)
end

function s.resp.closeSocket(address)
	s.closeSocket()
end

function s.resp.disconnect()
	-- todo: do something before exit
	if playerstable then
		if isAuthen then
			isAuthen = false
			s.call(".gameservice", "disconnect", playerstable)
		end
	end

	skynet.exit()
end

function s.closeSocket()
	s.send(WATCHDOG, "close", client_fd)
end

s.init = function ()
	skynet.register_protocol {
		name = "client",
		id = skynet.PTYPE_CLIENT,
		unpack = function (msg, sz)
			return Json_unpack(msg, sz)
		end,
		dispatch = function (fd, _, cmd, msg)
			assert(fd == client_fd)	-- You can use fd to reply message
			skynet.ignoreret()	-- session is fd, don't call skynet.ret
			-- skynet.trace()
			if cmd then
				local ok, result = pcall(request, cmd, msg)
				if not ok then
					skynet.error(result)
				end
			else
				error("This example doesn't support request client", msg.cmd)
			end
		end
	}
end

s.start(...)
