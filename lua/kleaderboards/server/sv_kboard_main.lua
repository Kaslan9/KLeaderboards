kboard.leaderboardTbl = kboard.leaderboardTbl or {}
kboard.Server.Damage = 0

AddCSLuaFile("kleaderboards/client/cl_kboard_main.lua")
AddCSLuaFile("kleaderboards/client/cl_kboard_draw.lua")
AddCSLuaFile("kleaderboards/client/cl_kboard_connectedplayers.lua")
AddCSLuaFile("kleaderboards/client/cl_kboard_leaderboards.lua")
AddCSLuaFile("kleaderboards/client/cl_kboard_personalstats.lua")
AddCSLuaFile("kleaderboards/client/cl_kboard_serverpanel.lua")


AddCSLuaFile("kleaderboards/kboard_config.lua")
AddCSLuaFile("kleaderboards/shared/sh_kboard.lua")
 
-- Include correct gamemode files
if (kboard.gamemode == "terrortown") then
    include("sv_kboard_terrortown.lua")
elseif (kboard.gamemode == "darkrp") then
    include("sv_kboard_darkrp.lua")
end

include("kleaderboards/kboard_config.lua")
include("kleaderboards/shared/sh_kboard.lua")
include("sv_kboard_functions.lua")

util.AddNetworkString("kboard_openMenu")
util.AddNetworkString("kboard_RequestPlayerData")
util.AddNetworkString("kboard_SendPlayerData")
util.AddNetworkString("kboard_RequestPageData")
util.AddNetworkString("kboard_SendPageData")
util.AddNetworkString("kboard_ResetPlayerData")
util.AddNetworkString("kboard_RequestSortPage")
util.AddNetworkString("kboard_SendSortPage")

local meta = FindMetaTable("Player")

hook.Add("Initialize", "kboard_Initialize", function()
    
    local searchString = ""
    for _,v in ipairs(kboard.leaderboardColumns) do
        if (v.sqlID == "Money") then continue end
        searchString = searchString..v.sqlID..","
    end
    searchString = string.sub(searchString, 0, #searchString - 1)

    kboard.leaderboardTbl = sql.Query("SELECT "..searchString.." FROM "..kboard.Server.clientTable.." ORDER BY "..kboard.leaderboardSortBy.." DESC LIMIT "..kboard.leaderboardRows) -- Update Sent Table
    
end)

hook.Add("PlayerInitialSpawn", "kboard_CreatePlayerEntry", function(ply) -- Add new player into table
    ply.kboardRequest = false -- variables to debounce messages
    ply.kboardOpen = false

    local query = sql.QueryValue("SELECT SteamID FROM "..kboard.Server.clientTable.." WHERE SteamID = '"..ply:SteamID().."'")

    if (query == false or query == nil) then -- If new player, then add into table, otherwise do nothing.
        ply:kboard_newPlayer()
        kboard.incrementStat("UniquePlayers")
    end

    ply:SetVar("kboard_DamageDealt", 0) -- Set Var for player
    ply:SetVar("kboard_DamageTaken", 0) -- Set Var for player

    sql.Query("UPDATE "..kboard.Server.clientTable.." SET Name = '"..ply:Nick().."' WHERE SteamID = '"..ply:SteamID().."'") -- Update Name in Leaderboard.
end)

function kboard.sortQuery(SearchString, SortBy, limit)
    return 
end

net.Receive("kboard_RequestPageData", function(len,ply) -- Player Request next/previous page, so get its data.
    if (ply.kboardRequest == true) then ply:kboard_OnError(kboard.errors.QuerySpam) return  end -- debouncing requests from players
    ply.kboardRequest = true
    timer.Simple(kboard.requestCooldown, function() ply.kboardRequest = false end)

    local state = net.ReadInt(3)
    local page = net.ReadUInt(16)
    local totalPages = tonumber(sql.QueryValue("SELECT COUNT(*) FROM "..kboard.Server.clientTable))
    if (not isnumber(page) || not isnumber(state)) then ply:kboard_OnError(kboard.errors.InvalidQuery.." (Server PageRequest)") return end
    if ((state == 1) && (page < totalPages)) then page = page + 1 
    elseif ((state == -1) && (page > 1)) then page = page - 1 else return end
    
    local offset = (page - 1) * kboard.leaderboardRows
    local searchString = ""
    for _,v in ipairs(kboard.leaderboardColumns) do
        if (v.sqlID == "Money") then continue end
        searchString = searchString..v.sqlID..","
    end
    searchString = string.sub(searchString, 0, #searchString - 1)

    local str = "SELECT "..searchString.." FROM "..kboard.Server.clientTable.." WHERE PRounds > '"..kboard.sortMinRounds.."' ORDER BY "..ply.kboard_sortby.." DESC LIMIT "..offset..","..kboard.leaderboardRows

    local newTable = sql.Query(str)
    if (not istable(newTable)) then return end
    newTable = util.TableToJSON(newTable)
    if (not isstring(newTable)) then return end
    newTable = util.Compress(newTable)
    if (not isstring(newTable)) then return end

    local tableLen = #newTable

    net.Start("kboard_SendPageData")
        net.WriteUInt(page, 16)
        net.WriteData(newTable, tableLen)
    net.Send(ply)
end)

net.Receive("kboard_RequestPlayerData", function(len,ply)
    if (ply.kboardRequest == true) then ply:kboard_OnError(kboard.errors.QuerySpam) return  end -- debouncing requests from players
    ply.kboardRequest = true
    timer.Simple(kboard.requestCooldown, function() ply.kboardRequest = false end)

    local steamid = net.ReadString()
    if (not isstring(steamid)) then ply:kboard_OnError(kboard.errors.InvalidQuery.." (Server Invalid SteamID)") return end

    local query = sql.QueryRow("SELECT * FROM "..kboard.Server.clientTable.." WHERE SteamID = '"..steamid.."'")
    if (not istable(query)) then ply:kboard_OnError(kboard.errors.InvalidQuery.." (Server PlayerData1)") return end

    query = util.TableToJSON(query)
    if (not isstring(query)) then ply:kboard_OnError(kboard.errors.InvalidQuery.." (Server PlayerData2)") return end

    query = util.Compress(query)
    if (not isstring(query)) then ply:kboard_OnError(kboard.errors.InvalidQuery.." (Server PlayerData3)") return end

    local tblLen = #query

    net.Start("kboard_SendPlayerData")
        net.WriteData(query, tblLen)
    net.Send(ply)
end)

hook.Add("PlayerButtonUp", "kboard_OpenMenuBind", function(ply, key) -- Player opened the menu.
    if (key == kboard.bind) then 
        ply:ConCommand("kleaderboards_Open")
    end
end)

local kboard_commands = {} -- New table for commands
for _, v in ipairs(kboard.ChatCommand) do
	kboard_commands[v] = true
end

hook.Add("PlayerSay", "kboard_OpenMenu", function(ply, str) -- check whether the command was used or not.
    if (kboard_commands[string.lower(str)]) then
        ply:ConCommand("kleaderboards_Open")        
        if (kboard.showCommandInChat) then return str else return "" end
    end
end)

timer.Create("kboard_playerDamageTimer", kboard.PlayerDamageTimer, 0, kboard.plyDamageTimer) -- Timer to periodically update player damage
timer.Create("kboard_serverDamageTimer", kboard.ServerDamageTimer, 0, kboard.damageTimer) -- Timer to periodically update server damage
