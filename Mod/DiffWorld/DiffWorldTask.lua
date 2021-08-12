--[[
Title: Diff World Task
Author(s):  big, wxa
CreateDate: 2020.06.12
UpdateDate: 2021.08.09
Desc: DiffWorldTask
use the lib:
------------------------------------------------------------
local DiffWorldTask = NPL.load('(gl)Mod/DiffWorld/DiffWorldTask.lua')
------------------------------------------------------------
]]

-- libs
local BlockEngine = commonlib.gettable('MyCompany.Aries.Game.BlockEngine')
local CommandManager = commonlib.gettable('MyCompany.Aries.Game.CommandManager')
local SlashCommand = commonlib.gettable('MyCompany.Aries.SlashCommand.SlashCommand')
local lfs = commonlib.Files.GetLuaFileSystem()
local CommonLib = NPL.load('Mod/GeneralGameServerMod/CommonLib/CommonLib.lua')
local Page = NPL.load('Mod/GeneralGameServerMod/UI/Page.lua', IsDevEnv)
local RPCVirtualConnection = NPL.load('Mod/GeneralGameServerMod/CommonLib/RPCVirtualConnection.lua', IsDevEnv)

-- service
local KeepworkServiceProject = NPL.load('(gl)Mod/WorldShare/service/KeepworkService/Project.lua')
local GitService = NPL.load('(gl)Mod/WorldShare/service/GitService.lua')
local LocalService = NPL.load('(gl)Mod/WorldShare/service/LocalService.lua')

local __rpc__ = commonlib.inherit(RPCVirtualConnection, {})
local __neuron_file__ = 'Mod/DiffWorld/DiffWorldTask.lua'
__rpc__:Property('RemoteNeuronFile', __neuron_file__) -- 对端处理文件
__rpc__:Property('LocalNeuronFile', __neuron_file__) -- 本地处理文件
CommonLib.AddPublicFile(__neuron_file__)
__rpc__:InitSingleton()

local DiffWorldTask = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), NPL.export())

local RegionSize = 512
local ChunkSize = 16

DiffWorldTask:Property("Local", true, "IsLocal")

function DiffWorldTask:ctor()
    self:Reset()
end

function DiffWorldTask:Reset()
    self.__regions__ = {}
    self.__diffs__ = {__regions__ = {}}
end

function DiffWorldTask:DownloadWorldById(pid, callback)
    local currentEnterWorld = GameLogic.GetFilters():apply_filters('store_get', 'world/currentEnterWorld')

    if not pid or type(pid) ~= 'number' then
        if currentEnterWorld and type(currentEnterWorld) == 'table' then
            pid = currentEnterWorld.kpProjectId
        end
    end

    KeepworkServiceProject:GetProject(pid, function(data, err)
        if not data or
           type(data) ~= 'table' or
           not data.name or
           not data.username or
           not data.world or
           not data.world.commitId then
            if callback and type(callback) == 'function' then
                callback(false)
            end

            return
        end

        GitService:DownloadZIP(
            data.name,
            data.username,
            data.world.commitId,
            function(bSuccess, downloadPath)
                if not bSuccess then
                    if callback and type(callback) == 'function' then
                        callback(false)
                    end

                    return
                end

                local tempDiffWorldDirectory = 'temp/diff_world/'

                -- clear old files
                ParaIO.DeleteFile(tempDiffWorldDirectory)
                ParaIO.CreateDirectory(tempDiffWorldDirectory)

                LocalService:MoveZipToFolder(
                    tempDiffWorldDirectory,
                    downloadPath,
                    function()
                        -- 次函数无出错处理 可能产生未知情况 
                        for filename in lfs.dir(tempDiffWorldDirectory) do
                            if (filename ~= "." and filename ~= "..") then
                                local worldPath = tempDiffWorldDirectory .. filename

                                if callback and type(callback) == 'function' then
                                    callback(true, worldPath)
                                end

                                return
                            end
                        end
                    end
                )
            end
        )
    end)
end

function DiffWorldTask:IsRemoteWorld()
    local world_directory = ParaWorld.GetWorldDirectory();
    return string.find(world_directory, "temp/diff_world/", 1, true);
end

