--[[
Title: Diff World Command
Author(s):  Big
Date: 2021.08.09
Desc: 
use the lib:
------------------------------------------------------------
local DiffWorldCommand = NPL.load('(gl)Mod/DiffWorld/DiffWorldCommand.lua')
------------------------------------------------------------
]]

-- libs
local Commands = commonlib.gettable('MyCompany.Aries.Game.Commands')
local CommandManager = commonlib.gettable('MyCompany.Aries.Game.CommandManager')
local CmdParser = commonlib.gettable('MyCompany.Aries.Game.CmdParser')

-- task
local DiffWorldTask = NPL.load('./DiffWorldTask.lua')

local DiffWorldCommand = NPL.export()

function DiffWorldCommand:init()
    Commands["diff2"] = {
        mode_deny = "",
        name = "diff2",
        quick_ref = "/diff2 open|connect|server -port=9000",
        desc = [[
    /diffworld open 新起Paracraft客户端并打开当前世界的最新版本
    /diffworld connect -port=9000 连接对比的远程世界并开始对比世界,  -port 可指定连接端口, 默认9000
    /diffworld server -port=9000 启动对比世界服务器, -port 指定监听端口 默认9000
        ]],
        handler = function(cmd_name, cmd_text, cmd_params, from_entity)
            local cmd, cmd_text = CmdParser.ParseString(cmd_text)
            local port = string.match(cmd_text, '-port=(%d+)')

            port = port or 9000

            if not self.diffTask then
                self.diffTask = DiffWorldTask:new()
            end

            if (cmd == 'open') then
                self:Open()
            elseif (cmd == 'connect') then
                self:Connect(port)
            elseif (cmd == 'server') then
                self:Server(port)
            else
                self:Open(function()
                    self:Server(port)
                end)
            end
        end
    }
end

function DiffWorldCommand:Open(callback)
    self.diffTask:DownloadWorldById(nil, function(bSuccess, worldDirectory)
        if bSuccess then
            CommandManager:RunCommand(string.format('/open paracraft://cmd/loadworld %s loadpackage="G:/code/trunk/,;G:/code/DiffWorld/" logfile="./log_diff.txt"', worldDirectory));
        end
    end)

    if callback and type(callback) == 'function' then
        callback()
    end
end

function DiffWorldCommand:Connect(port, callback)
    self.diffTask:StartClient('127.0.0.1', port)

    if callback and type(callback) == 'function' then
        callback()
    end
end

function DiffWorldCommand:Server(port, callback)
    self.diffTask:StartServer('0.0.0.0', port)

    if callback and type(callback) == 'function' then
        callback()
    end
end
