local RSGCore = exports['rsg-core']:GetCoreObject()
local spawnedBlackmarketBlips = {}
local isWashing = false
local debugMode = Config.Performance and Config.Performance.EnableDebugPrints or false
local currentActiveLocations = {}

lib.locale()

-----------------------------------------------------------------
-- Utility Functions
-----------------------------------------------------------------
local function DebugPrint(message)
    if debugMode then
        print('^3[rex-blackmarket:client]^7 ' .. message)
    end
end

local function ShowNotification(message, type, duration)
    lib.notify({
        title = message,
        type = type or 'inform',
        duration = duration or 5000
    })
end

local function IsPlayerBusy()
    return LocalPlayer.state.inv_busy or isWashing
end

local function SetPlayerBusy(busy)
    LocalPlayer.state:set("inv_busy", busy, true)
    isWashing = busy
end

-----------------------------------------------------------------
-- Blip Management
-----------------------------------------------------------------
local function CreateBlackmarketBlips()
    DebugPrint('Creating blackmarket blips...')
    
    -- Use current active locations instead of config locations
    for locationId, location in pairs(currentActiveLocations) do
        if location.blip and location.blip.show then
            local blipName = location.name .. ' - ' .. (location.locationName or 'Unknown')
            local blip = BlipAddForCoords(1664425300, location.coords)
            if blip and blip ~= 0 then
                SetBlipSprite(blip, joaat(location.blip.sprite), true)
                SetBlipScale(blip, location.blip.scale)
                SetBlipName(blip, blipName)
                
                spawnedBlackmarketBlips[locationId] = blip
                DebugPrint('Created blip for location: ' .. blipName)
            else
                print('^1[rex-blackmarket] ERROR: Failed to create blip for location: ' .. blipName .. '^7')
            end
        end
    end
end

local function RemoveBlackmarketBlips()
    DebugPrint('Removing blackmarket blips...')
    
    for locationId, blip in pairs(spawnedBlackmarketBlips) do
        if blip and blip ~= 0 then
            RemoveBlip(blip)
            DebugPrint('Removed blip for location: ' .. locationId)
        end
    end
    
    spawnedBlackmarketBlips = {}
end

-- Initialize blips after getting active locations from server
CreateThread(function()
    -- Wait a moment for the resource to fully load
    Wait(1000)
    
    -- Get current active locations from server
    RSGCore.Functions.TriggerCallback('rex-blackmarket:server:getActiveLocations', function(activeLocations)
        currentActiveLocations = activeLocations or {}
        DebugPrint('Received active locations for blips')
        CreateBlackmarketBlips()
    end)
end)

-----------------------------------------------------------------
-- Blood Money Washing Functions
-----------------------------------------------------------------
local function ValidateWashInput(input, bloodmoney, isWashAll)
    local amount
    
    -- Handle different input types
    if type(input) == 'table' and input[1] then
        amount = tonumber(input[1])
    elseif type(input) == 'number' then
        amount = input
    else
        return false, 'Invalid input'
    end
    
    if not amount then
        return false, 'Amount must be a number'
    end
    
    if amount < Config.Washing.MinWashAmount then
        return false, locale('cl_lang_min_wash') or ('Minimum wash amount is $' .. Config.Washing.MinWashAmount)
    end
    
    -- Different limits for wash all vs regular wash
    if isWashAll then
        -- Check wash all limits
        if Config.Washing.WashAllMaxLimit and Config.Washing.WashAllMaxLimit > 0 then
            if amount > Config.Washing.WashAllMaxLimit then
                return false, locale('cl_lang_wash_all_limit') or ('Wash all limit is $' .. Config.Washing.WashAllMaxLimit)
            end
        end
    else
        -- Check regular wash limits
        if amount > Config.Washing.MaxWash then
            return false, locale('cl_lang_10') .. Config.Washing.MaxWash
        end
    end
    
    if bloodmoney < amount then
        return false, locale('cl_lang_9')
    end
    
    return true, amount
end

