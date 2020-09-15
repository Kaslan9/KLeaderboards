
hook.Add("Initialize", "kboard_InitializeServer", function()

    if (!sql.TableExists(kboard.Server.serverTable)) then -- Create Data Table
        sql.Query("CREATE TABLE "..kboard.Server.serverTable.."(Kills INTEGER, Deaths INTEGER, DamageDealt INTEGER, DamageTaken INTEGER, EquipmentBought INTEGER, BodiesFound INTEGER, UniquePlayers INTEGER, TraitorWin INTEGER, InnocentWin INTEGER,TotalRounds INTEGER)")        
        sql.Query("INSERT INTO "..kboard.Server.serverTable.."(Kills, Deaths, DamageDealt, DamageTaken, EquipmentBought, BodiesFound, UniquePlayers,TraitorWin, InnocentWin,TotalRounds) VALUES(0,0,0,0,0,0,0,0,0,0)")

        print("[KLeaderboard] Server Stats Database Created!")
    else
        print("[KLeaderboard] Server Stats Database already Exists")
    end

    if !sql.TableExists(kboard.Server.weaponTable) then -- Create dynamic sql table for weapons.
        sql.Query("CREATE TABLE "..kboard.Server.weaponTable.."(id INTEGER)")
        sql.Query("INSERT INTO "..kboard.Server.weaponTable.."(id) VALUES(1)")
        print("[KLeaderboard] Weapon Stats Database Created!")
    else 
        print("[KLeaderboard] Server Stats Database already Exists")
    end

    for k,v in ipairs(kboard.weaponList) do
        kboard.addWeaponToDatabase(v.sqlname, kboard.Server.weaponTable)
    end
end)

hook.Add("TTTOrderedEquipment", "kboard_incrementItems", function()
    kboard.incrementBoughtItems(kboard.Server.serverTable)
end)

hook.Add("TTTBodyFound", "kboard_incrementBodies", function()
    kboard.incrementBodies(kboard.Server.serverTable)
end)

-- Functions used for server stats --
function kboard.incrementWeaponKills(weapon)
    local query = tonumber(sql.QueryValue("SELECT "..weapon.." FROM "..kboard.Server.serverTable))
    
    if (isnumber(query)) then query = query + 1 else query = 1 end
    sql.Query("UPDATE "..kboard.Server.serverTable.." SET "..weapon.." = '"..query.."'")
end

function kboard.incrementStat(stat)
    local query = tonumber(sql.QueryValue("SELECT "..stat.." FROM "..kboard.Server.serverTable))

    if (isnumber(query)) then query = query + 1 else query = 1 end
    sql.Query("UPDATE "..kboard.Server.serverTable.." SET "..stat.." = '"..query.."'")
end

function kboard.incrementDamage(type, amount)
    if (amount < 1) then return end
    local query = tonumber(sql.QueryValue("SELECT "..type.." FROM "..kboard.Server.serverTable))

    if (isnumber(query)) then query = query + amount else query = 1 end
    query = math.floor(query)
    sql.Query("UPDATE "..kboard.Server.serverTable.." SET "..type.." = '"..query.."'")
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