Config = {}

---------------------------------
-- Shop Settings
---------------------------------
Config.Shop = {
    Items = {
        { name = 'weapon_thrown_molotov', amount = 50, price = 5 },
        -- Moonshine Equipment
        { name = 'mp001_p_mp_still02x', amount = 10, price = 2000 },
        { name = 'p_boxcar_barrel_09a', amount = 10, price = 500 },
        -- Ingredients
        { name = 'water', amount = 100, price = 5 },
        { name = 'agarita', amount = 50, price = 10 },
        { name = 'alaskan_ginseng', amount = 50, price = 12 },
        { name = 'american_ginseng', amount = 50, price = 12 },
        { name = 'bay_bolete', amount = 50, price = 8 },
        { name = 'blackberry', amount = 50, price = 6 },
        { name = 'yarrow', amount = 50, price = 7 },
        { name = 'black_currant', amount = 50, price = 8 },
        { name = 'evergreen_huckleberry', amount = 50, price = 9 },
        { name = 'wild_mint', amount = 50, price = 7 },
    },
    PersistStock = true, -- Should stock save in database and reload after restart
    RestrictedJobs = { 'leo' }, -- Job types that cannot access the shop
}

---------------------------------
-- Money Washing Settings
---------------------------------
Config.Washing = {
    WashTime = 1000, -- Time in ms per 1 blood money unit
    MaxWash = 50, -- Maximum blood money to wash per transaction
    WashPercentage = 60, -- Percentage of blood money converted to clean money (0-100)
    OutlawIncrease = 1, -- Outlaw status increase per wash operation
    MinWashAmount = 1, -- Minimum amount that can be washed
    AllowWashAll = true, -- Allow players to wash all blood money at once (ignores MaxWash limit)
    WashAllMaxLimit = 1000, -- Maximum amount that can be washed with "Wash All" (0 = no limit)
}

---------------------------------
-- Law Alert System
---------------------------------
Config.LawAlert = {
    Active = true, -- Enable/disable law alerts
    Chance = 20, -- Chance (0-100) of alerting law enforcement
    AlertRadius = 100.0, -- Radius for law alert
}

---------------------------------
-- NPC Settings
---------------------------------
Config.NPC = {
    DistanceSpawn = 20.0, -- Distance at which NPCs spawn/despawn
    FadeIn = true, -- Enable fade in/out effects for NPCs
    FadeSpeed = 51, -- Fade speed (higher = faster)
    InteractionDistance = 3.0, -- Maximum interaction distance
}

---------------------------------
-- Location Rotation Settings
---------------------------------
Config.LocationRotation = {
    Enabled = true, -- Enable hourly location rotation
    RotationInterval = 60, -- Rotation interval in minutes (60 = 1 hour)
    NotifyPlayers = true, -- Notify players when locations change
    NotificationDelay = 300000, -- Delay before showing notification (5 minutes in ms)
    FadeOutTime = 10000, -- Time in ms to fade out NPCs before moving (10 seconds)
}

---------------------------------
-- Performance Settings
---------------------------------
Config.Performance = {
    NPCUpdateInterval = 500, -- NPC update interval in ms
    EnableDebugPrints = false, -- Enable debug logging
}

---------------------------------
-- Blackmarket Locations
---------------------------------
Config.BlackmarketLocations = {
    {
        id = 'main_blackmarket', -- Unique identifier for this blackmarket
        name = 'Black Market', -- Display name
        rotatingLocations = { -- Multiple locations that this blackmarket rotates between
            {
                locationId = 'thieves_landing',
                name = 'Thieves Landing',
                coords = vector3(-1396.49, -2291.90, 43.52),
                npcmodel = GetHashKey('mp_u_M_M_lom_rhd_smithassistant_01'),
                npccoords = vector4(-1396.49, -2291.90, 43.52, 310.10),
            },
            {
                locationId = 'strawberry_outskirts',
                name = 'Strawberry Outskirts',
                coords = vector3(-1678.38, -344.60, 174.08),
                npcmodel = GetHashKey('mp_u_M_M_lom_rhd_smithassistant_01'),
                npccoords = vector4(-1678.38, -344.60, 174.08, 160.87),
            },
            {
                locationId = 'valentine_camp',
                name = 'Valentine Hideout',
                coords = vector3(-2.55, 949.01, 210.87),
                npcmodel = GetHashKey('mp_u_M_M_lom_rhd_smithassistant_01'),
                npccoords = vector4(-2.55, 949.01, 210.87, 90.59),
            },
            {
                locationId = 'annesburg_mines',
                name = 'Annesburg Outskirts',
                coords = vector3(3120.85, 1550.06, 53.38),
                npcmodel = GetHashKey('mp_u_M_M_lom_rhd_smithassistant_01'),
                npccoords = vector4(3120.85, 1550.06, 53.38, 259.63),
            },
            {
                locationId = 'van_horn_docks',
                name = 'Van Horn Docks',
                coords = vector3(3029.22, 567.98, 44.70),
                npcmodel = GetHashKey('mp_u_M_M_lom_rhd_smithassistant_01'),
                npccoords = vector4(3029.22, 567.98, 44.70, 357.63),
            },
            {
                locationId = 'saint_denis_stables',
                name = 'Saint Denis Stables',
                coords = vector3(2511.61, -1452.80, 46.31),
                npcmodel = GetHashKey('mp_u_M_M_lom_rhd_smithassistant_01'),
                npccoords = vector4(2511.61, -1452.80, 46.31, 271.07),
            },
        },
        blip = {
            sprite = 'blip_shop_shady_store',
            scale = 0.2,
            show = true,
        },
    },
    -- You can add more blackmarket groups here, each with their own rotating locations
    -- {
    --     id = 'second_blackmarket',
    --     name = 'Underground Market',
    --     rotatingLocations = {
    --         -- Different set of locations for a second blackmarket
    --     },
    --     blip = {
    --         sprite = 'blip_shop_shady_store',
    --         scale = 0.2,
    --         show = true,
    --     },
    -- },
}

