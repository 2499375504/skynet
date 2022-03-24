
local socket = require "skynet.socket"
local skynet = require "skynet"
local websocket = require "http.websocket"
local cjson = require "cjson"
require "functions"
require "jsonutils"

local ws_id = 0

local function send_package(clientfd, cmd, pack, ispack)
	if pack == nil then
		pack = {}
	end
	pack._cmd = cmd
	local package = cjson.encode(pack)
	dump(pack, "pack")
	websocket.write(clientfd, package)
end

skynet.start(function ()
    local url = string.format("ws://127.0.0.1:8001")
    ws_id = websocket.connect(url)

    skynet.fork(function ()
        print("ws_id:", ws_id)
        while true do
            if ws_id == 0 then
                skynet.sleep(10)
            end
            send_package(ws_id, "login")
            local resp, close_reason = websocket.read(ws_id)
            print("<: " .. (resp and resp or "[Close] " .. close_reason))
            if not resp then
                print("echo server close.")
                break
            end
            websocket.ping(ws_id)
            skynet.sleep(100)
        end
    end)

    print("end.....")
end)