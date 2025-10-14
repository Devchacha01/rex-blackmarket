# Rex Blackmarket

[![Version](https://img.shields.io/badge/version-2.0.6-blue.svg)]()
[![License](https://img.shields.io/badge/license-Custom-red.svg)]()
[![Framework](https://img.shields.io/badge/framework-RSG--Core-green.svg)]()
[![Game](https://img.shields.io/badge/game-RedM-orange.svg)]()

An advanced blackmarket system for RedM servers featuring illegal item trading and blood money laundering mechanics.

## 🌟 Features

### 💰 Money Laundering System
- **Blood Money Washing**: Convert illegal blood money to clean cash
- **Wash All Option**: Quick option to wash all blood money at once
- **Custom Amount Input**: Enter specific amounts to wash with validation
- **Configurable Conversion Rates**: Set custom wash percentages (default 60%)
- **Transaction Limits**: Min/max wash amounts with validation
- **Progress Bar Integration**: Visual feedback during washing process
- **Outlaw Status Penalties**: Increases player's criminal reputation

### 🛒 Blackmarket Shop
- **Illegal Item Trading**: Access restricted weapons and contraband
- **Persistent Stock System**: Optional stock saving across server restarts
- **Job Restrictions**: Block law enforcement from accessing services
- **Dynamic Inventory**: Easy configuration of available items

### 👥 Advanced NPC System
- **Dynamic Spawning**: NPCs appear/disappear based on player proximity
- **Fade Effects**: Smooth appearance transitions for immersion
- **Optimized Performance**: Reduced CPU usage with smart update intervals
- **Location Rotation**: NPCs automatically move to different locations every hour
- **Smart Transitions**: Smooth NPC transitions during location changes
- **Dynamic Blips**: Map markers update automatically with NPC movements
- **Multiple Location Sets**: Each blackmarket can have multiple possible locations
- **Location Rotation**: NPCs automatically move to different locations every hour

### 🚔 Law Enforcement Integration
- **Alert System**: Configurable chance to notify police during transactions
- **RSG-Lawman Compatible**: Works with existing law enforcement systems
- **Realistic Consequences**: Risk vs reward gameplay mechanics

### 🌍 Multi-Language Support
- **Localization Ready**: Full support for multiple languages
- **Included Languages**: English (expandable)
- **Easy Translation**: Simple JSON-based locale system

## 📋 Dependencies

### Required
- **rsg-core**: RSG Framework core
- **ox_lib**: UI and utility library
- **rsg-inventory**: Inventory management system
- **oxmysql**: Database operations (for stock persistence)
- **rsg-lawman**: Law enforcement alerts

## 🚀 Installation

1. **Download** the resource and extract to your `resources` folder
2. **Ensure dependencies** are installed and started before this resource
3. **Add to server.cfg**:
   ```
   ensure rex-blackmarket
   ```
4. **Configure** settings in `config.lua` to match your server needs
5. **Restart** your server or start the resource

## ⚙️ Configuration

### Shop Settings
```lua
Config.Shop = {
    Items = {
        { name = 'weapon_thrown_molotov', amount = 50, price = 5 },
        -- Add more items here
    },
    PersistStock = true, -- Save stock across restarts
    RestrictedJobs = { 'leo' }, -- Blocked job types
}
```

### Money Washing
```lua
Config.Washing = {
    WashTime = 1000, -- Time per blood money unit (ms)
    MaxWash = 50, -- Maximum wash amount per transaction
    WashPercentage = 60, -- Conversion rate (0-100%)
    OutlawIncrease = 1, -- Outlaw status penalty
    MinWashAmount = 1, -- Minimum washable amount
    AllowWashAll = true, -- Allow "Wash All" option
    WashAllMaxLimit = 1000, -- Max amount for wash all (0 = no limit)
}
```

### Law Alerts
```lua
Config.LawAlert = {
    Active = true, -- Enable/disable alerts
    Chance = 20, -- Alert probability (0-100%)
    AlertRadius = 100.0, -- Alert radius
}
```

### Location Rotation
```lua
Config.LocationRotation = {
    Enabled = true, -- Enable hourly location rotation
    RotationInterval = 60, -- Rotation interval in minutes (60 = 1 hour)
    NotifyPlayers = true, -- Notify players when locations change
    NotificationDelay = 300000, -- Delay before showing notification (5 minutes in ms)
    FadeOutTime = 10000, -- Time in ms to fade out NPCs before moving (10 seconds)
}
```

## 🗺️ Adding Locations

### Rotating Locations Format (Recommended)
```lua
Config.BlackmarketLocations = {
    {
        id = 'main_blackmarket', -- Unique identifier for this blackmarket group
        name = 'Black Market', -- Display name for this blackmarket
        rotatingLocations = { -- Multiple locations that this blackmarket rotates between
            {
                locationId = 'thieves_landing',
                name = 'Thieves Landing',
                coords = vector3(-1396.49, -2291.90, 43.52),
                npcmodel = `mp_u_M_M_lom_rhd_smithassistant_01`,
                npccoords = vector4(-1396.49, -2291.90, 43.52, 310.10),
            },
            {
                locationId = 'strawberry_outskirts',
                name = 'Strawberry Outskirts',
                coords = vector3(-1818.23, -354.89, 164.66),
                npcmodel = `mp_u_M_M_lom_rhd_smithassistant_01`,
                npccoords = vector4(-1818.23, -354.89, 164.66, 285.15),
            },
            -- Add more locations here...
        },
        blip = {
            sprite = 'blip_shop_shady_store',
            scale = 0.2,
            show = true,
        },
    },
}
```

### Legacy Format (Still Supported)
For backward compatibility, the old format still works but won't have rotation:
```lua
Config.BlackmarketLocations = {
    {
        id = 'unique_id',
        name = 'Location Name',
        coords = vector3(x, y, z),
        npcmodel = `model_hash`,
        npccoords = vector4(x, y, z, heading),
        blip = {
            name = 'Blip Name',
            sprite = 'blip_shop_shady_store',
            scale = 0.2,
            show = true,
        },
    },
}
```

## 🔧 Performance Settings

```lua
Config.Performance = {
    NPCUpdateInterval = 500, -- NPC update frequency (ms)
    EnableDebugPrints = false, -- Debug logging
}
```

## 🐛 Debug Commands

When debug mode is enabled:
- `/rex_npc_debug` - Show NPC system information
- `/rex_npc_cleanup` - Manually cleanup all NPCs

Server console commands:
- `rex_rotate_locations` - Manually trigger location rotation

## 📝 Changelog

### Version 2.1.0 (Latest)
- ✅ Location Rotation System** - NPCs automatically move to different locations every hour
- ✅ Multiple Location Sets** - Each blackmarket can have multiple rotating locations
- ✅ Smart Transitions** - Smooth NPC fade-outs during location changes
- ✅ Dynamic Blips** - Map markers update automatically with NPC movements
- ✅ Player Notifications** - Optional notifications when locations change
- ✅ Enhanced server-client synchronization for location updates
- ✅ Improved resource management and cleanup
- ✅ Added locale support for rotation notifications
- ✅ Server console command for manual rotation testing

## 🆘 Support

- **Discord**: [https://discord.gg/YUV7ebzkqs](https://discord.gg/YUV7ebzkqs)
- **YouTube**: [https://www.youtube.com/@rexshack/videos](https://www.youtube.com/@rexshack/videos)
- **Store**: [https://rexshackgaming.tebex.io/](https://rexshackgaming.tebex.io/)

## 📄 License

This resource is protected by custom license terms. See the license agreement for details.

---

**Made with ❤️ by RexShack Gaming**
