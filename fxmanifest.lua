-- Tells FiveM what this resource is and which files to load.

fx_version 'cerulean'   -- the current manifest version
game 'gta5'             -- this resource is for GTA V
lua54 'yes'             -- use Lua 5.4 (newer, faster, better features)

author 'Suryaveer'
description 'Region-based weather and time system with a simple UI'
version '0.1.0'

-- Loaded first, on BOTH server and client, so both sides share the same config
shared_script 'shared/config.lua'

-- Runs on each player's machine
client_script 'client/main.lua'

-- Runs once on the server
server_script 'server/main.lua'