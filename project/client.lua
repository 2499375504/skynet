package.cpath = "luaclib/?.so"
package.path = "lualib/?.lua;examples/?.lua"

if _VERSION ~= "Lua 5.4" then
	error "Use lua 5.4"
end

local socket = require "client.socket"
local cjson = require "cjson"

local fd = assert(socket.connect("127.0.0.1", 8001))

local function json_pack(cmd, msg)
	msg._cmd = cmd
	local body = cjson.encode(msg)
	local namelen = string.len(cmd)
	local bodylen = string.len(body)
	local len = namelen + bodylen + 2
	local format = string.format("> i2 i2 c%d c%d", namelen, bodylen)
	local buff = string.pack(format, len, namelen, cmd, body)
	return buff
end

local function send_package(fd, pack)
	-- local package = string.pack(">s2", pack)
	socket.send(fd, pack)
end

local function unpack_package(text)
	local size = #text
	if size < 2 then
		return nil, text
	end
	local s = text:byte(1) * 256 + text:byte(2)
	if size < s+2 then
		return nil, text
	end

	return text:sub(3,2+s), text:sub(3+s)
end

local function recv_package(last)
	local result
	result, last = unpack_package(last)
	if result then
		return result, last
	end
	local r = socket.recv(fd)
	if not r then
		return nil, last
	end
	if r == "" then
		error "Server closed"
	end
	return unpack_package(last .. r)
end

local session = 0

local function send_request(name, args)
	session = session + 1
	local str = json_pack(name, args)
	send_package(fd, str)
	print("Request:", session)
end

local last = ""

local function print_request(name, args)
	print("REQUEST", name)
	if args then
		for k,v in pairs(args) do
			print(k,v)
		end
	end
end

local function print_response(session, args)
	print("RESPONSE", session)
	if args then
		for k,v in pairs(args) do
			print(k,v)
		end
	end
end

local function print_package(t, ...)
	if t == "REQUEST" then
		print_request(...)
	else
		assert(t == "RESPONSE")
		print_response(...)
	end
end

local function dispatch_package()
	while true do
		local v
		v, last = recv_package(last)
		if not v then
			break
		end
	end
end

-- 分隔字符串
local function split(str, flag)
    local tab = {}
    while true do
        -- 在字符串中查找分割的标签
        local n = string.find(str, flag)
        if n then
            -- 截取分割标签之前的字符串
            local first = string.sub(str, 1, n-1) 
            -- str 赋值为分割之后的字符串
            str = string.sub(str, n+1, #str) 
            -- 把截取的字符串 保存到table中
            table.insert(tab, first)
        else
            table.insert(tab, str)
            break
        end
    end
    return tab
end

send_request("handshake", {a="123"})
while true do
	dispatch_package()
	local line = socket.readstdin()
	if line then
		local args = split(line, " ")
		if #args > 0 then
			send_request(args[1], table.pack(table.unpack(args, 2)))
		else
			socket.usleep(100)
		end
	end
	
end
