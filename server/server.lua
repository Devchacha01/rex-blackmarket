local RSGCore = exports['rsg-core']:GetCoreObject()
local debugMode = Config.Performance and Config.Performance.EnableDebugPrints or false

lib.locale()

-----------------------------------------------------------------
-- Utility Functions
-----------------------------------------------------------------
local function DebugPrint(message)
    if debugMode then
        print('^2[rex-blackmarket:server]^7 ' .. message)
    end
end

local function ValidatePlayer(src)
    if not src or src <= 0 then
        DebugPrint('Invalid source: ' .. tostring(src))
        return false, nil
    end
    
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then
        DebugPrint('Player not found for source: ' .. src)
        return false, nil
    end
    
    return true, Player
end

local function IsPlayerAuthorized(Player)
    if not Player or not Player.PlayerData then
        return false
    end
    
    local playerJob = Player.PlayerData.job
    if not playerJob or not playerJob.type then
        return true -- Allow if job data is missing
    end
    
    -- Check if player's job is in restricted list
    if Config.Shop and Config.Shop.RestrictedJobs then
        for _, restrictedJob in ipairs(Config.Shop.RestrictedJobs) do
            if playerJob.type == restrictedJob then
                DebugPrint('Player access denied - restricted job: ' .. playerJob.type)
                return false
            end
        end
    end
    
    return true
end

local function SendNotification(src, message, type, duration)
    TriggerClientEvent('ox_lib:notify', src, {
        title = message,
        type = type or 'inform',
        duration = duration or 5000
    })
end

-----------------------------------------------------------------
-- Money Management
-----------------------------------------------------------------
local function GetPlayerMoney(Player, moneyType)
    if not Player or not Player.PlayerData or not Player.PlayerData.money then
        return 0
    end
    
    return Player.PlayerData.money[moneyType] or 0
end

local function ValidateWashAmount(amount, playerBloodMoney, isWashAll)
    if not amount or type(amount) ~= 'number' then
        return false, 'Invalid amount type'
    end
    
    if amount < Config.Washing.MinWashAmount then
        return false, 'Amount below minimum'
    end
    
    -- Different validation for wash all vs regular wash
    if isWashAll then
        -- Check if wash all is enabled
        if not Config.Washing.AllowWashAll then
            return false, 'Wash all not allowed'
        end
        
        -- Check wash all limits
        if Config.Washing.WashAllMaxLimit and Config.Washing.WashAllMaxLimit > 0 then
            if amount > Config.Washing.WashAllMaxLimit then
                return false, 'Amount exceeds wash all limit'
            end
        end
    else
        -- Regular wash limits
        if amount > Config.Washing.MaxWash then
            return false, 'Amount exceeds maximum'
        end
    end
    
    if amount > playerBloodMoney then
        return false, 'Insufficient blood money'
    end
    
    return true
end

-----------------------------------------------------------------
-- Callbacks
-----------------------------------------------------------------
-- Get player's blood money amount
RSGCore.Functions.CreateCallback('rex-blackmarket:server:bloodmoneycallback', function(source, cb)
    local valid, Player = ValidatePlayer(source)
    if not valid then
        cb(0)
        return
    end
    
    local bloodmoney = GetPlayerMoney(Player, 'bloodmoney')
    DebugPrint('Player ' .. source .. ' has $' .. bloodmoney .. ' blood money')
    
    cb(bloodmoney)
end)

-- Get player's outlaw status
RSGCore.Functions.CreateCallback('rex-blackmarket:server:getoutlawstatus', function(source, cb)
    local valid, Player = ValidatePlayer(source)
    if not valid then
        cb(nil)
        return
    end
    
    local citizenid = Player.PlayerData.citizenid
    if not citizenid then
        DebugPrint('No citizenid found for player: ' .. source)
        cb(nil)
        return
    end
    
    MySQL.query('SELECT outlawstatus FROM players WHERE citizenid = ? LIMIT 1', {citizenid}, function(result)
        if result and result[1] then
            DebugPrint('Retrieved outlaw status for player ' .. source .. ': ' .. tostring(result[1].outlawstatus))
            cb(result)
        else
            DebugPrint('No outlaw status found for player: ' .. source)
            cb(nil)
        end
    end)
end)

