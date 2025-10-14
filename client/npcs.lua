local RSGCore = exports['rsg-core']:GetCoreObject()
local spawnedPeds = {}
local isNPCSystemActive = true
local debugMode = Config.Performance and Config.Performance.EnableDebugPrints or false
local updateInterval = Config.Performance and Config.Performance.NPCUpdateInterval or 500
local currentActiveLocations = {}
local isLocationChangeInProgress = false

-----------------------------------------------------------------
-- Utility Functions
-----------------------------------------------------------------
local function DebugPrint(message)
    if debugMode then
        print('^3[rex-blackmarket:npcs]^7 ' .. message)
    end
end

local function IsValidPed(ped)
    return ped and DoesEntityExist(ped) and not IsEntityDead(ped)
end

local function SafeDeletePed(ped)
    if IsValidPed(ped) then
        DeletePed(ped)
        return true
    end
    return false
end

-----------------------------------------------------------------
-- Fade Effects
-----------------------------------------------------------------
local function FadeInPed(ped)
    if not Config.NPC.FadeIn or not IsValidPed(ped) then
        return
    end
    
    CreateThread(function()
        for alpha = 0, 255, Config.NPC.FadeSpeed do
            if not IsValidPed(ped) then break end
            SetEntityAlpha(ped, alpha, false)
            Wait(50)
        end
        
        if IsValidPed(ped) then
            SetEntityAlpha(ped, 255, false)
        end
    end)
end

local function FadeOutPed(ped, callback)
    if not Config.NPC.FadeIn or not IsValidPed(ped) then
        if callback then callback() end
        return
    end
    
    CreateThread(function()
        for alpha = 255, 0, -Config.NPC.FadeSpeed do
            if not IsValidPed(ped) then break end
            SetEntityAlpha(ped, alpha, false)
            Wait(50)
        end
        
        if callback then callback() end
    end)
end

-----------------------------------------------------------------
-- NPC Management System
-----------------------------------------------------------------
local function GetPlayerCoords()
    return GetEntityCoords(cache.ped)
end

local function ProcessNPCLocation(index, location)
    local playerCoords = GetPlayerCoords()
    local distance = #(playerCoords - location.npccoords.xyz)
    local spawnDistance = Config.NPC.DistanceSpawn
    local locationId = location.id or tostring(index)
    
    -- Check if we should spawn the NPC
    if distance < spawnDistance and not spawnedPeds[locationId] then
        DebugPrint('Spawning NPC for location: ' .. location.name)
        local spawnedPed = CreateBlackmarketNPC(location)
        
        if spawnedPed then
            spawnedPeds[locationId] = {
                ped = spawnedPed,
                location = location,
                spawnTime = GetGameTimer()
            }
        end
    end
    
    -- Check if we should despawn the NPC
    if distance >= spawnDistance and spawnedPeds[locationId] then
        DebugPrint('Despawning NPC for location: ' .. location.name)
        local pedData = spawnedPeds[locationId]
        
        if IsValidPed(pedData.ped) then
            FadeOutPed(pedData.ped, function()
                SafeDeletePed(pedData.ped)
            end)
        end
        
        spawnedPeds[locationId] = nil
    end
end

-- Main NPC management thread
CreateThread(function()
    DebugPrint('Starting NPC management system')
    
    -- Request current active locations from server
    RSGCore.Functions.TriggerCallback('rex-blackmarket:server:getActiveLocations', function(activeLocations)
        currentActiveLocations = activeLocations or {}
        DebugPrint('Received initial active locations from server')
    end)
    
    while isNPCSystemActive do
        Wait(updateInterval)
        
        if not cache.ped or not DoesEntityExist(cache.ped) or isLocationChangeInProgress then
            goto continue
        end
        
        -- Process active locations instead of config locations
        for locationId, location in pairs(currentActiveLocations) do
            if location.npccoords and location.npcmodel then
                ProcessNPCLocation(locationId, location)
            end
        end
        
        ::continue::
    end
    
    DebugPrint('NPC management system stopped')
end)

