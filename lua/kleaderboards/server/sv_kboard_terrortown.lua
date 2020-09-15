local meta = FindMetaTable("Player")

hook.Add("Initialize", "kboard_terrortownInitialize", function()

    if (not sql.TableExists(kboard.Server.clientTable)) then -- Create Data Table
        sql.Query("CREATE TABLE "..kboard.Server.clientTable.."(Name TEXT, SteamID TEXT, Kills INTEGER, Deaths INTEGER, TRounds INTEGER, DRounds INTEGER, IRounds INTEGER, Logins INTEGER, PRounds INTEGER, WinRate FLOAT, KD FLOAT, DamageDealt INTEGER, DamageTaken INTEGER)")        
        print("[KLeaderboards] TerrorTown Database Created!")
    else
        print("[KLeaderboards] TerrorTown Database already Exists")
    end

    if (!sql.TableExists(kboard.Server.serverTable)) then -- Create Data Table
        sql.Query("CREATE TABLE "..kboard.Server.serverTable.."(Kills INTEGER, Deaths INTEGER, DamageDealt INTEGER, DamageTaken INTEGER, EquipmentBought INTEGER, BodiesFound INTEGER, UniquePlayers INTEGER, TraitorWin INTEGER, InnocentWin INTEGER,TotalRounds INTEGER)")        
        sql.Query("INSERT INTO "..kboard.Server.serverTable.."(Kills, Deaths, DamageDealt, DamageTaken, EquipmentBought, BodiesFound, UniquePlayers,TraitorWin, InnocentWin,TotalRounds) VALUES(0,0,0,0,0,0,0,0,0,0)")

        print("[KLeaderboards] TerrorTown Server Stats Database Created!")
    else
        print("[KLeaderboards] TerrorTown Server Stats Database already Exists")
    end

    if !sql.TableExists(kboard.Server.weaponTable) then -- Create dynamic sql table for weapons.
        sql.Query("CREATE TABLE "..kboard.Server.weaponTable.."(id INTEGER)")
        sql.Query("INSERT INTO "..kboard.Server.weaponTable.."(id) VALUES(1)")
        print("[KLeaderboards] TerrorTown Weapon Stats Database Created!")
    else 
        print("[KLeaderboards] TerrorTown Weapon Stats Database already Exists")
    end

    for k,v in ipairs(kboard.weaponList) do -- Adds the weapons in the list to the table database
        kboard.addWeaponToDatabase(v.sqlname, kboard.Server.weaponTable)
        kboard.addWeaponToDatabase(v.sqlname, kboard.Server.clientTable)
    end
    
end)

