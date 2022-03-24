require "functions"
local skynet = require "skynet"
local tablelogic = require "tablelogic"
local tableframe = class("tableframe", tablelogic)

function tableframe:ctor()
    skynet.error("tableframe:ctor:", self, self.super)
    self.super.ctor(self)
end

function tableframe:initCfg(...)
    self.super.initCfg(self, ...)
end

function tableframe:CallBackReadySuccess(playernode)
    skynet.error("tableframe:CallBackReadSuccess")
    self:OnGameStart()
end

function tableframe:onTimer()
    -- skynet.error("onTimer")
end

function tableframe:OnGameStart()
    self:GameStart()
    self:sendAllData("GameStart")
    -- 这个按照各个游戏的逻辑来
    self:LockTable(true)
    skynet.sleep(5000)
    
    self:OnGameEnd()
end

function tableframe:OnGameEnd()
    self:LockTable(false)
    self:GameEnd()
    self:sendAllData("GameEnd")
end

return tableframe
