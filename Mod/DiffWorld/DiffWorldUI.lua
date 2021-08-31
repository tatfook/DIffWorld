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

        self.chunkList[key] = chunkList
    end

    -- get block list
    for key, chunk in ipairs(self.chunkList) do
        self.blockList[key] = {}
        local chunkBlockList = self.blockList[key]

        if chunk and type(chunk) == 'table' and #chunk > 0 then
            for cKey, cItem in ipairs(chunk) do
                local blockList = self:GetBlockList(cItem.region_key, cItem.chunk_key)

                chunkBlockList[cKey] = blockList
            end
        end
    end

    self.comprehansiveList[#self.comprehansiveList + 1] = {
        title = L'更改：',
        is_show = true,
        category = 0,
    }

    local countAdd = 0
    local countDelete = 0
    local countModify = 0

    self.codeBlocks = {}
    self.movieBlocks = {}
    self.otherBlocks = {}

    -- convert to 1 dimension array
    for key, item in ipairs(self.regionList) do
        local chunk = self.chunkList[key]

        local codeBlocks = {}
        local movieBlocks = {}
        local otherBlocks = {}

        for cKey, cItem in ipairs(chunk) do
            local block = self.blockList[key][cKey]

            for bKey, bItem in ipairs(block) do
                -- code block ID is: 219
                -- movie block ID is: 228

                -- remote_block_id is: history world
                -- local_block_id is: current edit world

                local blockDetail = self:GetBlockDetail(bItem, cItem.region_key, cItem.chunk_key)

                blockDetail.category = 3
                blockDetail.region_key = item.region_key
                blockDetail.is_show = false

                -- modify blocks
                if blockDetail.local_block_id and blockDetail.remote_block_id then
                    local blockName = ItemClient.CreateGetByBlockID(blockDetail.local_block_id):GetDisplayName()
                    blockDetail.block_name = blockName
                    blockDetail.operate = 'MODIFY'

                    if blockDetail.local_block_id == 219 then
                        -- code blocks
                        blockDetail.block_type = 'CODE_BLOCKS'
                        codeBlocks[#codeBlocks + 1] = blockDetail
                        self.codeBlocks[#self.codeBlocks + 1] = blockDetail
                    elseif blockDetail.local_block_id == 228 then
                        -- movie blocks
                        blockDetail.block_type = 'MOVIE_BLOCKS'
                        movieBlocks[#movieBlocks + 1] = blockDetail
                        self.movieBlocks[#self.movieBlocks + 1] = blockDetail
                    else
                        -- other blocks
                        blockDetail.block_type = 'OTHER_BLOCKS'
                        otherBlocks[#otherBlocks + 1] = blockDetail
                        self.otherBlocks[#self.otherBlocks + 1] = blockDetail
                    end
                end

                -- remove blocks
                if not blockDetail.local_block_id and blockDetail.remote_block_id then
                    local blockName = ItemClient.CreateGetByBlockID(blockDetail.remote_block_id):GetDisplayName()
                    blockDetail.block_name = blockName
                    blockDetail.operate = 'DELETE'

                    if blockDetail.remote_block_id == 219 then
                        -- code blocks
                        blockDetail.block_type = 'CODE_BLOCKS'
                        codeBlocks[#codeBlocks + 1] = blockDetail
                        self.codeBlocks[#self.codeBlocks + 1] = blockDetail
                    elseif blockDetail.remote_block_id == 228 then
                        -- movie blocks
                        blockDetail.block_type = 'MOVIE_BLOCKS'
                        movieBlocks[#movieBlocks + 1] = blockDetail
                        self.movieBlocks[#self.movieBlocks + 1] = blockDetail
                    else
                        -- other blocks
                        blockDetail.block_type = 'OTHER_BLOCKS'
                        otherBlocks[#otherBlocks + 1] = blockDetail
                        self.otherBlocks[#self.otherBlocks + 1] = blockDetail
                    end
                end

                -- add blocks
                if blockDetail.local_block_id and not blockDetail.remote_block_id then
                    local blockName = ItemClient.CreateGetByBlockID(blockDetail.local_block_id):GetDisplayName()
                    blockDetail.block_name = blockName
                    blockDetail.operate = 'ADD'

                    if blockDetail.local_block_id == 219 then
                        -- code blocks
                        blockDetail.block_type = 'CODE_BLOCKS'
                        codeBlocks[#codeBlocks + 1] = blockDetail
                        self.codeBlocks[#self.codeBlocks + 1] = blockDetail
                    elseif blockDetail.local_block_id == 228 then
                        -- movie blocks
                        blockDetail.block_type = 'MOVIE_BLOCKS'
                        movieBlocks[#movieBlocks + 1] = blockDetail
                        self.movieBlocks[#self.movieBlocks + 1] = blockDetail
                    else
                        -- other blocks
                        blockDetail.block_type = 'OTHER_BLOCKS'
                        otherBlocks[#otherBlocks + 1] = blockDetail
                        self.otherBlocks[#self.otherBlocks + 1] = blockDetail
                    end
                end
            end
        end

        -- count add/delete/modify

        local codeBlocksCountAdd = 0
        local codeBlocksCountDelete = 0
        local codeBlocksCountModify = 0

        for cKey, cItem in ipairs(codeBlocks) do
            if cItem and cItem.operate == 'ADD' then
                codeBlocksCountAdd = codeBlocksCountAdd + 1
            end

            if cItem and cItem.operate == 'DELETE' then
                codeBlocksCountDelete = codeBlocksCountDelete + 1
            end

            if cItem and cItem.operate == 'MODIFY' then
                codeBlocksCountModify = codeBlocksCountModify + 1
            end
        end

        local movieBlocksCountAdd = 0
        local movieBlocksCountDelete = 0
        local movieBlocksCountModify = 0

        for cKey, cItem in ipairs(movieBlocks) do
            if cItem and cItem.operate == 'ADD' then
                movieBlocksCountAdd = movieBlocksCountAdd + 1
            end

            if cItem and cItem.operate == 'DELETE' then
                movieBlocksCountDelete = movieBlocksCountDelete + 1
            end

            if cItem and cItem.operate == 'MODIFY' then
                movieBlocksCountModify = movieBlocksCountModify + 1
            end
        end

        local otherBlocksCountAdd = 0
        local otherBlocksCountDelete = 0
        local otherBlocksCountModify = 0

        for cKey, cItem in ipairs(otherBlocks) do
            if cItem and cItem.operate == 'ADD' then
                otherBlocksCountAdd = otherBlocksCountAdd + 1
            end

            if cItem and cItem.operate == 'DELETE' then
                otherBlocksCountDelete = otherBlocksCountDelete + 1
            end

            if cItem and cItem.operate == 'MODIFY' then
                otherBlocksCountModify = otherBlocksCountModify + 1
            end
        end

        item.category = 1
        item.is_show = true
        item.count_add = codeBlocksCountAdd + movieBlocksCountAdd + otherBlocksCountAdd
        item.count_delete = codeBlocksCountDelete + movieBlocksCountDelete + otherBlocksCountDelete
        item.count_modify = codeBlocksCountModify + movieBlocksCountModify + otherBlocksCountModify

        countAdd = countAdd + item.count_add
        countDelete = countDelete + item.count_delete
        countModify = countModify + item.count_modify

        self.comprehansiveList[#self.comprehansiveList + 1] = item

        if codeBlocks and #codeBlocks > 0 then
            local codeBlocksTitle = {
                category = 2,
                title = L'代码方块',
                block_type = 'CODE_BLOCKS',
                region_key = item.region_key,
                is_show = false,
                count_add = codeBlocksCountAdd,
                count_delete = codeBlocksCountDelete,
                count_modify = codeBlocksCountModify,
            }

            self.comprehansiveList[#self.comprehansiveList + 1] = codeBlocksTitle

            for key, item in ipairs(codeBlocks) do
                self.comprehansiveList[#self.comprehansiveList + 1] = item
            end
        end

        if movieBlocks and #movieBlocks > 0 then
            local movieBlocksTitle = {
                category = 2,
                title = L'电影方块',
                block_type = 'MOVIE_BLOCKS',
                region_key = item.region_key,
                is_show = false,
                count_add = movieBlocksCountAdd,
                count_delete = movieBlocksCountDelete,
                count_modify = movieBlocksCountModify,
            }

            self.comprehansiveList[#self.comprehansiveList + 1] = movieBlocksTitle
    
            for key, item in ipairs(movieBlocks) do
                self.comprehansiveList[#self.comprehansiveList + 1] = item
            end
        end

        if otherBlocks and #otherBlocks > 0 then
            local otherBlocksTitle = {
                category = 2,
                title = L'其他方块',
                block_type = 'OTHER_BLOCKS',
                region_key = item.region_key,
                is_show = false,
                count_add = otherBlocksCountAdd,
                count_delete = otherBlocksCountDelete,
                count_modify = otherBlocksCountModify,
            }

            self.comprehansiveList[#self.comprehansiveList + 1] = otherBlocksTitle
    
            for key, item in ipairs(otherBlocks) do
                self.comprehansiveList[#self.comprehansiveList + 1] = item
            end
        end
    end

    self.comprehansiveList[1].count_add = countAdd
    self.comprehansiveList[1].count_delete = countDelete
    self.comprehansiveList[1].count_modify = countModify

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
                z = block.z,
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

function DiffWorldUI:ShowCurRegionDifferent(selRegionKey)
    if not selRegionKey or type(selRegionKey) ~= 'string' then
        return
    end

    ParaTerrain.DeselectAllBlock(0)
    ParaTerrain.DeselectAllBlock(3)

    -- show current region blocks differents
    local function Handle(data)
        if data and
           type(data) == 'table' and
           #data > 0 then
            for key, item in ipairs(data) do
                if selRegionKey == item.region_key then
                    if item.operate == 'ADD' then
                        ParaTerrain.SelectBlock(item.x, item.y, item.z, true, 0)
                    elseif item.operate == 'DELETE' then
                        ParaTerrain.SelectBlock(item.x, item.y, item.z, true, 3)
                    elseif item.operate == 'MODIFY' then
                        ParaTerrain.SelectBlock(item.x, item.y, item.z, true, 0)
                    end
                end
            end
        end
    end

    Handle(self.codeBlocks)
    Handle(self.movieBlocks)
    Handle(self.otherBlocks)
end