-----------------------------------------------------------------
-- NPC Creation and Setup
-----------------------------------------------------------------
local function LoadModel(model, timeout)
    timeout = timeout or 10000 -- 10 second timeout
    local startTime = GetGameTimer()
    
    RequestModel(model)
    
    while not HasModelLoaded(model) do
        if GetGameTimer() - startTime > timeout then
            DebugPrint('Failed to load model: ' .. tostring(model))
            return false
        end
        Wait(50)
    end
    
    return true
end

local function SetupNPCProperties(ped)
    if not IsValidPed(ped) then return false end
    
    -- Basic properties
    SetRandomOutfitVariation(ped, true)
    SetEntityCanBeDamaged(ped, false)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCanBeTargetted(ped, false)
    SetPedFleeAttributes(ped, 0, false)
    
    -- Collision and physics
    SetEntityCollision(ped, true, true)
    SetEntityLoadCollisionFlag(ped, true)
    
    return true
end

local function AddNPCTargeting(ped, location)
    if not IsValidPed(ped) then return false end
    
    local success, err = pcall(function()
        exports.ox_target:addLocalEntity(ped, {
            {
                name = 'npc_blackmarket_' .. (location.id or 'unknown'),
                icon = 'far fa-eye',
                label = locale('cl_lang_1'),
                onSelect = function()
                    TriggerEvent('rex-blackmarket:client:mainmenu')
                end,
                distance = Config.NPC.InteractionDistance or 3.0
            }
        })
    end)
    
    if not success then
        DebugPrint('Failed to add targeting to NPC: ' .. tostring(err))
        return false
    end
    
    return true
end

function CreateBlackmarketNPC(location)
    if not location or not location.npcmodel or not location.npccoords then
        DebugPrint('Invalid location data for NPC creation')
        return nil
    end
    
    -- Load the model
    if not LoadModel(location.npcmodel) then
        return nil
    end
    
    -- Create the ped
    local coords = location.npccoords
    local ped = CreatePed(location.npcmodel, coords.x, coords.y, coords.z - 1.0, coords.w, false, false, 0, 0)
    
    if not IsValidPed(ped) then
        DebugPrint('Failed to create NPC for location: ' .. location.name)
        SetModelAsNoLongerNeeded(location.npcmodel)
        return nil
    end
    
    -- Set initial alpha for fade effect
    SetEntityAlpha(ped, Config.NPC.FadeIn and 0 or 255, false)
    
    -- Setup NPC properties
    if not SetupNPCProperties(ped) then
        SafeDeletePed(ped)
        SetModelAsNoLongerNeeded(location.npcmodel)
        return nil
    end
    
    -- Add targeting
    if not AddNPCTargeting(ped, location) then
        SafeDeletePed(ped)
        SetModelAsNoLongerNeeded(location.npcmodel)
        return nil
    end
    
    -- Start fade in effect
    FadeInPed(ped)
    
    -- Clean up model
    SetModelAsNoLongerNeeded(location.npcmodel)
    
    DebugPrint('Successfully created NPC for location: ' .. location.name)
    return ped
end

-----------------------------------------------------------------
-- Cleanup Functions
-----------------------------------------------------------------
local function CleanupAllNPCs()
    DebugPrint('Cleaning up all NPCs...')
    
    for locationId, pedData in pairs(spawnedPeds) do
        if IsValidPed(pedData.ped) then
            -- Remove targeting first
            pcall(function()
                exports.ox_target:removeLocalEntity(pedData.ped)
            end)
            
            -- Delete the ped
            SafeDeletePed(pedData.ped)
            DebugPrint('Cleaned up NPC for location: ' .. locationId)
        end
    end
    
    spawnedPeds = {}
    DebugPrint('All NPCs cleaned up')
end

local function StopNPCSystem()
    DebugPrint('Stopping NPC system...')
    isNPCSystemActive = false
    CleanupAllNPCs()
end

local function StartNPCSystem()
    DebugPrint('Starting NPC system...')
    isNPCSystemActive = true
end

