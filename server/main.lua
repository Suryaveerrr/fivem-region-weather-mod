-- server/main.lua
-- Holds the weather/time for every region and syncs it to all players via GlobalState.

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------

local function debugPrint(msg)
    if Config.Debug then
        print('^3[region-weather]^7 ' .. msg)   -- ^3 = yellow
    end
end

-- Quick lookup of allowed weather ids: validWeather['RAIN'] = true
local validWeather = {}
for _, weather in ipairs(Config.WeatherTypes) do
    validWeather[weather.id] = true
end

---------------------------------------------------------------------
-- State: one entry per region, built from the config defaults
---------------------------------------------------------------------

local regionState = {}
for regionId, region in pairs(Config.Regions) do
    regionState[regionId] = {
        weather = region.defaultWeather or Config.DefaultWeather,
        hour    = region.defaultHour or Config.DefaultHour,
        minute  = 0,
    }
end

-- Push the whole table to GlobalState so every client gets the update.
-- (Editing a nested value in GlobalState does NOT sync, so always reassign the table.)
local function publish()
    GlobalState.regionWeather = regionState
end

publish()
debugPrint('Initial region state published')

---------------------------------------------------------------------
-- Change one region. Returns true, or false + an error message.
-- Every change goes through here, so validation lives in one place.
---------------------------------------------------------------------

local function setRegion(regionId, weather, hour, minute)
    if not Config.Regions[regionId] then
        return false, ('Unknown region "%s"'):format(tostring(regionId))
    end

    weather = type(weather) == 'string' and weather:upper() or nil
    if not validWeather[weather] then
        return false, ('Unknown weather "%s"'):format(tostring(weather))
    end

    hour = tonumber(hour)
    minute = tonumber(minute) or 0
    if not hour or hour < 0 or hour > 23 or hour % 1 ~= 0 then
        return false, 'Hour must be a whole number from 0 to 23'
    end
    if minute < 0 or minute > 59 or minute % 1 ~= 0 then
        return false, 'Minute must be a whole number from 0 to 59'
    end

    regionState[regionId] = { weather = weather, hour = hour, minute = minute }
    publish()

    debugPrint(('%s set to %s at %02d:%02d'):format(regionId, weather, hour, minute))
    return true
end

-- Let other resources change a region: exports['region-weather']:SetRegion('city', 'RAIN', 20, 0)
exports('SetRegion', setRegion)

---------------------------------------------------------------------
-- Commands (for testing from the txAdmin Live Console)
---------------------------------------------------------------------

-- Reply to whoever ran the command: the server console (source 0) or a player
local function reply(source, msg)
    if source == 0 then
        print('[region-weather] ' .. msg)
    else
        TriggerClientEvent('region-weather:client:notify', source, msg)
    end
end

-- rwset <region> <weather> <hour> [minute]
-- e.g. rwset desert THUNDER 22
RegisterCommand('rwset', function(source, args)
    local ok, err = setRegion(args[1], args[2], args[3], args[4])
    if ok then
        reply(source, ('Updated %s'):format(args[1]))
    else
        reply(source, 'Error: ' .. err .. ' | Usage: rwset <region> <weather> <hour> [minute]')
    end
end, true)  -- true = restricted: only the server console / allowed admins can use it

-- rwlist: print every region's current state
RegisterCommand('rwlist', function(source)
    for regionId, state in pairs(regionState) do
        reply(source, ('%-12s %-11s %02d:%02d'):format(regionId, state.weather, state.hour, state.minute))
    end
end, true)