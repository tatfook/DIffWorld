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

-- libs
local ItemClient = commonlib.gettable('MyCompany.Aries.Game.Items.ItemClient')

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

function DiffWorldUI:Show(isLocal, diffs)
    self:Reset()

    self.isLocal = isLocal
    self.diffs = diffs or { __regions__ = {} }

    -- get region list
    self:GetRegionList()

    -- get chunk list
    for key, item in ipairs(self.regionList) do
        local chunkList = self:GetChunkList(item.region_key)

        self.chunkList[#self.chunkList + 1] = chunkList
    end

    -- get block list
    for key, item in ipairs(self.chunkList) do
        if item and type(item) == 'table' and #item > 0 then
            for iKey, iItem in ipairs(item) do
                local blockList = self:GetBlockList(iItem.region_key, iItem.chunk_key)

                self.blockList[#self.blockList + 1] = blockList
            end
        end
    end

    -- convert to 1 dimension array
    for key, item in ipairs(self.regionList) do
        item.category = 1
        item.is_show = true
        self.comprehansiveList[#self.comprehansiveList + 1] = item

        local chunk = self.chunkList[key]
        local codeBlocks = {}
        local movieBlocks = {}
        local otherBlocks = {}

        for cKey, cItem in ipairs(chunk) do
            local block = self.blockList[cKey]

            for bKey, bItem in ipairs(block) do
                -- code block ID is: 219
                -- movie block ID is: 228

                -- TODO: // merge blocks
                --curRegionBlocks
                echo(bItem, true)
            end
        end

        -- bItem.category = 2
        -- bItem.region_key = cItem.region_key
        -- bItem.is_show = false

        -- local blockDetail = self:GetBlockDetail(bItem, cItem.region_key, cItem.chunk_key)

        -- blockDetail.category = 3
        -- blockDetail.is_show = false

        -- local blockName = ItemClient.CreateGetByBlockID(blockDetail.remote_block_id):GetDisplayName()

        -- bItem.block_name = blockName
        -- blockDetail.block_name = blockName

        -- self.comprehansiveList[#self.comprehansiveList + 1] = bItem
        -- self.comprehansiveList[#self.comprehansiveList + 1] = blockDetail
    end

    echo(self.comprehansiveList, true)

    local params = Mod.WorldShare.Utils.ShowWindow(
        400,
        800,
        'Mod/DiffWorld/DiffWorldUI.html',
        'Mod.DiffWorld.DiffWorldUI',
        0,
        0,
        '_lt'
    )

    self:RefreshTree()
end

function DiffWorldUI:Reset()
    self.comprehansiveList = {}
    self.comprehansiveFilterList = {}
    self.regionList = {}
    self.chunkList = {}
    self.blockList = {}
    self.blockDetail = {}
    self.regionKey = '' -- 当前区域KEY
    self.chunkKey = '' -- 当前区块KEY
    self.blockIndex = '' -- 当前方块索引
    self.isLocal = nil
    self.diffs = { __regions__ = {} }
end

function DiffWorldUI:RefreshTree()
    local page = Mod.WorldShare.Store:Get('page/Mod.DiffWorld.DiffWorldUI')

    if not page then
        return
    end

    -- remove hide item
    self.comprehansiveFilterList = {}

    for key, item in ipairs(DiffWorldUI.comprehansiveList) do
        if item and item.is_show == true then
            self.comprehansiveFilterList[#self.comprehansiveFilterList + 1] = item
        end
    end

    page:GetNode('diff_tree'):SetUIAttribute('DataSource', self.comprehansiveFilterList)
end

function DiffWorldUI:GetRegionList()
    local diffs = self.diffs

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
end

function DiffWorldUI:GetChunkList(regionKey)
    if not regionKey then
        return
    end

    local region = self.diffs.__regions__[regionKey]
    local list = {}

    for chunkKey, chunk in pairs(region) do
        local chunkX, chunkZ = string.match(chunkKey, '(%d+)_(%d+)')
        local blockCount = 0

        for _ in pairs(chunk) do
            blockCount = blockCount + 1
        end

        table.insert(
            list,
            {
                chunk_x = tonumber(chunkX),
                chunk_z = tonumber(chunkZ),
                chunk_key = chunkKey,
                region_key = regionKey,
                block_count = blockCount,
            }
        )
    end

    return list
end

function DiffWorldUI:GetBlockList(regionKey, chunkKey)
    if not regionKey or not chunkKey then
        return
    end

    local region = self.diffs.__regions__[regionKey]
    local chunk = region[chunkKey]

    local list = {}

    for blockIndex, block in pairs(chunk) do
        table.insert(
            list,
            {
                x = block.x,
                y = block.y,
                z= block.z,
                block_index = blockIndex
            }
        )
    end

    return list
end

function DiffWorldUI:GetBlockDetail(block, regionKey, chunkKey)
    if not block or not regionKey or not chunkKey then
        return
    end

    local region = self.diffs.__regions__[regionKey]
    local chunk = region[chunkKey]
    local chunkBlock = chunk[block.block_index]

    local detail = {
        x = block.x,
        y = block.y,
        z = block.z,
        block_index = block.block_index
    }

    if self.isLocal then
        detail.local_block_id = chunkBlock.local_block_id
        detail.local_block_data = chunkBlock.local_block_data
        detail.local_entity_data = chunkBlock.local_entity_data

        detail.remote_block_id = chunkBlock.remote_block_id
        detail.remote_block_data = chunkBlock.remote_block_data
        detail.remote_entity_data = chunkBlock.remote_entity_data
    else
        detail.remote_block_id = chunkBlock.local_block_id
        detail.remote_block_data = chunkBlock.local_block_data
        detail.remote_entity_data = chunkBlock.local_entity_data

        detail.local_block_id = chunkBlock.remote_block_id
        detail.local_block_data = chunkBlock.remote_block_data
        detail.local_entity_data = chunkBlock.remote_entity_data
    end

    detail.is_equal_block_id = detail.local_block_id == detail.remote_block_id
    detail.is_equal_block_data = detail.local_block_data == detail.remote_block_data
    detail.is_equal_entity_data = detail.local_entity_data == detail.remote_entity_data

    return detail
end