function DiffWorldTask:GetRegion(key)
    self.__regions__[key] = self.__regions__[key] or {}
    return self.__regions__[key]
end

function DiffWorldTask:IsExistRegion(key)
    return self.__regions__[key] ~= nil;
end

function DiffWorldTask:UseSyncChunkMode()
    CommandManager:RunCommand("/property AsyncChunkMode false")
    CommandManager:RunCommand("/property UseAsyncLoadWorld false")
end

function DiffWorldTask:LoadRegion(x, y, z)
    ParaBlockWorld.LoadRegion(GameLogic.GetBlockWorld(), x, y or 4, z)
end

-- 获取所有区域信息
function DiffWorldTask:LoadAllRegionInfo()
    local directory = CommonLib.ToCanonicalFilePath(ParaWorld.GetWorldDirectory() .. '/blockWorld.lastsave')
    local entities = {}

    ParaIO.CreateDirectory(directory)

    for filename in lfs.dir(directory) do
        if string.match(filename, "%d+_%d+%.raw") then
            local region_x, region_z = string.match(filename, "(%d+)_(%d+)%.raw")
            local region_key = string.format("%s_%s", region_x, region_z)
            local region = self:GetRegion(region_key)

            region.region_key = region_key
            region.region_x, region.region_z = tonumber(region_x), tonumber(region_z)
            region.block_x, region.block_z = region.region_x * RegionSize, region.region_z * RegionSize
            region.rawpath = CommonLib.ToCanonicalFilePath(directory .. "/" .. filename)
        elseif string.match(filename, "%d+_%d+%.region%.xml") then
            local region_key = string.match(filename, "(%d+_%d+)%.region%.xml")
            table.insert(entities, {region_key = region_key, xmlpath = CommonLib.ToCanonicalFilePath(directory .. "/" .. filename)})
        end
    end

    for _, entity in ipairs(entities) do
        self:GetRegion(entity.region_key).xmlpath = entity.xmlpath
    end

    for _, region in pairs(self.__regions__) do
        region.rawmd5 = CommonLib.GetFileMD5(region.rawpath)
        region.xmlmd5 = CommonLib.GetFileMD5(region.xmlpath)
    end

    return self.__regions__
end

function DiffWorldTask:Register(...)
    __rpc__:Register(...)
end

function DiffWorldTask:Call(...)
    __rpc__:Call(...)
end

function DiffWorldTask:LoadRegion(region)
    CommandManager:RunCommand("/loadregion %s %s %s", region.block_x, 5, region.block_z);
end

function DiffWorldTask:StartServer(ip, port)
    CommonLib.StartNetServer(ip, port)

    self:UseSyncChunkMode()
    self:Reset()
    self:LoadAllRegionInfo()

    -- server 端为Local数据
    self:SetLocal(true)
end

function DiffWorldTask:StartClient(ip, port)
    __rpc__:SetNid(CommonLib.AddNPLRuntimeAddress(ip, port))

    self:UseSyncChunkMode()
    self:Reset()
    self:LoadAllRegionInfo()
    self:SetLocal(false)

    local key, region, diff_regions = nil, nil, {}

    local function NextDiffRegionInfo()
        key, region = next(self.__regions__, key);

        if not region then 
            return self:Call('DiffWorldFinish', nil, function(data)
                self:DiffFinish(data);
            end)
        end 

        if (region.is_equal_rawmd5 and region.is_equal_xmlmd5) then 
            -- 完全一致 比较下一个区域
            NextDiffRegionInfo();
        else
            print(string.format("diff region: %s, is_equal_rawmd5 = %s, is_equal_xmlmd5 = %s", region.region_key, region.is_equal_rawmd5, region.is_equal_xmlmd5));
            -- entity 或 block 不同
            self:DiffRegionChunkInfo(region, function()
                -- 对比完成
                NextDiffRegionInfo();
            end);
        end
    end

    self:Call('DiffWorldStart', self.__regions__, function(remote_regions)
        self:MergeRegion(remote_regions)

        NextDiffRegionInfo()
    end)
end

