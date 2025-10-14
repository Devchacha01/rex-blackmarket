-----------------------------------------------------------------
-- Rex Blackmarket - Shared Utilities
-- Version: 2.0.5+
-- Author: RexShack Gaming
-----------------------------------------------------------------

Utils = {}

-----------------------------------------------------------------
-- Table Utilities
-----------------------------------------------------------------
function Utils.TableCount(t)
    if type(t) ~= 'table' then return 0 end
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

function Utils.TableHasValue(t, value)
    if type(t) ~= 'table' then return false end
    for _, v in pairs(t) do
        if v == value then
            return true
        end
    end
    return false
end

function Utils.DeepCopy(t)
    if type(t) ~= 'table' then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = Utils.DeepCopy(v)
    end
    return copy
end

-----------------------------------------------------------------
-- Math Utilities
-----------------------------------------------------------------
function Utils.Round(number, decimals)
    local multiplier = 10 ^ (decimals or 0)
    return math.floor(number * multiplier + 0.5) / multiplier
end

function Utils.Clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

function Utils.RandomFloat(min, max)
    return min + (max - min) * math.random()
end

-----------------------------------------------------------------
-- String Utilities
-----------------------------------------------------------------
function Utils.FormatMoney(amount)
    if type(amount) ~= 'number' then return '$0' end
    return '$' .. tostring(math.floor(amount))
end

function Utils.Trim(str)
    if not str then return '' end
    return str:match('^%s*(.-)%s*$')
end

function Utils.Split(str, delimiter)
    if not str or not delimiter then return {} end
    local result = {}
    for match in (str .. delimiter):gmatch('(.-)' .. delimiter) do
        table.insert(result, match)
    end
    return result
end

-----------------------------------------------------------------
-- Vector Utilities
-----------------------------------------------------------------
function Utils.GetDistance(pos1, pos2)
    if not pos1 or not pos2 then return math.huge end
    return #(pos1 - pos2)
end

function Utils.GetDistance2D(pos1, pos2)
    if not pos1 or not pos2 then return math.huge end
    local dx = pos1.x - pos2.x
    local dy = pos1.y - pos2.y
    return math.sqrt(dx * dx + dy * dy)
end

-----------------------------------------------------------------
-- Validation Utilities
-----------------------------------------------------------------
function Utils.IsValidCoord(coord)
    return coord and type(coord) == 'vector3' and 
           coord.x and coord.y and coord.z and
           type(coord.x) == 'number' and 
           type(coord.y) == 'number' and 
           type(coord.z) == 'number'
end

function Utils.IsValidVector4(vec)
    return vec and type(vec) == 'vector4' and
           vec.x and vec.y and vec.z and vec.w and
           type(vec.x) == 'number' and 
           type(vec.y) == 'number' and 
           type(vec.z) == 'number' and
           type(vec.w) == 'number'
end

function Utils.IsValidAmount(amount, min, max)
    if type(amount) ~= 'number' then return false end
    if min and amount < min then return false end
    if max and amount > max then return false end
    return amount > 0
end

-----------------------------------------------------------------
-- Time Utilities
-----------------------------------------------------------------
function Utils.GetTimestamp()
    return os.time()
end

function Utils.FormatTime(seconds)
    if not seconds or type(seconds) ~= 'number' then return '0s' end
    
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60
    
    if hours > 0 then
        return string.format('%dh %dm %ds', hours, minutes, secs)
    elseif minutes > 0 then
        return string.format('%dm %ds', minutes, secs)
    else
        return string.format('%ds', secs)
    end
end

-----------------------------------------------------------------
-- Color Utilities
-----------------------------------------------------------------
Utils.Colors = {
    Red = '^1',
    Green = '^2',
    Yellow = '^3',
    Blue = '^4',
    Cyan = '^5',
    Pink = '^6',
    White = '^7',
    Grey = '^8',
    Reset = '^7'
}

function Utils.ColorText(text, color)
    local colorCode = Utils.Colors[color] or color or Utils.Colors.White
    return colorCode .. text .. Utils.Colors.Reset
end

-----------------------------------------------------------------
-- Debug Utilities
-----------------------------------------------------------------
function Utils.PrintTable(t, indent)
    indent = indent or 0
    local spacing = string.rep('  ', indent)
    
    if type(t) ~= 'table' then
        print(spacing .. tostring(t))
        return
    end
    
    for k, v in pairs(t) do
        if type(v) == 'table' then
            print(spacing .. tostring(k) .. ':')
            Utils.PrintTable(v, indent + 1)
        else
            print(spacing .. tostring(k) .. ': ' .. tostring(v))
        end
    end
end

-----------------------------------------------------------------
-- Export for global access
-----------------------------------------------------------------
if IsDuplicityVersion() then
    -- Server-side
    exports('GetUtils', function() return Utils end)
else
    -- Client-side
    exports('GetUtils', function() return Utils end)
end