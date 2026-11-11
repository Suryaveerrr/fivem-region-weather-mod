-- Detects which region the player is in and fires an event when it changes.

local currentRegion = nil   
local warnedZones = {}      


-- Helpers


local function debugPrint(msg)
    if Config.Debug then
        print('[region-weather] ' .. msg)
    end
end


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


local function getRegionForZone(zoneCode)
    local regionId = zoneToRegion[zoneCode]
    if regionId then
        return regionId
    end

   
    if not warnedZones[zoneCode] then
        warnedZones[zoneCode] = true
        debugPrint(('Zone %s (%s) has no region, using default "%s"')
            :format(zoneCode, GetLabelText(zoneCode), Config.DefaultRegion))
    end
    return Config.DefaultRegion
end

-- Main Loop

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
exports('GetCurrentRegion', function()
    return currentRegion
end)


-- Debug commands


-- rwtest
RegisterCommand('rwtest', function()
    local coords = GetEntityCoords(PlayerPedId())
    local zoneCode = GetNameOfZone(coords.x, coords.y, coords.z)
    print(('[region-weather] Zone: %s (%s) | Region: %s | Position: %.1f, %.1f, %.1f')
        :format(zoneCode, GetLabelText(zoneCode), tostring(currentRegion),
                coords.x, coords.y, coords.z))
end, false)

-- rwtp <place>
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