local function StartWashingProcess(amount, outlawstatus, isWashAll)
    DebugPrint('Starting washing process for amount: $' .. amount .. (isWashAll and ' (wash all)' or ''))
    
    local washTime = Config.Washing.WashTime * amount
    local progressLabel = locale('cl_lang_8') .. ' ($' .. amount .. ')'
    
    if isWashAll then
        progressLabel = locale('cl_lang_wash_all_progress') or ('Washing All Blood Money ($' .. amount .. ')')
    end
    
    local success = lib.progressBar({
        duration = washTime,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disableControl = true,
        disable = { move = true, mouse = true },
        anim = {
            dict = 'mech_inventory@crafting@fallbacks',
            clip = 'full_craft_and_stow',
            flag = 27
        },
        label = progressLabel,
    })
    
    if success then
        DebugPrint('Washing completed successfully')
        
        -- Check for law alert
        if Config.LawAlert.Active and math.random(100) <= Config.LawAlert.Chance then
            DebugPrint('Triggering law alert')
            local coords = GetEntityCoords(cache.ped)
            TriggerEvent('rsg-lawman:client:lawmanAlert', coords, locale('cl_lang_11'))
        end
        
        -- Process the wash on server
        TriggerServerEvent('rex-blackmarket:server:washmoney', amount, outlawstatus, isWashAll)
        
        -- Calculate and show earnings
        local cleanMoney = math.floor(amount * (Config.Washing.WashPercentage / 100))
        local successMessage = isWashAll and 
            locale('cl_lang_wash_all_success') or 
            locale('cl_lang_wash_success')
        
        ShowNotification(
            successMessage or ('Washed $' .. amount .. ' blood money into $' .. cleanMoney .. ' clean cash'),
            'success',
            7000
        )
    else
        DebugPrint('Washing was cancelled')
        ShowNotification(locale('cl_lang_wash_cancelled') or 'Washing cancelled', 'error')
    end
end

-- Wash a specific amount of blood money
local function WashBloodMoneyAmount(amount, isWashAll)
    if IsPlayerBusy() then
        ShowNotification(locale('cl_lang_busy') or 'You are currently busy', 'error')
        return
    end
    
    if not amount or amount <= 0 then
        ShowNotification(locale('cl_lang_invalid_amount') or 'Invalid amount', 'error')
        return
    end
    
    -- Store wash type for validation
    isWashAll = isWashAll or false
    
    SetPlayerBusy(true)
    DebugPrint('Washing specific amount: $' .. amount)
    
    -- Get current blood money to validate
    RSGCore.Functions.TriggerCallback('rex-blackmarket:server:bloodmoneycallback', function(bloodmoney)
        if not bloodmoney or bloodmoney <= 0 then
            ShowNotification(locale('cl_lang_no_bloodmoney') or 'You have no blood money', 'error')
            SetPlayerBusy(false)
            return
        end
        
        -- Validate the amount
        local valid, result = ValidateWashInput(amount, bloodmoney, isWashAll)
        if not valid then
            ShowNotification(result, 'error', 7000)
            SetPlayerBusy(false)
            return
        end
        
        -- Get outlaw status and start washing
        RSGCore.Functions.TriggerCallback('rex-blackmarket:server:getoutlawstatus', function(outlawResult)
            local outlawstatus = (outlawResult and outlawResult[1] and outlawResult[1].outlawstatus) or 0
            StartWashingProcess(result, outlawstatus, isWashAll)
            SetPlayerBusy(false)
        end)
    end)
end

-- Wash custom amount with input dialog
local function WashBloodMoneyCustom(bloodmoney)
    if IsPlayerBusy() then
        ShowNotification(locale('cl_lang_busy') or 'You are currently busy', 'error')
        return
    end
    
    DebugPrint('Opening custom wash dialog')
    
    local input = lib.inputDialog(locale('cl_lang_wash_custom_title') or ('Wash Blood Money (max $' .. Config.Washing.MaxWash .. ')'), {
        {
            label = locale('cl_lang_6') or 'Amount',
            description = locale('cl_lang_7') .. bloodmoney,
            type = 'number',
            icon = 'fa-solid fa-dollar-sign',
            required = true,
            min = Config.Washing.MinWashAmount,
            max = math.min(bloodmoney, Config.Washing.MaxWash)
        },
    })
    
    if not input or not input[1] then
        return
    end
    
    local amount = tonumber(input[1])
    if amount then
        WashBloodMoneyAmount(amount)
    else
        ShowNotification(locale('cl_lang_invalid_amount') or 'Invalid amount', 'error')
    end
end

-----------------------------------------------------------------
-- Menu System
-----------------------------------------------------------------
local function ShowMainMenu()
    if IsPlayerBusy() then
        ShowNotification(locale('cl_lang_busy') or 'You are currently busy', 'error')
        return
    end
    
    DebugPrint('Opening main blackmarket menu')
    
    lib.registerContext({
        id = 'blackmarket_main_menu',
        title = locale('cl_lang_2'),
        position = 'top-right',
        options = {
            {
                title = locale('cl_lang_3'),
                description = locale('cl_lang_3_desc') or 'Convert blood money to clean cash',
                icon = 'fa-solid fa-hand-sparkles',
                event = 'rex-blackmarket:client:showWashMenu',
                arrow = true
            },
            {
                title = locale('cl_lang_4'),
                description = locale('cl_lang_4_desc') or 'Browse illegal goods',
                icon = 'fa-solid fa-shop',
                serverEvent = 'rex-blackmarket:server:openShop',
                arrow = true
            },
        }
    })
    
    lib.showContext('blackmarket_main_menu')