-----------------------------------------------------------------
-- Resource Event Handlers
-----------------------------------------------------------------
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    StopNPCSystem()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    StartNPCSystem()
end)

-- Handle player disconnect/reconnect scenarios
RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    DebugPrint('Player loaded, ensuring NPC system is active')
    if not isNPCSystemActive then
        StartNPCSystem()
    end
end)

RegisterNetEvent('RSGCore:Client:OnPlayerUnload', function()
    DebugPrint('Player unloaded, cleaning up NPCs')
    CleanupAllNPCs()
end)

-----------------------------------------------------------------
-- Location Update System
-----------------------------------------------------------------
local function CleanupSpecificNPC(locationId)
    if spawnedPeds[locationId] then
        local pedData = spawnedPeds[locationId]
        
        if IsValidPed(pedData.ped) then
            -- Remove targeting first
            pcall(function()
                exports.ox_target:removeLocalEntity(pedData.ped)
            end)
            
            -- Delete the ped
            SafeDeletePed(pedData.ped)
            DebugPrint('Cleaned up NPC for location: ' .. locationId)
        end
        
        spawnedPeds[locationId] = nil
    end
end

local function PrepareLocationChange(fadeOutTime)
    DebugPrint('Preparing for location change...')
    isLocationChangeInProgress = true
    
    -- Fade out all current NPCs
    for locationId, pedData in pairs(spawnedPeds) do
        if IsValidPed(pedData.ped) then
            FadeOutPed(pedData.ped, function()
                CleanupSpecificNPC(locationId)
            end)
        else
            CleanupSpecificNPC(locationId)
        end
    end
    
    -- Wait for fade out to complete
    CreateThread(function()
        Wait(fadeOutTime or 5000)
        isLocationChangeInProgress = false
        DebugPrint('Location change preparation complete')
    end)
end

local function UpdateActiveLocations(newActiveLocations)
    DebugPrint('Updating active locations...')
    
    -- Clean up NPCs that are no longer at active locations
    for locationId, pedData in pairs(spawnedPeds) do
        if not newActiveLocations[locationId] then
            CleanupSpecificNPC(locationId)
        end
    end
    
    -- Update the current active locations
    currentActiveLocations = newActiveLocations or {}
    
    DebugPrint('Active locations updated')
end

-- Event handler for location change preparation
RegisterNetEvent('rex-blackmarket:client:prepareLocationChange', function(fadeOutTime)
    PrepareLocationChange(fadeOutTime)
end)

-- Event handler for location updates
RegisterNetEvent('rex-blackmarket:client:updateLocations', function(newActiveLocations)
    UpdateActiveLocations(newActiveLocations)
end)

-- Event handler for location change notifications
RegisterNetEvent('rex-blackmarket:client:notifyLocationChange', function()
    lib.notify({
        title = locale('cl_lang_location_moved') or 'Black Market Moved',
        description = locale('cl_lang_location_moved_desc') or 'The black market dealers have relocated. Check your map for new locations.',
        type = 'inform',
        duration = 10000,
        position = 'top'
    })
end)

-----------------------------------------------------------------
-- Debug Commands (only in debug mode)
-----------------------------------------------------------------
if debugMode then
    RegisterCommand('rex_npc_debug', function()
        print('^3[rex-blackmarket:npcs] Debug Info:^7')
        print('Active NPCs: ' .. CountTable(spawnedPeds))
        print('System Active: ' .. tostring(isNPCSystemActive))
        print('Update Interval: ' .. updateInterval .. 'ms')
        
        for locationId, pedData in pairs(spawnedPeds) do
            local isValid = IsValidPed(pedData.ped)
            local coords = isValid and GetEntityCoords(pedData.ped) or 'N/A'
            print('Location: ' .. locationId .. ', Valid: ' .. tostring(isValid) .. ', Coords: ' .. tostring(coords))
        end
    end, false)
    
    RegisterCommand('rex_npc_cleanup', function()
        print('^3[rex-blackmarket:npcs] Manual cleanup triggered^7')
        CleanupAllNPCs()
    end, false)
end

-- Utility function for debug
function CountTable(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end
