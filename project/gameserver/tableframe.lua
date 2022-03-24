require "functions"
local skynet = require "skynet"
local tablelogic = require "tablelogic"
local tableframe = class("tableframe", tablelogic)

function tableframe:ctor()
    print("tableframe:ctor:", self, self.super)
    self.super.ctor(self)
end

function tableframe:initCfg(...)
    self.super.initCfg(self, ...)
end

function tableframe:CallBackReadySuccess(playernode)
    print("tableframe:CallBackReadSuccess")
    self:OnGameStart()
end

function tableframe:OnGameStart()
    self:GameStart()
    -- 这个按照各个游戏的逻辑来
    self.tableAgent.send(".gameservice", "tableBusy", self.tableCfg.id, true)
    skynet.sleep(5000)
    self:GameEnd()

    self:sendAllData("GameEnd")

end

return tableframe
