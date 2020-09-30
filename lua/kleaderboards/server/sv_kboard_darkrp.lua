local meta = FindMetaTable("Player")

hook.Add("Initialize", "kboard_terrortownInitialize", function()

    if (not sql.TableExists(kboard.Server.clientTable)) then -- Create Data Table
        sql.Query("CREATE TABLE "..kboard.Server.clientTable.."(Name TEXT, SteamID TEXT, Kills INTEGER, Deaths INTEGER, KD FLOAT, DamageDealt INTEGER, DamageTaken INTEGER, Arrests INTEGER, Arrested INTEGER, JobChanges INTEGER, LockPicks INTEGER, PropsSpawned INTEGER)")        
        print("[KLeaderboards] DarkRP Client Stats Database Created!")
    else
        print("[KLeaderboards] DarkRP Client Stats Database already Exists")
    end

    if (!sql.TableExists(kboard.Server.serverTable)) then -- Create Data Table
        sql.Query("CREATE TABLE "..kboard.Server.serverTable.."(Kills INTEGER, Deaths INTEGER, DamageDealt INTEGER, DamageTaken INTEGER, Arrests INTEGER, JobChanges INTEGER, LockPicks INTEGER, PropsSpawned INTEGER)")        
        sql.Query("INSERT INTO "..kboard.Server.serverTable.."(Kills, Deaths, DamageDealt, DamageTaken, Arrests, JobChanges, LockPicks, PropsSpawned) VALUES(0,0,0,0,0,0,0,0)")

        print("[KLeaderboards] DarkRP Server Stats Database Created!")
    else
        print("[KLeaderboards] DarkRP Server Stats Database already Exists")
    end

    if !sql.TableExists(kboard.Server.weaponTable) then -- Create dynamic sql table for weapons.
        sql.Query("CREATE TABLE "..kboard.Server.weaponTable.."(id INTEGER)")
        sql.Query("INSERT INTO "..kboard.Server.weaponTable.."(id) VALUES(1)")
        print("[KLeaderboards] DarkRP Weapon Stats Database Created!")
    else 
        print("[KLeaderboards] DarkRP Weapon Stats Database already Exists")
    end

    for k,v in ipairs(kboard.weaponList) do -- Adds the weapons in the list to the table database
        kboard.addWeaponToDatabase(v.sqlname, kboard.Server.weaponTable)
    end
end)

