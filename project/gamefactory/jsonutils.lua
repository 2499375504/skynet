local skynet = require "skynet"
local cjson = require "cjson"

function Json_pack(cmd, msg)
	if msg == nil then
		msg = {}
	end
	msg._cmd = cmd
	local body = cjson.encode(msg)
	local namelen = string.len(cmd)
	local bodylen = string.len(body)
	local len = namelen + bodylen + 2
	skynet.error("json_pack:", cmd, msg, len)
	local format = string.format("> i2 i2 c%d c%d", namelen, bodylen)
	local buff = string.pack(format, len, namelen, cmd, body)
	return buff
end

function Json_unpack(rawbuff, sz)
	local buff = skynet.tostring(rawbuff, sz)
	local len = string.len(buff)
	local namelen_format = string.format("> i2 c%d", len - 2)
	local namelen, other = string.unpack(namelen_format, buff)
	local bodylen = len-2-namelen
	local format = string.format("> c%d c%d", namelen, bodylen)
	local cmd, bodybuff = string.unpack(format, other)
	local isok, msg = pcall(cjson.decode, bodybuff)

	skynet.error(isok, msg, msg._cmd, cmd)
	if not isok or not msg or not msg._cmd or not cmd == msg._cmd then
		skynet.error("error json_unpack")
		return
	end

	return cmd, msg
end

function Json_unspack(buff)
	local len = string.len(buff)
	local namelen_format = string.format("> i2 c%d", len - 2)
	local namelen, other = string.unpack(namelen_format, buff)
	local bodylen = len-2-namelen
	local format = string.format("> c%d c%d", namelen, bodylen)
	local cmd, bodybuff = string.unpack(format, other)
	local isok, msg = pcall(cjson.decode, bodybuff)

	skynet.error(isok, msg, msg._cmd, cmd)
	if not isok or not msg or not msg._cmd or not cmd == msg._cmd then
		skynet.error("error json_unspack")
		return
	else
		skynet.error("Json_unspack", cmd, msg)
	end

	return cmd, msg
end
