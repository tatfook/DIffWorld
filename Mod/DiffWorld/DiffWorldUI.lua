--[[
Title: Diff World UI
Author(s):  Big
Date: 2021.08.09
Desc: 
use the lib:
------------------------------------------------------------
local DiffWorldUI = NPL.load('(gl)Mod/DiffWorld/DiffWorldUI.lua')
------------------------------------------------------------
]]

local DiffWorldUI = NPL.export()

-- Diffs data format
--[[
{
    __regions__ = {
        ["37_37"] = {
            ["1200_1200"] = {
                ["123456"] = {x = 19200, y = 5, z = 19200, block_id = 62},
            },
            ["1200_1202"] = {
                ["123456"] = {x = 19200, y = 5, z = 19200, block_id = 62},
                ["1234561"] = {x = 19200, y = 5, z = 19200, block_id = 62},
                ["1234562"] = {x = 19200, y = 5, z = 19200, block_id = 62},
                ["1234563"] = {x = 19200, y = 5, z = 19200, block_id = 62},
                ["1234564"] = {x = 19200, y = 5, z = 19200, block_id = 62},
                ["1234565"] = {x = 19200, y = 5, z = 19200, block_id = 62},
                ["1234566"] = {x = 19200, y = 5, z = 19200, block_id = 62},
            },
            ["1200_1203"] = {
                ["123456"] = {x = 19200, y = 5, z = 19200, block_id = 62}
            },
            ["1200_1204"] = {
                ["123456"] = {x = 19200, y = 5, z = 19200, block_id = 62}
            },
            ["1200_1205"] = {
                ["123456"] = {x = 19200, y = 5, z = 19200, block_id = 62}
            },
            ["1200_1206"] = {
                ["123456"] = {x = 19200, y = 5, z = 19200, block_id = 62}
            },
        },
        ["36_36"] = {
            ["1100_1100"] = {
                ["223456"] = {x = 19200, y = 5, z = 19200, block_id = 62}
            }
        }
    }
}
]]

DiffWorldUI.regionList = {}
DiffWorldUI.chunkList = {}
DiffWorldUI.blockList = {}
DiffWorldUI.blockDetail = {}
DiffWorldUI.regionKey = '' -- 当前区域KEY
DiffWorldUI.chunkKey = '' -- 当前区块KEY
DiffWorldUI.blockIndex = '' -- 当前方块索引

function DiffWorldUI:Show(isLocal, diffs)
    self:Reset()

    local diffs = diffs or { __regions__ = {} }

    for regionKey, region in pairs(diffs.__regions__) do 
        local regionX, regionZ = string.match(regionKey, '(%d+)_(%d+)')
        local chunkCount = 0

        for _ in pairs(region) do
            chunkCount = chunkCount + 1
        end

        table.insert(
            self.regionList,
            {
                region_x = tonumber(regionX),
                region_z = tonumber(regionZ),
                region_key = regionKey,
                chunk_count = chunkCount,
            }
        )
    end

    local params = Mod.WorldShare.Utils.ShowWindow(
        400,
        800,
        'Mod/DiffWorld/DiffWorldUI.html',
        'Mod.DiffWorld.DiffWorldUI',
        0,
        0,
        '_lt'
    )
end

function DiffWorldUI:Reset()
    self.regionList = {}
    self.chunkList = {}
    self.blockList = {}
    self.blockDetail = {}
    self.regionKey = '' -- 当前区域KEY
    self.chunkKey = '' -- 当前区块KEY
    self.blockIndex = '' -- 当前方块索引
end

function DiffWorldUI:GetChunkList()
    local region = __diffs__.__regions__[region_key]
    local list = {}

    for chunk_key, chunk in pairs(region) do
        local chunk_x, chunk_z = string.match(chunk_key, "(%d+)_(%d+)")
        local block_count = 0

        for _ in pairs(chunk) do
            block_count = block_count + 1
        end

        table.insert(
            list,
            {
                chunk_x = tonumber(chunk_x),
                chunk_z = tonumber(chunk_z),
                chunk_key = chunk_key,
                region_key = region_key,
                block_count = block_count,
            }
        )
    end

    return list
end

function DiffWorldUI:GetBlockList()
    local region = __diffs__.__regions__[region_key]
    local chunk = region[chunk_key]
    local list = {}

    for block_index, block in pairs(chunk) do
        table.insert(
            list,
            {
                x = block.x,
                y = block.y,
                z= block.z,
                block_index = block_index
            }
        )
    end

    return list
end

function DiffWorldUI:GetBlockDetail(block)
    local region = __diffs__.__regions__[region_key]
    local chunk = region[chunk_key]
    local chunk_block = chunk[block.block_index]
    local detail = {
        x = block.x,
        y = block.y,
        z = block.z,
        block_index = block.block_index
    }

    if __is_local__ then
        detail.local_block_id = chunk_block.local_block_id
        detail.local_block_data = chunk_block.local_block_data
        detail.local_entity_data = chunk_block.local_entity_data

        detail.remote_block_id = chunk_block.remote_block_id
        detail.remote_block_data = chunk_block.remote_block_data
        detail.remote_entity_data = chunk_block.remote_entity_data
    else
        detail.remote_block_id = chunk_block.local_block_id
        detail.remote_block_data = chunk_block.local_block_data
        detail.remote_entity_data = chunk_block.local_entity_data

        detail.local_block_id = chunk_block.remote_block_id
        detail.local_block_data = chunk_block.remote_block_data
        detail.local_entity_data = chunk_block.remote_entity_data
    end

    detail.is_equal_block_id = detail.local_block_id == detail.remote_block_id
    detail.is_equal_block_data = detail.local_block_data == detail.remote_block_data
    detail.is_equal_entity_data = detail.local_entity_data == detail.remote_entity_data

    return detail
end