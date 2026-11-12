-- Detects which region the player is in and fires an event when it changes.

local currentRegion = nil   -- the region the player is in right now (e.g. 'city')
local warnedZones = {}      -- zones we've already warned about, so we don't spam the console


local function debugPrint(msg)
    if Config.Debug then
        print('[region-weather] ' .. msg)
    end
end

-- Show a small notification above the minimap (GTA's "feed")
local function notify(text)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandThefeedPostTicker(false, true)
end



local zoneToRegion = {}
for regionId, region in pairs(Config.Regions) do
    for _, zoneCode in ipairs(region.zones) do
        zoneToRegion[zoneCode] = regionId
    end
end

-- Returns the region id for a zone code, falling back to the default region
local function getRegionForZone(zoneCode)
    local regionId = zoneToRegion[zoneCode]
    if regionId then
        return regionId
    end

    -- Zone isn't in the config: warn once so we can add it later
    if not warnedZones[zoneCode] then
        warnedZones[zoneCode] = true
        debugPrint(('Zone %s (%s) has no region, using default "%s"')
            :format(zoneCode, GetLabelText(zoneCode), Config.DefaultRegion))
    end
    return Config.DefaultRegion
end



CreateThread(function()
    while true do
        local coords = GetEntityCoords(PlayerPedId())
        local zoneCode = GetNameOfZone(coords.x, coords.y, coords.z)
        local regionId = getRegionForZone(zoneCode)

        if regionId ~= currentRegion then
            local oldRegion = currentRegion
            currentRegion = regionId

            debugPrint(('Region changed: %s -> %s (zone %s)')
                :format(tostring(oldRegion), regionId, zoneCode))

            -- ~y~ = yellow text, ~s~ = reset colour (GTA text formatting)
            notify(('Entered ~y~%s~s~'):format(Config.Regions[regionId].label))

            -- Other scripts (and Step 4) can listen for this
            TriggerEvent('region-weather:client:regionChanged', regionId, oldRegion)
        end

        Wait(Config.CheckInterval)  -- pause this loop so it isn't running every frame
    end
end)

-- Let other resources ask "which region is the player in?"
-- Usage elsewhere: exports['region-weather']:GetCurrentRegion()
exports('GetCurrentRegion', function()
    return currentRegion
end)



-- rwtest: print your zone, region and position
RegisterCommand('rwtest', function()
    local coords = GetEntityCoords(PlayerPedId())
    local zoneCode = GetNameOfZone(coords.x, coords.y, coords.z)
    print(('[region-weather] Zone: %s (%s) | Region: %s | Position: %.1f, %.1f, %.1f')
        :format(zoneCode, GetLabelText(zoneCode), tostring(currentRegion),
                coords.x, coords.y, coords.z))
end, false)

-- rwtp <place>: teleport to a test location (debug only)
local testLocations = {
    city   = vector3(195.0, -933.0, 30.7),     -- Legion Square
    sandy  = vector3(1960.0, 3740.0, 32.3),    -- Sandy Shores
    paleto = vector3(-275.0, 6230.0, 31.5),    -- Paleto Bay
    chiliad = vector3(501.0, 5593.0, 797.0),   -- Top of Mount Chiliad
}

RegisterCommand('rwtp', function(_, args)
    if not Config.Debug then return end
    local target = testLocations[args[1] or '']
    if not target then
        print('[region-weather] Usage: rwtp city | sandy | paleto | chiliad')
        return
    end
    SetEntityCoords(PlayerPedId(), target.x, target.y, target.z, false, false, false, false)
end, false)



-- Get the server's weather/time for a regioSn (or nil if not received yet)
local function getRegionState(regionId)
    local all = GlobalState.regionWeather
    return all and all[regionId]
end

local function describe(regionId)
    local s = getRegionState(regionId)
    if not s then return ('%s: (no data yet)'):format(tostring(regionId)) end
    return ('%s: %s at %02d:%02d'):format(Config.Regions[regionId].label, s.weather, s.hour, s.minute)
end

-- When the player enters a new region, show that region's weather/time
AddEventHandler('region-weather:client:regionChanged', function(newRegion)
    debugPrint('Now in ' .. describe(newRegion))
end)

-- When the server changes ANY region, this runs on every client
AddStateBagChangeHandler('regionWeather', 'global', function(_, _, value)
    if not currentRegion or not value then return end
    local s = value[currentRegion]
    if s then
        debugPrint(('Server update: your region is now %s at %02d:%02d'):format(s.weather, s.hour, s.minute))
    end
end)

-- Messages from the server (e.g. replies to rwset)
RegisterNetEvent('region-weather:client:notify', function(msg)
    notify(msg)
end)

-- rwstate: show the synced weather/time for your current region
RegisterCommand('rwstate', function()
    print('[region-weather] ' .. describe(currentRegion))
end, false)