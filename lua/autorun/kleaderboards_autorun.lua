kboard = kboard or {}
kboard.gamemode = engine.ActiveGamemode()

local supportedGMs = {
    ["darkrp"] = true, 
    ["terrortown"] = true,
}

if (not supportedGMs[kboard.gamemode]) then 
    print("[KLeaderboards] Addon Not Initalized, "..kboard.gamemode.." Not Supported.") 
    return 
else 
    print("[KLeaderboards] "..kboard.gamemode.." Supported. Addon Initalized") 
end

kboard.Server = kboard.Server or {}

if SERVER then
    include("kleaderboards/server/sv_kboard_main.lua")
elseif CLIENT then
	include("kleaderboards/client/cl_kboard_main.lua")
end