end

-- Register main menu event
RegisterNetEvent('rex-blackmarket:client:mainmenu', ShowMainMenu)

-----------------------------------------------------------------
-- Wash Menu System
-----------------------------------------------------------------
local function ShowWashMenu()
    if IsPlayerBusy() then
        ShowNotification(locale('cl_lang_busy') or 'You are currently busy', 'error')
        return
    end
    
    -- Get current blood money first
    RSGCore.Functions.TriggerCallback('rex-blackmarket:server:bloodmoneycallback', function(bloodmoney)
        if not bloodmoney or bloodmoney <= 0 then
            ShowNotification(locale('cl_lang_no_bloodmoney') or 'You have no blood money', 'error')
            return
        end
        
        DebugPrint('Opening wash menu with $' .. bloodmoney .. ' blood money')
        
        -- Calculate max washable amount
        local maxWashable = math.min(bloodmoney, Config.Washing.MaxWash)
        
        -- Calculate wash all amount based on configuration
        local allAmount = bloodmoney
        if Config.Washing.WashAllMaxLimit and Config.Washing.WashAllMaxLimit > 0 then
            allAmount = math.min(bloodmoney, Config.Washing.WashAllMaxLimit)
        end
        local cleanAmount = math.floor(allAmount * (Config.Washing.WashPercentage / 100))
        
        -- Build menu options
        local menuOptions = {}
        
        -- Add "Wash All" option if enabled
        if Config.Washing.AllowWashAll and allAmount >= Config.Washing.MinWashAmount then
            table.insert(menuOptions, {
                title = locale('cl_lang_wash_all') or 'Wash All Blood Money',
                description = ('Wash $' .. allAmount .. ' → $' .. cleanAmount .. ' clean cash'),
                icon = 'fa-solid fa-coins',
                onSelect = function()
                    WashBloodMoneyAmount(allAmount, true) -- true indicates wash all
                end
            })
        end
        
        -- Add custom amount option
        table.insert(menuOptions, {
            title = locale('cl_lang_wash_custom') or 'Wash Custom Amount',
            description = ('Available: $' .. bloodmoney .. ' | Max per wash: $' .. maxWashable),
            icon = 'fa-solid fa-dollar-sign',
            onSelect = function()
                WashBloodMoneyCustom(bloodmoney)
            end
        })
        
        lib.registerContext({
            id = 'blackmarket_wash_menu',
            title = locale('cl_lang_wash_menu') or 'Money Washing',
            position = 'top-right',
            menu = 'blackmarket_main_menu',
            options = menuOptions
        })
        
        lib.showContext('blackmarket_wash_menu')
    end)
end

-- Register wash menu event
RegisterNetEvent('rex-blackmarket:client:showWashMenu', ShowWashMenu)

-- Legacy function for backward compatibility
local function WashBloodMoney()
    -- This now opens the wash menu instead
    ShowWashMenu()
end

-- Register washing event
RegisterNetEvent('rex-blackmarket:client:washbloodmoney', WashBloodMoney)

-----------------------------------------------------------------
-- Resource Management
-----------------------------------------------------------------
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    DebugPrint('Resource stopping, cleaning up...')
    
    -- Reset player state
    SetPlayerBusy(false)
    
    -- Remove blips
    RemoveBlackmarketBlips()
end)

-- Handle resource start
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    DebugPrint('Resource started')
    
    -- Small delay to ensure config is loaded
    Wait(1000)
    
    -- Get active locations and create blips
    RSGCore.Functions.TriggerCallback('rex-blackmarket:server:getActiveLocations', function(activeLocations)
        currentActiveLocations = activeLocations or {}
        CreateBlackmarketBlips()
    end)
end)

-- Handle location updates for blips
RegisterNetEvent('rex-blackmarket:client:updateLocations', function(newActiveLocations)
    DebugPrint('Updating blips for new locations...')
    
    -- Remove old blips
    RemoveBlackmarketBlips()
    
    -- Update active locations
    currentActiveLocations = newActiveLocations or {}
    
    -- Create new blips
    CreateBlackmarketBlips()
end)