---------------------------------
-- Validation Functions
---------------------------------
local function ValidateConfig()
    -- Validate washing settings
    if Config.Washing.WashPercentage < 0 or Config.Washing.WashPercentage > 100 then
        print('^1[rex-blackmarket] ERROR: WashPercentage must be between 0 and 100^7')
        Config.Washing.WashPercentage = math.max(0, math.min(100, Config.Washing.WashPercentage))
    end
    
    if Config.Washing.MaxWash < Config.Washing.MinWashAmount then
        print('^1[rex-blackmarket] ERROR: MaxWash cannot be less than MinWashAmount^7')
        Config.Washing.MaxWash = Config.Washing.MinWashAmount
    end
    
    -- Validate wash all settings
    if Config.Washing.WashAllMaxLimit and Config.Washing.WashAllMaxLimit > 0 then
        if Config.Washing.WashAllMaxLimit < Config.Washing.MinWashAmount then
            print('^1[rex-blackmarket] ERROR: WashAllMaxLimit cannot be less than MinWashAmount^7')
            Config.Washing.WashAllMaxLimit = Config.Washing.MinWashAmount
        end
    end
    
    -- Validate law alert settings
    if Config.LawAlert.Chance < 0 or Config.LawAlert.Chance > 100 then
        print('^1[rex-blackmarket] ERROR: LawAlert.Chance must be between 0 and 100^7')
        Config.LawAlert.Chance = math.max(0, math.min(100, Config.LawAlert.Chance))
    end
    
    -- Validate locations
    for i, location in ipairs(Config.BlackmarketLocations) do
        -- Check basic required fields
        if not location.id or not location.name then
            print('^1[rex-blackmarket] ERROR: Invalid blackmarket location at index ' .. i .. ' (missing id or name)^7')
        else
            -- Check if it's new rotating format or old single location format
            if location.rotatingLocations then
                -- New rotating locations format
                if type(location.rotatingLocations) ~= 'table' or #location.rotatingLocations == 0 then
                    print('^1[rex-blackmarket] ERROR: Invalid rotating locations at index ' .. i .. ' (empty or invalid rotatingLocations table)^7')
                else
                    -- Validate each rotating location
                    for j, rotLocation in ipairs(location.rotatingLocations) do
                        if not rotLocation.locationId or not rotLocation.name or not rotLocation.coords or not rotLocation.npccoords or not rotLocation.npcmodel then
                            print('^1[rex-blackmarket] ERROR: Invalid rotating location ' .. j .. ' in blackmarket ' .. i .. ' (missing required fields: locationId, name, coords, npccoords, npcmodel)^7')
                        end
                    end
                end
            elseif not location.coords or not location.npccoords then
                -- Old single location format - must have coords and npccoords
                print('^1[rex-blackmarket] ERROR: Invalid blackmarket location at index ' .. i .. ' (missing coords or npccoords)^7')
            end
        end
    end
end

-- Run validation on config load
ValidateConfig()

-- Debug information (only if debug is enabled)
if Config.Performance and Config.Performance.EnableDebugPrints then
    print('^2[rex-blackmarket] Config validation completed successfully^7')
    print('^2[rex-blackmarket] Loaded ' .. #Config.BlackmarketLocations .. ' blackmarket location(s)^7')
    
    for i, location in ipairs(Config.BlackmarketLocations) do
        if location.rotatingLocations then
            print('^2[rex-blackmarket] - ' .. location.name .. ' (' .. #location.rotatingLocations .. ' rotating locations)^7')
        else
            print('^2[rex-blackmarket] - ' .. location.name .. ' (single location)^7')
        end
    end
end