-----------------------------------------------------------------
-- Events
-----------------------------------------------------------------
-- Wash blood money event with enhanced security
RegisterNetEvent('rex-blackmarket:server:washmoney', function(amount, outlawstatus, isWashAll)
    local src = source
    local valid, Player = ValidatePlayer(src)
    
    if not valid then
        DebugPrint('Invalid player attempted to wash money: ' .. tostring(src))
        return
    end
    
    -- Validate amount
    if not amount or type(amount) ~= 'number' or amount <= 0 then
        DebugPrint('Invalid wash amount from player ' .. src .. ': ' .. tostring(amount))
        SendNotification(src, 'Invalid amount specified', 'error')
        return
    end
    
    -- Default wash all to false if not provided
    isWashAll = isWashAll or false
    
    -- Get current blood money
    local playerBloodMoney = GetPlayerMoney(Player, 'bloodmoney')
    
    -- Validate wash amount
    local validAmount, reason = ValidateWashAmount(amount, playerBloodMoney, isWashAll)
    if not validAmount then
        DebugPrint('Wash validation failed for player ' .. src .. ': ' .. reason)
        SendNotification(src, 'Invalid wash amount: ' .. reason, 'error')
        return
    end
    
    -- Double-check player has sufficient blood money
    if not Player.Functions.RemoveMoney('bloodmoney', amount, 'blackmarket-wash') then
        DebugPrint('Failed to remove blood money from player ' .. src)
        SendNotification(src, 'Transaction failed - insufficient funds', 'error')
        return
    end
    
    -- Calculate clean money (percentage conversion)
    local cleanAmount = math.floor(amount * (Config.Washing.WashPercentage / 100))
    
    -- Add clean money
    Player.Functions.AddMoney('cash', cleanAmount, 'blackmarket-wash')
    
    -- Update outlaw status
    local newOutlawStatus = (outlawstatus or 0) + Config.Washing.OutlawIncrease
    local citizenid = Player.PlayerData.citizenid
    
    MySQL.update('UPDATE players SET outlawstatus = ? WHERE citizenid = ?', {
        newOutlawStatus,
        citizenid
    }, function(affectedRows)
        if affectedRows > 0 then
            DebugPrint('Updated outlaw status for player ' .. src .. ' to ' .. newOutlawStatus)
        else
            DebugPrint('Failed to update outlaw status for player ' .. src)
        end
    end)
    
    -- Log the transaction
    DebugPrint('Player ' .. src .. ' washed $' .. amount .. ' blood money into $' .. cleanAmount .. ' clean cash')
    
    -- Send success notification to client
    SendNotification(src, 'Successfully washed $' .. amount .. ' blood money', 'success')
end)

-----------------------------------------------------------------
-- Location Rotation System
-----------------------------------------------------------------
local currentActiveLocations = {}
local rotationTimer = nil

