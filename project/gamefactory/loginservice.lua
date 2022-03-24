local skynet = require "skynet"
require "skynet.manager"
local s = require "service"

s.resp.LoginReq = function (address, conf)
    local userid = conf.userid
    local password = conf.password
    skynet.error("LoginReq:", userid, password)
    -- 连接db验证
    return true, conf
end

s.init = function ()
    skynet.error("login server init...")
    skynet.register ".login"
    math.randomseed(os.time())
end

s.start(...)