-- Special Net Recieve for DarkRP -- 
net.Receive("kboard_RequestSortPage", function(len,ply)
    if (ply.kboardRequest == true) then ply:kboard_CMSG(kboard.errors.QuerySpam) return  end -- debouncing requests from players
    ply.kboardRequest = true
    timer.Simple(kboard.requestCooldown, function() ply.kboardRequest = false end)
    
    if (not ply:IsPlayer()) then return end
    local sortby = net.ReadString()
    if (not isstring(sortby)) then ply:kboard_CMSG(kboard.errors.InvalidQuery) return end

    local searchString = ""
    for _,v in ipairs(kboard.leaderboardColumns) do
        if (v.sqlID == "Money") then continue end
        searchString = searchString..v.sqlID..","
    end
    searchString = string.sub(searchString, 0, #searchString - 1)

    local leaderboardData = sql.Query("SELECT "..searchString.." FROM "..kboard.Server.clientTable.." ORDER BY "..sortby.." DESC LIMIT "..kboard.leaderboardRows)
    if (not istable(leaderboardData)) then ply:kboard_CMSG(kboard.errors.InvalidQuery.." Server leaderboardTable0") return end 

    for k,v in ipairs(leaderboardData) do
        local plyTable = {}

        table.Empty(plyTable)
        
        local steamID64 = util.SteamIDTo64(v.SteamID)
        local query = tonumber(sql.QueryValue("SELECT wallet FROM darkrp_player WHERE uid = '"..steamID64.."'"))
        if (not isnumber(query)) then continue end

        leaderboardData[k]["Money"] = query
    end
    if (not istable(leaderboardData)) then ply:kboard_CMSG(kboard.errors.InvalidQuery.." Server leaderboardTable1") return end 

    local leaderboardData = util.TableToJSON(leaderboardData)
    if (not isstring(leaderboardData)) then ply:kboard_CMSG(kboard.errors.InvalidQuery.." Server leaderboardTable2") return end

    leaderboardData = util.Compress(leaderboardData)
    if (not isstring(leaderboardData)) then ply:kboard_CMSG(kboard.errors.InvalidQuery.." Server leaderboardTable3") return end

    local leaderboardlen = #leaderboardData

    local pages = sql.QueryValue("SELECT COUNT(*) FROM "..kboard.Server.clientTable)
    pages = pages/kboard.leaderboardRows
    pages = math.floor(pages)
    if (pages < 1) then pages = 1 end

    net.Start("kboard_SendSortPage")
        net.WriteUInt(pages, 16)
        net.WriteUInt(leaderboardlen, 16)

        net.WriteData(leaderboardData, leaderboardlen)
    net.Send(ply)
end)

-- DarkRP Specific Hooks --

hook.Add("DoPlayerDeath", "kboard_terrortownDeaths", function(victim, attacker, dmg)
    victim:kboard_increaseDeaths(kboard.Server.clientTable)--  Increase Deaths
    victim:kboard_setKD(kboard.Server.clientTable) -- set KD
    kboard.incrementStat("Deaths",kboard.Server.serverTable)

    if (victim == attacker) then return end -- make sure it's not suicide
    if (!attacker:IsPlayer()) then return end -- make sure attacker is player

    attacker:kboard_increaseKills(kboard.Server.clientTable) -- Increase General Kills
    attacker:kboard_setKD(kboard.Server.clientTable)
    kboard.incrementStat("Kills",kboard.Server.serverTable)

    if (!attacker:GetActiveWeapon():IsWeapon()) then return end  -- make sure player has weapon
    
    local weapon = attacker:GetActiveWeapon():GetClass()
    for k,v in pairs(kboard.weaponList) do
        if (v.id == weapon) then
            attacker:kboard_increaseWeaponKills(v.sqlname,kboard.Server.clientTable)
            kboard.incrementWeaponKills(v.sqlname, kboard.Server.weaponTable)
            break
        end
    end

end)

hook.Add("EntityTakeDamage","kboard_darkrpDamage", function(ply, dmg)
    if (not ply:IsPlayer()) then return end
    local attacker = dmg:GetAttacker()

    local amount = dmg:GetDamage()
    kboard.Server.Damage = kboard.Server.Damage + amount

    local victimDamage = ply:GetVar("kboard_DamageTaken")
    if (not isnumber(victimDamage)) then victimDamage = 0 end
    ply:SetVar("kboard_DamageTaken", (victimDamage + amount))
    
    if (not attacker:IsPlayer()) then return end

    local attackerDamage = attacker:GetVar("kboard_DamageDealt")
    if (not isnumber(attackerDamage)) then attackerDamage = 0 end
    attacker:SetVar("kboard_DamageDealt", (attackerDamage + amount))
end)

hook.Add("playerArrested", "kboard_darkrpArrested", function(criminal, time, actor)
    if (criminal:IsPlayer() && actor:IsPlayer()) then
        actor:kboard_incrementArrests()
        criminal:kboard_incrementArrested() 
        kboard.incrementArrests()
    end
end)

hook.Add("OnPlayerChangedTeam", "kboard_darkrpJobChange", function(ply, before, after)
    if (ply:IsPlayer()) then
        ply:kboard_incrementJobChange()
        kboard.incrementJobChanges()
    end
end)

hook.Add("onLockpickCompleted", "kboard_darkrpLockPick", function(ply, success)
    if (ply:IsPlayer() && success) then
        ply:kboard_incrementLockPicks()
        kboard.incrementLockPicks()
    end
end)

hook.Add("PlayerSpawnedProp", "test", function(ply)
    if (ply:IsPlayer()) then
        ply:kboard_incrementPropsSpawned()
        kboard.incrementPropsSpawned()
    end
end)

-- DarkRP Speicifc Functions --

function meta:kboard_newPlayer()
    if (not IsValid(self)) || not self:IsPlayer() then return end

    local steamID = self:SteamID()
    local query = sql.Query("INSERT INTO "..kboard.Server.clientTable.."(Name, SteamID, Kills, Deaths, KD, DamageDealt, DamageTaken, Arrests, Arrested, JobChanges, LockPicks, PropsSpawned) VALUES('"..self:Nick().."','"..steamID.."',0,0,0.0,0,0,0,0,0,0,0)")
    for _,v in ipairs(kboard.weaponList) do
        sql.Query("UPDATE "..kboard.Server.clientTable.." SET "..v.name.." = '0' WHERE SteamID = '"..steamID.."'")
    end
end

function meta:kboard_incrementArrests()
    local steamid = self:SteamID()
    local query = tonumber(sql.QueryValue("SELECT Arrests FROM "..kboard.Server.clientTable.." WHERE SteamID = '"..steamid.."'"))
    
    if (isnumber(query)) then query = query + 1 else query = 1 end

    sql.Query("UPDATE "..kboard.Server.clientTable.." SET Arrests = '"..query.."' WHERE SteamID = '"..steamid.."'")
end

function meta:kboard_incrementArrested()
    local steamid = self:SteamID()
    local query = tonumber(sql.QueryValue("SELECT Arrested FROM "..kboard.Server.clientTable.." WHERE SteamID = '"..steamid.."'"))
    
    if (isnumber(query)) then query = query + 1 else query = 1 end

    sql.Query("UPDATE "..kboard.Server.clientTable.." SET Arrested = '"..query.."' WHERE SteamID = '"..steamid.."'")
end

function meta:kboard_incrementJobChange()
    local steamid = self:SteamID()
    local query = tonumber(sql.QueryValue("SELECT JobChanges FROM "..kboard.Server.clientTable.." WHERE SteamID = '"..steamid.."'"))
    
    if (isnumber(query)) then query = query + 1 else query = 1 end

    sql.Query("UPDATE "..kboard.Server.clientTable.." SET JobChanges = '"..query.."' WHERE SteamID = '"..steamid.."'")
end

function meta:kboard_incrementPropsSpawned()
    local steamid = self:SteamID()
    local query = tonumber(sql.QueryValue("SELECT PropsSpawned FROM "..kboard.Server.clientTable.." WHERE SteamID = '"..steamid.."'"))
    
    if (isnumber(query)) then query = query + 1 else query = 1 end

    sql.Query("UPDATE "..kboard.Server.clientTable.." SET PropsSpawned = '"..query.."' WHERE SteamID = '"..steamid.."'")
end

function meta:kboard_incrementLockPicks()
    local steamid = self:SteamID()
    local query = tonumber(sql.QueryValue("SELECT LockPicks FROM "..kboard.Server.clientTable.." WHERE SteamID = '"..steamid.."'"))

    if (isnumber(query)) then query = query + 1 else query = 1 end

    sql.Query("UPDATE "..kboard.Server.clientTable.." SET LockPicks = '"..query.."' WHERE SteamID = '"..steamid.."'")
end

function kboard.incrementLockPicks()
    local query = tonumber(sql.QueryValue("SELECT LockPicks FROM "..kboard.Server.serverTable))

    if (isnumber(query)) then query = query + 1 else query = 1 end

    sql.Query("UPDATE "..kboard.Server.serverTable.." SET LockPicks = '"..query.."'")
end

function kboard.incrementArrests()
    local query = tonumber(sql.QueryValue("SELECT Arrests FROM "..kboard.Server.serverTable))

    if (isnumber(query)) then query = query + 1 else query = 1 end

    sql.Query("UPDATE "..kboard.Server.serverTable.." SET Arrests = '"..query.."'")
end

function kboard.incrementJobChanges()
    local query = tonumber(sql.QueryValue("SELECT JobChanges FROM "..kboard.Server.serverTable))

    if (isnumber(query)) then query = query + 1 else query = 1 end

    sql.Query("UPDATE "..kboard.Server.serverTable.." SET JobChanges = '"..query.."'")
end

function kboard.incrementPropsSpawned()
    local query = tonumber(sql.QueryValue("SELECT PropsSpawned FROM "..kboard.Server.serverTable))
    if (isnumber(query)) then query = query + 1 else query = 1 end

    sql.Query("UPDATE "..kboard.Server.serverTable.." SET PropsSpawned = '"..query.."'")
end

function meta:kboard_SendAddonData() -- Function runs everytime the player joins
    if (not IsValid(self)) || (not self:IsPlayer()) then return end

    local searchString = ""
    for _,v in ipairs(kboard.leaderboardColumns) do
        if (v.sqlID == "Money") then continue end
        searchString = searchString..v.sqlID..","
    end
    searchString = string.sub(searchString, 0, #searchString - 1)

    local leaderboardData = sql.Query("SELECT "..searchString.." FROM "..kboard.Server.clientTable.." ORDER BY "..kboard.leaderboardSortBy.." DESC LIMIT "..kboard.leaderboardRows)
    if (not istable(leaderboardData)) then self:kboard_CMSG(kboard.errors.InvalidQuery.." Server leaderboardTable0") return end 

    for k,v in ipairs(leaderboardData) do
        local plyTable = {}

        table.Empty(plyTable)
        
        local steamID64 = util.SteamIDTo64(v.SteamID)
        local query = tonumber(sql.QueryValue("SELECT wallet FROM darkrp_player WHERE uid = '"..steamID64.."'"))
        if (not isnumber(query)) then continue end

        leaderboardData[k]["Money"] = query
    end
    if (not istable(leaderboardData)) then self:kboard_CMSG(kboard.errors.InvalidQuery.." Server leaderboardTable1") return end 

    local leaderboardConvert = util.TableToJSON(leaderboardData)
    if (not isstring(leaderboardConvert)) then self:kboard_CMSG(kboard.errors.InvalidQuery.." Server leaderboardTable2") return end

    leaderboardConvert = util.Compress(leaderboardConvert)
    if (not isstring(leaderboardConvert)) then self:kboard_CMSG(kboard.errors.InvalidQuery.." Server leaderboardTable3") return end


    local totalPlayers = sql.QueryValue("SELECT COUNT(*) FROM "..kboard.Server.clientTable)
    local serverData = sql.Query("SELECT * FROM "..kboard.Server.serverTable)
    if (not istable(serverData)) then self:kboard_CMSG(kboard.errors.InvalidQuery) return end 
    serverData[1]["UniquePlayers"] = totalPlayers

    serverData = util.TableToJSON(serverData)
    if (not isstring(serverData)) then self:kboard_CMSG(kboard.errors.InvalidQuery.." Server serverTable2") return end

    serverData = util.Compress(serverData)
    if (not isstring(serverData)) then self:kboard_CMSG(kboard.errors.InvalidQuery.." Server serverTable3") return end

    local weaponsData = sql.Query("SELECT * FROM "..kboard.Server.weaponTable)
    if (not istable(weaponsData)) then self:kboard_CMSG(kboard.errors.InvalidQuery.." Server weaponsTable1") return end

    weaponsData = util.TableToJSON(weaponsData)
    if (not isstring(weaponsData)) then self:kboard_CMSG(kboard.errors.InvalidQuery.." Server weaponsTable2") return end

    weaponsData = util.Compress(weaponsData)
    if (not isstring(weaponsData)) then self:kboard_CMSG(kboard.errors.InvalidQuery.." Server weaponsTable3") return end

    local leaderboardlen = #leaderboardConvert
    local serverlen = #serverData
    local weaponslen = #weaponsData

    local pages = sql.QueryValue("SELECT COUNT(*) FROM "..kboard.Server.clientTable)
    pages = pages/kboard.leaderboardRows
    pages = math.floor(pages)
    if (pages < 1) then pages = 1 end

    net.Start("kboard_openMenu")
        net.WriteUInt(pages, 16)
        net.WriteUInt(leaderboardlen, 16)
        net.WriteUInt(serverlen,16)
        net.WriteUInt(weaponslen,16)

        net.WriteData(leaderboardConvert, leaderboardlen)
        net.WriteData(serverData, serverlen)
        net.WriteData(weaponsData, weaponslen)

    net.Send(self)
end

-- DarkRP Console Command --
concommand.Add("kleaderboards_Open", function(ply) -- Console Command to open the menu.
    if (ply.kboardOpen == true) then ply:kboard_CMSG(kboard.errors.MenuSpam) return end
    ply.kboardOpen = true
    timer.Simple(kboard.requestCooldown, function() ply.kboardOpen = false  end) -- Debouncing player Network messaging

    ply:kboard_SendAddonData()
end)