-- Initialize active locations for each blackmarket
local function InitializeActiveLocations()
    if not Config.LocationRotation or not Config.LocationRotation.Enabled then
        -- If rotation is disabled, use the first location from each blackmarket
        for _, blackmarket in ipairs(Config.BlackmarketLocations) do
            if blackmarket.rotatingLocations and #blackmarket.rotatingLocations > 0 then
                local firstLocation = blackmarket.rotatingLocations[1]
                currentActiveLocations[blackmarket.id] = {
                    id = blackmarket.id,
                    name = blackmarket.name,
                    coords = firstLocation.coords,
                    npcmodel = firstLocation.npcmodel,
                    npccoords = firstLocation.npccoords,
                    locationName = firstLocation.name,
                    blip = blackmarket.blip
                }
            end
        end
        return
    end
    
    -- Initialize with random locations for each blackmarket
    for _, blackmarket in ipairs(Config.BlackmarketLocations) do
        if blackmarket.rotatingLocations and #blackmarket.rotatingLocations > 0 then
            local randomIndex = math.random(1, #blackmarket.rotatingLocations)
            local selectedLocation = blackmarket.rotatingLocations[randomIndex]
            
            currentActiveLocations[blackmarket.id] = {
                id = blackmarket.id,
                name = blackmarket.name,
                coords = selectedLocation.coords,
                npcmodel = selectedLocation.npcmodel,
                npccoords = selectedLocation.npccoords,
                locationName = selectedLocation.name,
                blip = blackmarket.blip,
                currentLocationIndex = randomIndex
            }
            
            DebugPrint('Initialized blackmarket ' .. blackmarket.id .. ' at location: ' .. selectedLocation.name)
        end
    end
end

-- Rotate locations for all blackmarkets
local function RotateLocations()
    if not Config.LocationRotation or not Config.LocationRotation.Enabled then
        return
    end
    
    DebugPrint('Starting location rotation...')
    
    -- Notify clients that NPCs will be moving soon
    TriggerClientEvent('rex-blackmarket:client:prepareLocationChange', -1, Config.LocationRotation.FadeOutTime)
    
    -- Wait for fade out period
    Wait(Config.LocationRotation.FadeOutTime)
    
    local newLocations = {}
    
    -- Select new locations for each blackmarket
    for _, blackmarket in ipairs(Config.BlackmarketLocations) do
        if blackmarket.rotatingLocations and #blackmarket.rotatingLocations > 0 then
            local currentLocation = currentActiveLocations[blackmarket.id]
            local currentIndex = currentLocation and currentLocation.currentLocationIndex or 1
            
            -- Select next location (cycle through all available)
            local nextIndex = currentIndex + 1
            if nextIndex > #blackmarket.rotatingLocations then
                nextIndex = 1
            end
            
            local newLocation = blackmarket.rotatingLocations[nextIndex]
            
            newLocations[blackmarket.id] = {
                id = blackmarket.id,
                name = blackmarket.name,
                coords = newLocation.coords,
                npcmodel = newLocation.npcmodel,
                npccoords = newLocation.npccoords,
                locationName = newLocation.name,
                blip = blackmarket.blip,
                currentLocationIndex = nextIndex
            }
            
            DebugPrint('Rotated blackmarket ' .. blackmarket.id .. ' to location: ' .. newLocation.name)
        end
    end
    
    -- Update active locations
    currentActiveLocations = newLocations
    
    -- Notify all clients of the new locations
    TriggerClientEvent('rex-blackmarket:client:updateLocations', -1, currentActiveLocations)
    
    -- Optionally notify players about the location change
    if Config.LocationRotation.NotifyPlayers then
        CreateThread(function()
            Wait(Config.LocationRotation.NotificationDelay or 0)
            TriggerClientEvent('rex-blackmarket:client:notifyLocationChange', -1)
        end)
    end
end

-- Start the rotation timer
local function StartLocationRotation()
    if not Config.LocationRotation or not Config.LocationRotation.Enabled then
        DebugPrint('Location rotation is disabled')
        return
    end
    
    local intervalMs = (Config.LocationRotation.RotationInterval or 60) * 60000 -- Convert minutes to milliseconds
    DebugPrint('Starting location rotation timer with interval: ' .. (intervalMs / 60000) .. ' minutes')
    
    rotationTimer = SetInterval(function()
        RotateLocations()
    end, intervalMs)
end

-- Stop the rotation timer
local function StopLocationRotation()
    if rotationTimer then
        ClearInterval(rotationTimer)
        rotationTimer = nil
        DebugPrint('Location rotation timer stopped')
    end
end

-- Get current active locations callback
RSGCore.Functions.CreateCallback('rex-blackmarket:server:getActiveLocations', function(source, cb)
    cb(currentActiveLocations)
end)

-- Manual rotation command (for testing/admin use)
RegisterCommand('rex_rotate_locations', function(source, args, rawCommand)
    if source ~= 0 then -- Only allow from server console
        return
    end
    
    print('^3[rex-blackmarket] Manual location rotation triggered^7')
    RotateLocations()
end, true)

-----------------------------------------------------------------
-- Shop Management
-----------------------------------------------------------------
-- Initialize blackmarket shop
local function InitializeShop()
    if not Config.Shop or not Config.Shop.Items then
        DebugPrint('No shop items configured')
        return
    end
    
    local success, err = pcall(function()
        exports['rsg-inventory']:CreateShop({
            name = 'blackmarket',
            label = 'Blackmarket Shop',
            slots = #Config.Shop.Items,
            items = Config.Shop.Items,
            persistentStock = Config.Shop.PersistStock,
        })
    end)
    
    if success then
        DebugPrint('Blackmarket shop initialized successfully')
    else
        print('^1[rex-blackmarket] ERROR: Failed to initialize shop: ' .. tostring(err) .. '^7')
    end
end

-- Shop access event
RegisterNetEvent('rex-blackmarket:server:openShop', function()
    local src = source
    local valid, Player = ValidatePlayer(src)
    
    if not valid then
        DebugPrint('Invalid player attempted to open shop: ' .. tostring(src))
        return
    end
    
    -- Check if player is authorized
    if not IsPlayerAuthorized(Player) then
        DebugPrint('Unauthorized player attempted to access shop: ' .. src)
        SendNotification(src, 'Access denied - you cannot use this service', 'error')
        return
    end
    
    -- Open the shop
    local success, err = pcall(function()
        exports['rsg-inventory']:OpenShop(src, 'blackmarket')
    end)
    
    if success then
        DebugPrint('Player ' .. src .. ' opened blackmarket shop')
    else
        DebugPrint('Failed to open shop for player ' .. src .. ': ' .. tostring(err))
        SendNotification(src, 'Failed to open shop', 'error')
    end
end)

-- Initialize shop and location rotation on resource start
CreateThread(function()
    -- Small delay to ensure all dependencies are loaded
    Wait(2000)
    InitializeShop()
    
    -- Initialize location rotation system
    InitializeActiveLocations()
    StartLocationRotation()
end)

-- Handle resource stopping
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    DebugPrint('Resource stopping, cleaning up location rotation...')
    StopLocationRotation()
end)