function DiffWorldTask:MergeRegion(regions)
    for key, data in pairs(regions) do
        local region = self.__regions__[key]

        if not region then
            region = self:GetRegion(key)
            commonlib.partialcopy(region, data)
            region.rawmd5, region.xmlmd5 = nil, nil
        end

        region.is_equal_rawmd5 = region.rawmd5 == data.rawmd5
        region.is_equal_xmlmd5 = region.xmlmd5 == data.xmlmd5
    end
end

-- 对比chunk
function DiffWorldTask:DiffRegionChunkInfo(region, callback)
    local local_chunks = self:LoadRegionChunkInfo(region)
    local remote_chunks = nil
    local chunk_key, local_chunk = nil, nil

    local function NextDiffRegionChunkInfo()
        chunk_key, local_chunk = next(local_chunks, chunk_key)

        if not local_chunk then
            return type(callback) == 'function' and callback()
        end

        local remote_chunk = remote_chunks[chunk_key] or {}

        if local_chunk.chunk_md5 == remote_chunk.chunk_md5 then
            NextDiffRegionChunkInfo()
        else
            self:DiffRegionChunkBlockInfo(local_chunk, function()
                NextDiffRegionChunkInfo()
            end)
        end
    end

    -- 保证两个世界chunk生成是一致的
    local data = {region_key = region.region_key, chunk_generates = {}}

    for chunk_key, chunk in pairs(local_chunks) do
        data.chunk_generates[chunk_key] = chunk.is_generate
    end

    self:Call("DiffRegionChunkInfo", data, function(chunks)
        remote_chunks = chunks

        for chunk_key, remote_chunk in pairs(remote_chunks) do
            local local_chunk = local_chunks[chunk_key]

            if not local_chunk.is_generate and remote_chunk.is_generate then
                self:GenerateChunk(local_chunk.chunk_x, local_chunk.chunk_z)

                local chunk_v = ParaTerrain.GetMapChunkData(local_chunk.chunk_x, local_chunk.chunk_z, false, 0xffff)
                local_chunk.chunk_md5 = CommonLib.MD5(chunk_v)
            end
        end

        NextDiffRegionChunkInfo()
    end)
end

function DiffWorldTask:IsGenerateChunk(chunk_x, chunk_z)
    local real_chunk = GameLogic.GetWorld():GetChunk(chunk_x, chunk_z, true)

    return  (real_chunk and real_chunk:GetTimeStamp() > 0) and true or false;
end

function DiffWorldTask:GenerateChunk(chunk_x, chunk_z)
    if self:IsGenerateChunk(chunk_x, chunk_z) then
        return
    end

    local chunk = GameLogic.GetWorld():GetChunk(chunk_x, chunk_z, true)

    GameLogic.GetBlockGenerator():GenerateChunk(chunk, chunk_x, chunk_z, true)
end

function DiffWorldTask:LoadRegionChunkInfo(region, chunk_generates)
    self:LoadRegion(region)

    local size = RegionSize / ChunkSize
    region.chunks = region.chunks or {}

    for i = 0, 31 do
        for j = 0, 31 do
            local chunk_x, chunk_z = region.region_x * size + i, region.region_z * size + j
            local chunk_key = string.format("%s_%s", chunk_x, chunk_z)

            if chunk_generates and chunk_generates[chunk_key] then
                self:GenerateChunk(chunk_x, chunk_z)
            end

            local is_generate = self:IsGenerateChunk(chunk_x, chunk_z)
            local chunk_v = (is_generate) and (ParaTerrain.GetMapChunkData(chunk_x, chunk_z, false, 0xffff)) or ''
            local chunk_md5 = CommonLib.MD5(chunk_v)
            local chunk = region.chunks[chunk_key] or {}

            region.chunks[chunk_key] = chunk
            chunk.chunk_x, chunk.chunk_z, chunk.chunk_md5, chunk.chunk_key = chunk_x, chunk_z, chunk_md5, chunk_key
            chunk.is_equal_rawmd5, chunk.is_equal_xmlmd5, chunk.region_key = region.is_equal_rawmd5, region.is_equal_xmlmd5, region.region_key
            chunk.is_generate = is_generate
        end
    end

    return region.chunks
end

