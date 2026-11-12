
-- Detects which region the player is in, reads that region's weather/time


local currentRegion = nil   
local warnedZones = {}      



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


-- Build a lookup table once at startup: zone code -> region id
-- e.g. zoneToRegion['SANDY'] = 'desert'
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

-- Main loop: check the player's region every Config.CheckInterval ms
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

            -- Other scripts (and the Step 4 code below) listen for this
            TriggerEvent('region-weather:client:regionChanged', regionId, oldRegion)
        end

        Wait(Config.CheckInterval)  -- pause so this loop isn't running every frame
    end
end)

-- Let other resources ask "which region is the player in?"
-- Usage elsewhere: exports['region-weather']:GetCurrentRegion()
exports('GetCurrentRegion', function()
    return currentRegion
end)



-- Get the server's weather/time for a region 
local function getRegionState(regionId)
    local all = GlobalState.regionWeather
    return all and all[regionId]
end

local function describe(regionId)
    local s = getRegionState(regionId)
    if not s then return ('%s: (no data yet)'):format(tostring(regionId)) end
    return ('%s: %s at %02d:%02d'):format(Config.Regions[regionId].label, s.weather, s.hour, s.minute)
end

-- When the player enters a new region, log that region's weather/time
AddEventHandler('region-weather:client:regionChanged', function(newRegion)
    debugPrint('Now in ' .. describe(newRegion))
end)

-- Messages from the server (e.g. replies to rwset)
RegisterNetEvent('region-weather:client:notify', function(msg)
    notify(msg)
end)



local appliedWeather = nil     -- the weather we last told GTA to use
local isTransitioning = false  -- true while a weather blend is in progress
local transitionId = 0         -- increases with each new blend, so an old one can't finish over a newer one

-- Weathers that should cover the ground in snow and leave tracks
local snowWeathers = { SNOW = true, SNOWLIGHT = true, BLIZZARD = true, XMAS = true }

-- Turn the full snow effect on/off: white ground cover, footprints, tyre tracks, snow sounds
local snowEffectsOn = false

local function setSnowEffects(enabled)
    if enabled == snowEffectsOn then return end   -- only act when it actually changes
    snowEffectsOn = enabled

    ForceSnowPass(enabled)                 -- covers the ground in snow
    SetForceVehicleTrails(enabled)         -- tyre tracks
    SetForcePedFootstepsTracks(enabled)    -- footprints

    
    CreateThread(function()
        if enabled then
            RequestScriptAudioBank('ICE_FOOTSTEPS', false)    -- crunchy footstep sounds
            RequestScriptAudioBank('SNOW_FOOTSTEPS', false)
            RequestNamedPtfxAsset('core_snow')                -- snow particle effects
            while not HasNamedPtfxAssetLoaded('core_snow') do
                Wait(0)
            end
            UseParticleFxAssetNextCall('core_snow')
        else
            ReleaseNamedScriptAudioBank('ICE_FOOTSTEPS')
            ReleaseNamedScriptAudioBank('SNOW_FOOTSTEPS')
            RemoveNamedPtfxAsset('core_snow')
        end
    end)
    debugPrint('Snow effects ' .. (enabled and 'ON' or 'OFF'))
end

-- Lock GTA onto one weather, instantly and persistently
local function lockWeather(weather)
    ClearOverrideWeather()
    ClearWeatherTypePersist()
    SetWeatherTypePersist(weather)
    SetWeatherTypeNow(weather)
    SetWeatherTypeNowPersist(weather)

    setSnowEffects(snowWeathers[weather] == true)
end

-- Change weather; instant = true skips the blend (used on first spawn)
local function applyWeather(weather, instant)
    if weather == appliedWeather then return end
    appliedWeather = weather

    transitionId = transitionId + 1
    local myId = transitionId

    if instant then
        isTransitioning = false
        lockWeather(weather)
        debugPrint('Weather set instantly to ' .. weather)
        return
    end

    isTransitioning = true
    SetWeatherTypeOverTime(weather, Config.WeatherTransitionTime)
    debugPrint(('Blending to %s over %.0fs'):format(weather, Config.WeatherTransitionTime))

    -- After the blend finishes, lock the weather in place
    CreateThread(function()
        Wait(math.floor(Config.WeatherTransitionTime * 1000))
        -- If another change started meanwhile, let that one win
        if myId == transitionId then
            lockWeather(weather)
            isTransitioning = false
        end
    end)
end

local function applyTime(hour, minute)
    NetworkOverrideClockTime(hour, minute, 0)
end

-- Apply a region's state table ({ weather, hour, minute })
local function applyState(state, instant)
    if not state then return end
    applyWeather(state.weather, instant)
    applyTime(state.hour, state.minute)
end

-- 1) Entering a new region: apply it (instantly if this is the first region since spawning)
AddEventHandler('region-weather:client:regionChanged', function(newRegion, oldRegion)
    applyState(getRegionState(newRegion), oldRegion == nil)
end)

-- 2) The server changed something: log it and apply it if it's for our region.
-- Note: this handler runs just BEFORE GlobalState updates, so use the `value` passed in.
AddStateBagChangeHandler('regionWeather', 'global', function(_, _, value)
    if not currentRegion or not value then return end
    local s = value[currentRegion]
    if s then
        debugPrint(('Server update: your region is now %s at %02d:%02d'):format(s.weather, s.hour, s.minute))
        applyState(s, false)
    end
end)

-- 3) Enforcement loop: keep re-applying so GTA's own clock/weather cycle can't take over.
-- It also covers the case where we spawned before the server's state had arrived.
CreateThread(function()
    while true do
        Wait(Config.EnforceInterval)

        local state = currentRegion and getRegionState(currentRegion)
        if state then
            applyTime(state.hour, state.minute)

            if state.weather ~= appliedWeather and not isTransitioning then
                applyWeather(state.weather, appliedWeather == nil)
            elseif not isTransitioning and appliedWeather then
                SetWeatherTypeNowPersist(appliedWeather)
            end
        end
    end
end)


-- rwtest: print your zone, region and position
RegisterCommand('rwtest', function()
    local coords = GetEntityCoords(PlayerPedId())
    local zoneCode = GetNameOfZone(coords.x, coords.y, coords.z)
    print(('[region-weather] Zone: %s (%s) | Region: %s | Position: %.1f, %.1f, %.1f')
        :format(zoneCode, GetLabelText(zoneCode), tostring(currentRegion),
                coords.x, coords.y, coords.z))
end, false)

-- rwstate: show the synced weather/time for your region, plus what the game is actually doing
RegisterCommand('rwstate', function()
    print(('[region-weather] %s | Game clock: %02d:%02d | Applied weather: %s | Snow: %s')
        :format(describe(currentRegion), GetClockHours(), GetClockMinutes(),
                tostring(appliedWeather), tostring(snowEffectsOn)))
end, false)

-- rwtp <place>: teleport to a test location (debug only)
local testLocations = {
    city    = vector3(195.0, -933.0, 30.7),     -- Legion Square
    sandy   = vector3(1960.0, 3740.0, 32.3),    -- Sandy Shores
    paleto  = vector3(-275.0, 6230.0, 31.5),    -- Paleto Bay
    chiliad = vector3(501.0, 5593.0, 797.0),    -- Top of Mount Chiliad
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