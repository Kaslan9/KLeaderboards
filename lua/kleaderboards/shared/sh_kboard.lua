kboard.version = "1.1.7"
local meta = FindMetaTable("Player")

kboard.errors = { -- errors, not recommended to change
    MenuSpam     = "Please Don't Spam Open The Menu!",
    RoundActive  = "You May Not Open The Menu In An Active Round!",
    InvalidQuery = "A Query Error Has Occured! Try Again",
    QuerySpam    = "Please Wait "..kboard.requestCooldown.." Seconds Between Requests", 
}

if SERVER then

    if (kboard.gamemode == "darkrp") then 

        kboard.Server.clientTable = "kboard_darkrp_client" -- contains all darkrp stats for the clients
        kboard.Server.serverTable = "kboard_darkrp_server" -- contains all darkrp stats for the server
        kboard.Server.weaponTable = "kboard_darkrp_weapon" -- contains all darkrp stats for the server weapons

    elseif (kboard.gamemode == "terrortown") then

        kboard.Server.clientTable = "K_Leaderboard" -- contains all terrortown stats for the clients
        kboard.Server.serverTable = "kboard_ServerStats" -- contains all terrortown stats for the server
        kboard.Server.weaponTable = "kboard_weaponStats" -- contains all terrortown stats for the server weapons

    end
end

if CLIENT then

    kboard.Server.trackedStats = { -- list  shows stats.
        general = {
        {name = "Kills",                show = true,    sqlID = "Kills"},
        {name = "Deaths",               show = true,    sqlID = "Deaths"},
        {name = "Total Damage",         show = true,    sqlID = "DamageDealt"},
        {name = "DamageTaken",          show = false,   sqlID = "DamageTaken"},
        {name = "Total Players",        show = true,    sqlID = "UniquePlayers"},
        },

        TTT = {
        {name = "Total Rounds",         show = true,    sqlID = "TotalRounds"},
        {name = "Traitor Wins",         show = true,    sqlID = "TraitorWin"},
        {name = "Innocent Wins",        show = true,    sqlID = "InnocentWin"},
        {name = "Equipment Bought",     show = true,    sqlID = "EquipmentBought"},
        {name = "Bodies Found",         show = true,    sqlID = "BodiesFound"},
        },

        DarkRP = {
        {name = "Arrests",              show = true,    sqlID = "Arrests"},
        {name = "Job Changes",          show = true,    sqlID = "JobChanges"},
        {name = "Total Props",          show = true,    sqlID = "PropsSpawned"},
        {name = "Total Lockpicks",      show = true,    sqlID = "LockPicks"},
        },
    }



    if (kboard.gamemode == "terrortown") then
        kboard.serverStatLabel = "TTT"
        kboard.serverStatCategory = "TTT"

        kboard.personalStats = {
            {name = "Rounds Played",    sqlID = "PRounds"},
            {name = "Win Rate",         sqlID = "WinRate"},
            {name = "Rounds Won",       sqlID = "RoundsWon"},
            {name = "Traitor Wins",     sqlID = "TRounds"},
            {name = "Detective Wins",   sqlID = "DRounds"},
            {name = "Inno Wins",        sqlID = "IRounds"},
            {name = "Damage Dealt",     sqlID = "DamageDealt"},
            {name = "Damage Taken",     sqlID = "DamageTaken"},
        }
    elseif (kboard.gamemode == "darkrp") then
        kboard.serverStatLabel = "DarkRP"
        kboard.serverStatCategory = "DarkRP"

        kboard.personalStats = {
            {name = "Arrests",          sqlID = "Arrests"},
            {name = "Arrested",         sqlID = "Arrested"},
            {name = "Job Changes",      sqlID = "JobChanges"},
            {name = "LockPicks",        sqlID = "LockPicks"},
            {name = "PropsSpawned",     sqlID = "PropsSpawned"},
            {name = "Damage Dealt",     sqlID = "DamageDealt"},
            {name = "Damage Taken",     sqlID = "DamageTaken"},
        }
    end

end

if (kboard.gamemode == "terrortown") then
    kboard.leaderboardColumns = {
        {name = "Name",         sqlID = "Name",         show = true},
        {name = "Kills",        sqlID = "Kills",        show = true},
        {name = "K/D",          sqlID = "KD",           show = true},
        {name = "Total Rounds", sqlID = "PRounds",      show = true},
        {name = "WinRate",      sqlID = "WinRate",      show = true},
        {name = "SteamID",      sqlID = "SteamID",      show = false},

    }
    
    kboard.sortOptions = {
        {name = "Kills",        sqlID = "Kills"},
        {name = "K/D",           sqlID = "KD"},
        {name = "Total Rounds", sqlID = "PRounds"},
        {name = "WinRate",      sqlID = "WinRate"},
    }

elseif (kboard.gamemode == "darkrp") then

    kboard.leaderboardColumns = {
        {name = "Name",         sqlID = "Name",         show = true},
        {name = "Kills",        sqlID = "Kills",        show = true},
        {name = "K/D",          sqlID = "KD",           show = true},
        {name = "Money",        sqlID = "Money",        show = true},
        {name = "Total Props",  sqlID = "PropsSpawned", show = true},
        {name = "SteamID",      sqlID = "SteamID",      show = false}, -- SteamID should be false and always last. (Used for offline player personal panels)
    }

    kboard.sortOptions = {
        {name = "Kills",        sqlID = "Kills"},
        {name = "KD",           sqlID = "KD"},
        {name = "Total Props",  sqlID = "PropsSpawned"},
    }
end

function meta:kboard_OnError(error)
    if (not IsValid(self)) || not self:IsPlayer() then return end
    self:ChatPrint(error)
end