-- 对比方块信息
function DiffWorldTask:DiffRegionChunkBlockInfo(chunk, callback)
    local blocks = self:LoadRegionChunkBlockInfo(chunk)

    self:Call("DiffRegionChunkBlockInfo", {chunk = chunk, blocks = blocks}, function()
        return type(callback) == "function" and callback()
    end);
end

function DiffWorldTask:LoadRegionChunkBlockInfo(chunk)
    local is_equal_rawmd5, is_equal_xmlmd5 = chunk.is_equal_rawmd5, chunk.is_equal_xmlmd5
    local start_x, start_y = chunk.chunk_x * ChunkSize, chunk.chunk_z * ChunkSize
    local blocks = {}

    for i = 0, 15 do
        for j = 0, 15 do
            local x, z = start_x + i, start_y + j;
            for y = -128, 128 do
                local index = BlockEngine:GetSparseIndex(x, y, z)
                local block_id, block_data, entity_data = BlockEngine:GetBlockFull(x, y, z)

                -- 无实体数据且方块相同则不同步
                if block_id and block_id ~= 0 then
                    entity_data = entity_data and commonlib.serialize_compact(entity_data)
                    local entity_data_md5 = entity_data and CommonLib.MD5(entity_data)

                    if not is_equal_rawmd5 or entity_data then
                        blocks[index] = {
                            block_id = block_id,
                            block_data = block_data,
                            entity_data = entity_data,
                            entity_data_md5 = entity_data_md5
                        }
                    end
                end
            end
        end
    end

    return blocks
end

-- 响应方块比较
DiffWorldTask:Register("DiffRegionChunkBlockInfo", function(data)
    local self = DiffWorldTask
    local chunk, remote_blocks = data.chunk, data.blocks
    local local_blocks = self:LoadRegionChunkBlockInfo(chunk)
    local region_key, chunk_key = chunk.region_key, chunk.chunk_key
    local __regions__ = self.__diffs__.__regions__
    local diff_region = __regions__[region_key] or {}
    __regions__[region_key] = diff_region
    local diff_region_chunk = diff_region[chunk_key] or {}
    diff_region[chunk_key] = diff_region_chunk

    for block_index, remote_block in pairs(remote_blocks) do
        local local_block = local_blocks[block_index]

        if not local_block or
           local_block.block_id ~= remote_block.block_id or
           local_block.block_data ~= remote_block.block_data or
           local_block.entity_data_md5 ~= remote_block.entity_data_md5 then
            local x, y, z = BlockEngine:FromSparseIndex(block_index)

            diff_region_chunk[block_index] = {
                x = x, y = y, z = z,
                remote_block_id = remote_block.block_id,
                remote_block_data = remote_block.block_data,
                remote_entity_data = remote_block.entity_data,
                local_block_id = local_block and local_block.block_id,
                local_block_data = local_block and local_block.block_data,
                local_entity_data = local_block and local_block.entity_data,
            }
        end
    end

    for block_index, local_block in pairs(local_blocks) do
        if not remote_blocks[block_index] then
            local x, y, z = BlockEngine:FromSparseIndex(block_index)

            diff_region_chunk[block_index] = {
                x = x, y = y, z = z,
                local_block_id = local_block.block_id,
                local_block_data = local_block.block_data,
                local_entity_data = local_block.entity_data,
            }
        end
    end

    return
end)

function DiffWorldTask:DiffFinish(__diffs__)
    local __is_local__ = self:IsLocal()
    local __regions__ = __diffs__.__regions__
    local __region_count__ = 0
    local __chunk_count__ = 0
    local __block_count__ = 0

    for _, region in pairs(__regions__) do
        __region_count__ = __region_count__ + 1

        local chunk_count = 0

        for _, chunk in pairs(region) do
            chunk_count = chunk_count + 1

            for _, block in pairs(chunk) do
                __block_count__ = __block_count__ + 1
            end
        end

        __chunk_count__ = __chunk_count__ + chunk_count
    end

    if not self:IsRemoteWorld() then
        Page.Show({
            __is_local__ = __is_local__,
            __diffs__ = __diffs__,
        }, {
            url = '%ggs%/Command/DiffWorld/DiffWorldUI.html',
            alignment = '_lt',
            width = 500,
            height = '100%',
        })
    end
end

NPL.this(function()
    __rpc__:OnActivate(msg)
end);
