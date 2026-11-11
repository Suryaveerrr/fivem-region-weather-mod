-- client/main.lua
-- Runs on each player's game. Later this will detect the player's region and apply weather/time.

print('[region-weather] client script loaded (debug: ' .. tostring(Config.Debug) .. ')')

-- Test command: type "rwtest" in the F8 console to see which map zone you are in.
RegisterCommand('rwtest', function()
    local ped = PlayerPedId()                 -- your character
    local coords = GetEntityCoords(ped)       -- your position (vector3: x, y, z)

    -- GTA splits the map into named zones. This returns a short code, e.g. "DOWNT"
    local zoneCode = GetNameOfZone(coords.x, coords.y, coords.z)

    -- Turn the code into the readable in-game name, e.g. "Downtown"
    local zoneName = GetLabelText(zoneCode)

    print(('[region-weather] Zone: %s (%s) | Position: %.1f, %.1f, %.1f')
        :format(zoneCode, zoneName, coords.x, coords.y, coords.z))
end, false)  -- false = anyone can use this command