-- Special Net Recieve for DarkRP -- 
net.Receive("kboard_RequestSortPage", function(len,ply)
    if (ply.kboardRequest == true) then ply:kboard_OnError(kboard.errors.QuerySpam) return  end -- debouncing requests from players
    ply.kboardRequest = true
    timer.Simple(kboard.requestCooldown, function() ply.kboardRequest = false end)

    if (not ply:IsPlayer()) then return end
    local sortby = net.ReadString()
    if (not isstring(sortby)) then ply:kboard_OnError(kboard.errors.InvalidQuery) return end
    ply.kboard_sortby = sortby
    local searchString = ""
    for _,v in ipairs(kboard.leaderboardColumns) do
        if (v.sqlID == "Money") then continue end
        searchString = searchString..v.sqlID..","
    end
    searchString = string.sub(searchString, 0, #searchString - 1)

    local str = "SELECT "..searchString.." FROM "..kboard.Server.clientTable.." WHERE PRounds > '"..kboard.sortMinRounds.."' ORDER BY "..ply.kboard_sortby.." DESC LIMIT "..kboard.leaderboardRows
    
    local leaderboardData = sql.Query(str)
    if (not istable(leaderboardData)) then ply:kboard_OnError(kboard.errors.InvalidQuery.." Server leaderboardTable1") return end 

    local leaderboardData = util.TableToJSON(leaderboardData)
    if (not isstring(leaderboardData)) then ply:kboard_OnError(kboard.errors.InvalidQuery.." Server leaderboardTable2") return end

    leaderboardData = util.Compress(leaderboardData)
    if (not isstring(leaderboardData)) then ply:kboard_OnError(kboard.errors.InvalidQuery.." Server leaderboardTable3") return end

    local leaderboardlen = #leaderboardData

    local pages = sql.QueryValue("SELECT COUNT(*) FROM "..kboard.Server.clientTable.." WHERE PRounds > '"..kboard.sortMinRounds.."'")
    pages = pages/kboard.leaderboardRows
    pages = math.floor(pages)
    if (pages < 1) then pages = 1 end

    net.Start("kboard_SendSortPage")
        net.WriteUInt(pages, 16)
        net.WriteUInt(leaderboardlen, 16)
        net.WriteString(ply.kboard_sortby)

        net.WriteData(leaderboardData, leaderboardlen)
    net.Send(ply)
end)

-- TTT Specific Hooks -- 
hook.Add("TTTOrderedEquipment", "kboard_terrortowntItems", function()
    kboard.incrementBoughtItems(kboard.Server.serverTable)
end)

hook.Add("TTTBodyFound", "kboard_terrortownBodies", function()
    kboard.incrementBodies(kboard.Server.serverTable)
end)

hook.Add("PlayerInitialSpawn", "kboard_terrortownJoin", function(ply)
    ply:kboard_setWinRate() -- Make Sure WinRate is Set
end)

hook.Add("DoPlayerDeath", "kboard_terrortownDeaths", function(victim, attacker, dmg)
    if (kboard.enableSpecDM) then
        kboard.allowSpecDMKills(victim,attacker,dmg) -- Function for when SpecDM kills are allowed.
    else
        kboard.disallowSpecDMKills(victim,attacker,dmg)-- Function for when SpecDM kills are disallowed.
    end
end)

hook.Add("EntityTakeDamage","kboard_terrortownDamage", function(ply, dmg)
    if (kboard.enableSpecDM) then
        kboard.allowSpecDMDamage(ply, dmg)
    else
        kboard.disallowSpecDMDamage(ply, dmg)-- Function for when SpecDM Damage is disallowed.
    end
end)

hook.Add("TTTEndRound", "kboard_CheckForWins", function(result) -- WIN_TRAITOR | WIN_INNOCENT | WIN_TIMELIMIT
    kboard.incrementStat("TotalRounds")
    
    if (result == WIN_TRAITOR) then
        kboard.incrementStat("TraitorWin")
    else     
        kboard.incrementStat("InnocentWin")
    end

    for _,ply in pairs(player.GetAll()) do  -- Increase Wins/Rounds for players and server.
        ply:kboard_increaseWins("PRounds")
        kboard.incrementStat("InnocentWin")

        if (not ply:Alive() || ply:IsSpec()) then ply:kboard_setWinRate() continue end

        if (result == WIN_TRAITOR && ply:IsTraitor()) then
            ply:kboard_increaseWins("TRounds")
            continue
        elseif ((result != WIN_TRAITOR) && ply:IsDetective()) then
            ply:kboard_increaseWins("DRounds")
            continue
        elseif ((result != WIN_TRAITOR) && (not ply:IsTraitor())) then
            ply:kboard_increaseWins("IRounds")
        end
        ply:kboard_setWinRate()
    end

    local searchString = ""
    for _,v in ipairs(kboard.leaderboardColumns) do
        if (v.sqlID == "Money") then continue end
        searchString = searchString..v.sqlID..","
    end
    searchString = string.sub(searchString, 0, #searchString - 1)

    kboard.leaderboardTbl = sql.Query("SELECT "..searchString.." FROM "..kboard.Server.clientTable.." ORDER BY "..kboard.leaderboardSortBy.." DESC LIMIT "..kboard.leaderboardRows) -- Update Sent Table
end)

-- TTT Specific ConCommand --

concommand.Add("kleaderboards_Open", function(ply) -- Console Command to open the menu.

    if (ply.kboardOpen == true) then ply:kboard_OnError(kboard.errors.MenuSpam) return end
    ply.kboardOpen = true
    timer.Simple(kboard.requestCooldown, function() ply.kboardOpen = false  end) -- Debouncing player Network messaging

    if (not kboard.allowGhosting) then -- check whether ghosting is allowed.
        if (GetRoundState() == ROUND_ACTIVE && ply:Alive() && !ply:IsSpec()) then -- if ghosting is not allowed then leave. 
            ply:kboard_OnError(kboard.errors.RoundActive)
            return
        end
    end
    ply:kboard_SendAddonData()
end)

-- TTT Specific Functions --

function meta:kboard_newPlayer()
    if (not IsValid(self)) || not self:IsPlayer() then return end

    local steamID = self:SteamID()
    local query = sql.Query("INSERT INTO "..kboard.Server.clientTable.."(Name, SteamID, Kills, Deaths, TRounds, DRounds, IRounds, PRounds, WinRate, KD, DamageDealt, DamageTaken) VALUES('"..self:Nick().."','"..steamID.."', 0, 0, 0, 0, 0, 0, 0.0, 0.0,0,0)")
    for _,v in ipairs(kboard.weaponList) do
        sql.Query("UPDATE "..kboard.Server.clientTable.." SET "..v.name.." = '0' WHERE SteamID = '"..steamID.."'")
    end
end

function kboard.incrementBoughtItems()
    local query = tonumber(sql.QueryValue("SELECT EquipmentBought FROM "..kboard.Server.serverTable))

    if (isnumber(query)) then query = query + 1 else query = 1 end
    sql.Query("UPDATE "..kboard.Server.serverTable.." SET EquipmentBought = '"..query.."'")
end

function kboard.incrementBodies()
    local query = tonumber(sql.QueryValue("SELECT BodiesFound FROM "..kboard.Server.serverTable))

    if (isnumber(query)) then query = query + 1 else query = 1 end
    sql.Query("UPDATE "..kboard.Server.serverTable.." SET BodiesFound = '"..query.."'")
end

function kboard.allowSpecDMKills(victim,attacker,dmg)

    local amount = dmg:GetDamage()
    victim:kboard_increaseDeaths()--  Increase Deaths
    victim:kboard_setKD() -- set KD
    kboard.incrementStat("Deaths")

    if (victim == attacker) then return end -- make sure it's not suicide
    if (!attacker:IsPlayer()) then return end -- make sure attacker is player

    attacker:kboard_increaseKills() -- Increase General Kills
    attacker:kboard_setKD()
    kboard.incrementStat("Kills")

    if (!attacker:GetActiveWeapon():IsWeapon()) then return end  -- make sure player has weapon
    
    local weapon = attacker:GetActiveWeapon():GetClass()
    for k,v in pairs(kboard.weaponList) do
        if (v.id == weapon) then
            attacker:kboard_increaseWeaponKills(v.sqlname)
            kboard.incrementWeaponKills(v.sqlname)
            break
        end
    end
end

function kboard.disallowSpecDMKills(victim,attacker,dmg)
    if (victim:GetNWBool("SpecDM_Enabled") == false ) then  
        local amount = dmg:GetDamage()
        victim:kboard_increaseDeaths()--  Increase Deaths
        victim:kboard_setKD() -- set KD
        kboard.incrementStat("Deaths")
    end

    if (victim == attacker) then return end -- make sure it's not suicide
    if (!attacker:IsPlayer()) then return end -- make sure attacker is player

    if ((attacker:GetNWBool("SpecDM_Enabled") == false || victim:GetNWBool("SpecDM_Enabled") == false)) then  
        attacker:kboard_increaseKills() -- Increase General Kills
        attacker:kboard_setKD()
        kboard.incrementStat("Kills")
    
        if (!attacker:GetActiveWeapon():IsWeapon()) then return end  -- make sure player has weapon
        
        local weapon = attacker:GetActiveWeapon():GetClass()
        for k,v in pairs(kboard.weaponList) do
            if (v.id == weapon) then
                attacker:kboard_increaseWeaponKills(v.sqlname)
                kboard.incrementWeaponKills(v.sqlname)
                break
            end
        end
    end
end

function kboard.allowSpecDMDamage(ply, dmg)
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
end

function kboard.disallowSpecDMDamage(ply, dmg)
    if (not ply:IsPlayer()) then return end
    local attacker = dmg:GetAttacker()
    local amount = dmg:GetDamage()

    if (ply:GetNWBool("SpecDM_Enabled") == false) then
        local victimDamage = ply:GetVar("kboard_DamageTaken")
        if (not isnumber(victimDamage)) then victimDamage = 0 end
        ply:SetVar("kboard_DamageTaken", (victimDamage + amount))
    end

    if (ply:GetNWBool("SpecDM_Enabled") == false && attacker:GetNWBool("SpecDM_Enabled") == false) then
        kboard.Server.Damage = kboard.Server.Damage + amount
    end

    if (not attacker:IsPlayer()) then return end

    if (attacker:GetNWBool("SpecDM_Enabled") == false || ply:GetNWBool("SpecDM_Enabled") == false) then 
        local attackerDamage = attacker:GetVar("kboard_DamageDealt")
        if (not isnumber(attackerDamage)) then attackerDamage = 0 end
        attacker:SetVar("kboard_DamageDealt", (attackerDamage + amount))
    end
end

function meta:kboard_increaseWins(result)
    if ((not IsValid(self)) || not self:IsPlayer()) then return end

    local steamID = self:SteamID()
    local query = sql.QueryValue("SELECT "..result.." FROM "..kboard.Server.clientTable.." WHERE SteamID = '"..steamID.."'")
    query = tonumber(query)
    if (isnumber(query)) then query = query + 1 else query = 1 end
    sql.Query("UPDATE "..kboard.Server.clientTable.." SET "..result.." = '"..query.."' WHERE SteamID = '"..steamID.."'")
end

function meta:kboard_setWinRate()
    if (not IsValid(self)) || not self:IsPlayer() then return end

    local steamID = self:SteamID()

    local IWins   = tonumber(sql.QueryValue("SELECT IRounds FROM "..kboard.Server.clientTable.." WHERE SteamID = '"..steamID.."'"))
    local DWins   = tonumber(sql.QueryValue("SELECT DRounds FROM "..kboard.Server.clientTable.." WHERE SteamID = '"..steamID.."'"))
    local TWins   = tonumber(sql.QueryValue("SELECT TRounds FROM "..kboard.Server.clientTable.." WHERE SteamID = '"..steamID.."'"))
    local PRounds = tonumber(sql.QueryValue("SELECT PRounds FROM "..kboard.Server.clientTable.." WHERE SteamID = '"..steamID.."'"))

    if (not isnumber(IWins) || not isnumber(DWins) || not isnumber(TWins) || not isnumber(PRounds)) then return end
    if (PRounds == 0) then PRounds = 1 end
    local wonRounds = IWins + DWins + TWins
    local winRate = (wonRounds/PRounds) * 100
    winRate = math.Round(winRate, 2)
    
    sql.Query("UPDATE "..kboard.Server.clientTable.." SET WinRate = '"..winRate.."' WHERE SteamID = '"..steamID.."'")
end

function meta:kboard_SendAddonData() -- Function runs everytime the player joins
    if (not IsValid(self)) || (not self:IsPlayer()) then return end
    self.kboard_sortby = kboard.leaderboardSortBy
    local searchString = ""
    for _,v in ipairs(kboard.leaderboardColumns) do
        searchString = searchString..v.sqlID..","
    end
    searchString = string.sub(searchString, 0, #searchString - 1)

    local leaderboardData = sql.Query("SELECT "..searchString.." FROM "..kboard.Server.clientTable.." ORDER BY "..kboard.leaderboardSortBy.." DESC LIMIT "..kboard.leaderboardRows)
    if (not istable(leaderboardData)) then self:kboard_OnError(kboard.errors.InvalidQuery) return end 

    local leaderboardConvert = util.TableToJSON(leaderboardData)
    if (not isstring(leaderboardConvert)) then self:kboard_OnError(kboard.errors.InvalidQuery) return end

    leaderboardConvert = util.Compress(leaderboardConvert)
    if (not isstring(leaderboardConvert)) then self:kboard_OnError(kboard.errors.InvalidQuery) return end


    local totalPlayers = sql.QueryValue("SELECT COUNT(*) FROM "..kboard.Server.clientTable)
    local serverData = sql.Query("SELECT * FROM "..kboard.Server.serverTable)
    if (not istable(serverData)) then self:kboard_OnError(kboard.errors.InvalidQuery) return end 
    serverData["UniquePlayers"] = totalPlayers

    serverData = util.TableToJSON(serverData)
    if (not isstring(serverData)) then self:kboard_OnError(kboard.errors.InvalidQuery) return end

    serverData = util.Compress(serverData)
    if (not isstring(serverData)) then self:kboard_OnError(kboard.errors.InvalidQuery) return end



    local weaponsData = sql.Query("SELECT * FROM "..kboard.Server.weaponTable)
    if (not istable(weaponsData)) then self:kboard_OnError(kboard.errors.InvalidQuery) return end

    weaponsData = util.TableToJSON(weaponsData)
    if (not isstring(weaponsData)) then self:kboard_OnError(kboard.errors.InvalidQuery) return end

    weaponsData = util.Compress(weaponsData)
    if (not isstring(weaponsData)) then self:kboard_OnError(kboard.errors.InvalidQuery) return end

    local leaderboardlen = #leaderboardConvert
    local serverlen = #serverData
    local weaponslen = #weaponsData

    local pages = sql.QueryValue("SELECT COUNT(*) FROM "..kboard.Server.clientTable.." WHERE PRounds > '"..kboard.sortMinRounds.."'")
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
