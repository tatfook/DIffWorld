--[[
Title: Diff World Mod
Author(s):  Big
Date: 2021.08.09
Desc: 
use the lib:
------------------------------------------------------------
NPL.load('(gl)Mod/DiffWorld/main.lua')
local DiffWorld = commonlib.gettable('Mod.DiffWorld')
------------------------------------------------------------

CODE GUIDELINE

1. all classes and functions use upper camel case.
2. all variables use lower camel case.
3. all files use use upper camel case.
4. all templates variables and functions use underscore case.
5. single quotation marks are used for strings.

]]

NPL.load('(gl)script/apps/Aries/Creator/Game/Commands/CommandManager.lua')
NPL.load('(gl)script/apps/Aries/Creator/Game/block_engine.lua')
NPL.load('(gl)script/apps/Aries/Creator/Game/Tasks/DestroyBlockTask.lua')
NPL.load("(gl)script/apps/Aries/Creator/Game/Tasks/CreateBlockTask.lua")

-- libs

-- command
local DiffWorldCommand = NPL.load('./DiffWorldCommand.lua')

local DiffWorld = commonlib.inherit(commonlib.gettable('Mod.ModBase'), commonlib.gettable('Mod.DiffWorld'))

DiffWorld:Property({'Name', 'DiffWorld', 'GetName', 'SetName', { auto = true }})
DiffWorld:Property({'Desc', 'Compare with the previous worlds to find out differents.', 'GetDesc', 'SetDesc', { auto = true }})
DiffWorld.version = '0.0.1'

LOG.std(nil, 'info', 'DiffWorld', 'Diff world mod version: %s', DiffWorld.version)

function DiffWorld:init()
    DiffWorldCommand:init()
end

function DiffWorld:OnWorldLoad()
    if ParaEngine.GetAppCommandLineByParam('diffworld', nil) then
        GameLogic.RunCommand('/diff connect')
    end
end


