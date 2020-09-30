-- This file includes non-gamemode specific functions in the addon --
include("kleaderboards/shared/sh_kboard.lua")

local meta = FindMetaTable("Player")

function kboard.addWeaponToDatabase(weapon, database)
    local query = sql.Query("ALTER TABLE "..database.." ADD "..weapon.." INTEGER")
    
    if (query == false) then
        print("[KLeaderboard] Failed to add "..weapon.." to "..database.."("..sql.LastError()..")")
        return
    end        
    print("[KLeaderboard] "..weapon.." Added To "..database)
end

function meta:kboard_increaseKills()
    if (not IsValid(self)) || not self:IsPlayer() then return end

    local steamID = self:SteamID()
    local query = tonumber(sql.QueryValue("SELECT Kills FROM "..kboard.Server.clientTable.." WHERE SteamID = '"..steamID.."'"))

    if (isnumber(query)) then query = query + 1 else query = 1 end
    sql.Query("UPDATE "..kboard.Server.clientTable.." SET Kills = '"..query.."' WHERE SteamID = '"..steamID.."'")
end

function meta:kboard_increaseWeaponKills(weapon)
    if (not IsValid(self)) || not self:IsPlayer() then return end
    local steamID = self:SteamID()
    local query = tonumber(sql.QueryValue("SELECT "..weapon.." FROM "..kboard.Server.clientTable.." WHERE SteamID = '"..steamID.."'"))
    if (isnumber(query)) then query = query + 1 else query = 1 end
    sql.Query("UPDATE "..kboard.Server.clientTable.." SET "..weapon.." = '"..query.."' WHERE SteamId = '"..steamID.."'")
end

function meta:kboard_increaseDeaths()
    if (not IsValid(self)) || not self:IsPlayer() then return end

    local steamID = self:SteamID()
    local query = tonumber(sql.QueryValue("SELECT Deaths FROM "..kboard.Server.clientTable.." WHERE SteamID = '"..steamID.."'"))
    if (isnumber(query)) then query = query + 1 else query = 1 end
    sql.Query("UPDATE "..kboard.Server.clientTable.." SET Deaths = '"..query.."' WHERE SteamID = '"..steamID.."'")
end

function meta:kboard_setKD()
    if (not IsValid(self)) || not self:IsPlayer() then return end

    local steamID = self:SteamID()
    local kills = tonumber(sql.QueryValue("SELECT Kills FROM "..kboard.Server.clientTable.." WHERE SteamID = '"..steamID.."'"))
    local deaths = tonumber(sql.QueryValue("SELECT Deaths FROM "..kboard.Server.clientTable.." WHERE SteamID = '"..steamID.."'"))

    if (not isnumber(kills)) then kills = 0 end
    if (not isnumber(deaths) || deaths == 0) then deaths = 1 end
    local KDRatio = kills/deaths
    KDRatio = math.Round(KDRatio,2)

    sql.Query("UPDATE "..kboard.Server.clientTable.." SET KD = '"..KDRatio.."' WHERE SteamID = '"..steamID.."'")
end

function meta:kboard_addPlayerDamage(type,amount)
    if (not IsValid(self)) || not self:IsPlayer() then return end
    if (amount < 1) then return end
    if (amount > 6000) then amount = 6000 end

    local steamID = self:SteamID()
    local query = tonumber(sql.QueryValue("SELECT "..type.." FROM "..kboard.Server.clientTable.." WHERE SteamID = '"..steamID.."'"))

    if (isnumber(query)) then query = math.floor(query + amount) else query = 1 end

    sql.Query("UPDATE "..kboard.Server.clientTable.." SET "..type.." = '"..query.."' WHERE SteamID = '"..steamID.."'")
end

function kboard.damageTimer() -- Calls this function once every minute rather than calling it for every damage taken, which would be highly inefficient

    kboard.incrementDamage("DamageDealt",kboard.Server.Damage, kboard.Server.serverTable)
    kboard.incrementDamage("DamageTaken",kboard.Server.Damage, kboard.Server.serverTable)
    kboard.Server.Damage = 0
end

function kboard.plyDamageTimer() -- Calls this function once every minute rather than calling it for every damage taken, which would be highly inefficient
    for _,ply in ipairs(player.GetAll()) do
        local dmgDealt = ply:GetVar("kboard_DamageDealt")
        if (dmgDealt != 0) then 
            ply:kboard_addPlayerDamage("DamageDealt", dmgDealt)
            ply:SetVar("kboard_DamageDealt", 0)
        end
        local dmgTaken = ply:GetVar("kboard_DamageTaken")
        if (dmgTaken != 0) then 
            ply:kboard_addPlayerDamage("DamageTaken", dmgTaken)
            ply:SetVar("kboard_DamageTaken", 0)
        end
    end
end

function kboard.incrementWeaponKills(weapon)
    local query = tonumber(sql.QueryValue("SELECT "..weapon.." FROM "..kboard.Server.weaponTable))
    
    if (isnumber(query)) then query = query + 1 else query = 1 end
    sql.Query("UPDATE "..kboard.Server.weaponTable.." SET "..weapon.." = '"..query.."'")
end

function kboard.incrementStat(stat)
    local query = tonumber(sql.QueryValue("SELECT "..stat.." FROM "..kboard.Server.serverTable))

    if (isnumber(query)) then query = query + 1 else query = 1 end
    sql.Query("UPDATE "..kboard.Server.serverTable.." SET "..stat.." = '"..query.."'")
end

function kboard.incrementDamage(type, amount)
    if (amount < 1) then return end
    if (amount > 6000) then amount = 6000 end
    local query = tonumber(sql.QueryValue("SELECT "..type.." FROM "..kboard.Server.serverTable))

    if (isnumber(query)) then query = query + amount else query = 1 end
    query = math.floor(query)
    sql.Query("UPDATE "..kboard.Server.serverTable.." SET "..type.." = '"..query.."'")
end

function meta:kboard_CMSG(msg)
    if (not isstring(msg) || not self:IsPlayer() || not IsValid(self)) then return end

    net.Start("kboard_SendMessage")
        net.WriteString(msg)
    net.Send(self)
end 