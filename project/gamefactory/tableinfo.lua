local M = {}

M.cfg = nil

-- 是不是满房间了 lua栈 数据不共享 stable加锁 暂时不想用太多
M.playernum = 0
-- 是不是已经不能再进了
M.busy = false
-- 逻辑线程
M.tablelogic = nil

function M:init(cfg)
    self.cfg = cfg
    -- {
    --     -- 桌子号 房卡房的话就是房间号
    --     id = 0,
    --     playernum = 4,
    --     -- 是否允许旁观
    --     allowlookon = true,
    --     -- 房间规则 
    --     rules = {}
    -- }
end

function M:isfull()
    return self.playernum >= self.cfg.playernum or self.busy
end

function M:addplayer()
    self.playernum = self.playernum + 1
end

function M:subplayer()
    self.playernum = self.playernum - 1
end

return M