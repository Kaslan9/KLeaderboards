-- A bind to open the leaderboard instead of typing in chat. Set false to disable. default: KEY_F6
kboard.bind = KEY_F6                -- use https://wiki.facepunch.com/gmod/Enums/KEY for Key values

-- Enable anti-ghosting (Allow Leaderboards to be opened mid-round) -- default: false
-- TTT ONLY OPTION
kboard.allowGhosting = false

-- Shows "!Leaderboard" whenever a player types it in chat, set to false to disable. -- default: true
kboard.showCommandInChat = false   

-- Change the command that the player must use to open the leaderboards -- you can add/remove commands from here.
kboard.ChatCommand = {"!leaderboard",
                      "!leaderboards",
                      "!stats",}

-- Enables the tracking of played time using UTime -- default: false
-- NOTE: Set true only if UTime is installed.
kboard.enableUTime = false 

-- Disables players gaining kills/deaths when they are in Spectator Deathmatch -- default: false
-- TTT ONLY OPTION
kboard.enableSpecDM = false

-- Sort the players in the Leaderboards By: 
-- TTT (Kills, KD, WinRate, PRounds <Rounds Played> (copy and paste options))
-- DarkRP (Kills, KD, PropsSpawned (copy and paste options))
kboard.leaderboardSortBy = "Kills"

-- How often the server updates player damage (in seconds) -- default: 60
-- Decreasing this number might cause preformance issues. Not recommended to change.
kboard.PlayerDamageTimer = 5 

-- How often the server updates total server damage (in seconds) -- default: 30
-- Decreasing this number might cause preformance issues. Not recommended to change.
kboard.ServerDamageTimer = 5

-- How often can a player request data from the server in seconds (Next/Prev Page, Player Profiles, Open Leaderboards) -- default: 2
-- Set 0 to Disable (not recommended)
kboard.requestCooldown = 2

-- the Minimum amount of rounds a player must play to be included in the leaderboards. -- default: 25
-- TTT Only Option
kboard.sortMinRounds = 25

-- the amount of rows(players) to display in the leaderboards -- default: 15
-- Not recommended to change (Will mess with layout slightly.)
kboard.leaderboardRows = 15 
------------------------------------------------------------------------------------------------

-- To add a new weapon to the tracking list, copy and paste this line :
-- {name = "WEAPON_NAME",             id = "WEAPON_ID"},

-- Name should be the name that you want displayed in the leaderboards
-- sqlname should be the column name in the SQL Database (SHOULD NOT INCLUDE SPACES)
-- Make sure to restart server after adding a new weapon. (Not restarting may cause some issues.)
kboard.weaponList = kboard.weaponList or {}

if (kboard.gamemode == "terrortown") then --- TTT WEAPON LIST

    -- to add more categories, copy a line from below change the starting variable and name. Keep pnl as nil.
    kboard.weaponListCategories = {
        {name = "Rifles",           pnl = nil}, 
        {name = "Snipers",          pnl = nil},
        {name = "Shotguns",         pnl = nil}, 
        {name = "Pistols",          pnl = nil}, 
        {name = "Misc.",            pnl = nil},
        {name = "Traitor",          pnl = nil},
        {name = "Detective",        pnl = nil},
    }
    -- category MUST include one of the names above with the exact spelling.
    kboard.weaponList = { 
        {name = "M16",              id = "weapon_ttt_m16",          sqlname = "M16",            category = "Rifles"},
        {name = "H.U.G.E",          id = "weapon_zm_sledge",        sqlname = "HUGE",           category = "Rifles"},
        {name = "Mac10",            id = "weapon_zm_mac10",         sqlname = "Mac10",          category = "Rifles"},
        {name = "Scout",            id = "weapon_zm_rifle",         sqlname = "Scout",          category = "Snipers"},
        {name = "Shotgun",          id = "weapon_zm_shotgun",       sqlname = "Auto_Shotgun",   category = "Shotguns"},

        {name = "Deagle",           id = "weapon_zm_revolver",      sqlname = "Deagle",         category = "Pistols"},
        {name = "Glock",            id = "weapon_ttt_glock",        sqlname = "Glock",          category = "Pistols"},
        {name = "Pistol",           id = "weapon_zm_pistol",        sqlname = "Pistol",         category = "Pistols"},

        {name = "Crowbar",          id = "weapon_zm_improvised",    sqlname = "Crowbar",        category = "Misc."},
    }

elseif (kboard.gamemode == "darkrp") then -- DARKRP WEAPON LIST
    kboard.weaponListCategories = {
        {name = "Rifles",           pnl = nil}, 
        {name = "Snipers",          pnl = nil},
        {name = "Shotguns",         pnl = nil}, 
        {name = "Pistols",          pnl = nil}, 
        {name = "Misc.",            pnl = nil},
    }

    kboard.weaponList = {
        {name = "AK47",             id = "weapon_ak472",            sqlname = "AK47",            category = "Rifles"},
        {name = "Deagle",           id = "weapon_deagle2",          sqlname = "Deagle",          category = "Pistols"},
        {name = "M4",               id = "weapon_m42",              sqlname = "M4",              category = "Rifles"},
        {name = "MP5",              id = "weapon_mp52",             sqlname = "MP5",             category = "Rifles"},
    }
end

if not CLIENT then return end

-- non-named corrospond to the main panel.
-- Leaderboard is for Leaderboards
-- CPlayers is for Connected Players
-- Personal is for Players Stats
-- Server is for Server Stats
-- Config is for Config
-- DO NOT CHANGE NAMES ONLY CHANGE COLORS
kboard.colors = { -- table of colors, you can change the colors of everything here
    frame = Color(16,16,16,230), -- main frame, background of everything

    closeButton = Color(32,32,32), -- closebutton top right
    closeText = Color(200,200,200), -- color of the text
    closeHovered = Color(255,150,0), -- color of the text when hovered

    buttonsPanel = Color(8,8,8,127), -- background of the Buttons
    
    contentPanel = Color(8,8,8,127), -- content panel, the background of everything the buttons lead to
    titlePanel = Color(8,8,8,127), -- color of background where title appears

    selectionButtons = Color(8,8,8,0), -- the selection buttons color
    selectionHovered = Color(100,100,100,127), -- color when buttons are hovered
    selectionText = Color(200,200,200), -- button text color
    selectionTextHovered = Color(255,150,0), -- color of text when button is Selected.

    whiteLines = Color(255,255,255), -- color of all bottom lines.

    --- Player Panel ---

    Personal_namePanel = Color(32,32,32,200), -- Player Stats Panel, background of name
    Personal_namePanelBorder = Color(200,200,200),
    Personal_nameColor = Color(200,200,200),

    Personal_generalPanel = Color(32,32,32,200),
    Personal_generalPanelBorder = Color(200,200,200),
    Personal_generalPanelText = Color(200,200,200),

    Personal_killsText = Color(200,200,200),
    Personal_deathsText = Color(200,200,200),
    Personal_kdText = Color(200,200,200),
    Personal_UTimeText = Color(200,200,200),

    Personal_statsPanel = Color(64,64,64,125),
    Personal_statsText = Color(200,200,200),

    Personal_weaponsBackground = Color(64,64,64,125),
    Personal_weaponPanel = Color(32,32,32,0),
    Personal_weaponPanelText = Color(200,200,200),

    Personal_weaponBottomLine = Color(128,128,128,200),

    --- SERVER PANEL --- 

    Server_generalBackground = Color(8,8,8,127),
    Server_generalBorder = Color(255,255,255),
    Server_generalText = Color(200,200,200),

    Server_GMBackground = Color(8,8,8,127),
    Server_GMBorder = Color(255,255,255),
    Server_GMText = Color(200,200,200),

    Server_weaponsBackground = Color(8,8,8,127),
    Server_weaponsBorder = Color(255,255,255),
    Server_weaponsText = Color(200,200,200),

    Server_boxColor = Color(32,32,32,100),
    Server_boxTextColor = Color(200,200,200),

    Server_scrollButtons = Color(48,48,48),
    Server_scrollButtonsText = Color(255,150,0),

    -- Leaderboard Panel --
    Leaderboards_frameBackground = Color(16,16,16,200),
    Leaderboards_columnHeaderBackground = Color(64,64,64,0),
    Leaderboards_columnHeaderText = Color(255,150,0),

    Leaderboards_evenLineColor = Color(48,48,48,60),
    Leaderboards_oddLineColor = Color(0,0,0,0),
    Leaderboards_LineTextColor = Color(255,255,255),
    Leaderboards_LineHovered  = Color(86,86,86),

    Leaderboards_nextButton = Color(48,48,48,0),
    Leaderboards_nextButtonBorder = Color(200,200,200),
    Leaderboards_nextButtonHovered = Color(255,150,0),
    Leaderboards_nextButtonText = Color(200,200,200),

    Leaderboards_prevButton = Color(48,48,48,0),
    Leaderboards_prevButtonBorder = Color(200,200,200),
    Leaderboards_prevButtonHovered = Color(255,150,0),
    Leaderboards_prevButtonText = Color(200,200,200),
    
    Leaderboards_pageLabel = Color(200,200,200),
    Leaderboards_noticeLabel = Color(160,160,160),
    Leaderboards_sortLabel = Color(160,160,160),


    -- Connected Players Panel -- 

    CPlayers_frameBackground = Color(16,16,16,200),
    CPlayers_buttonOdd = Color(16,16,16,100),
    CPlayers_buttonEven = Color(48,48,48, 150),
    CPlayers_textColor = Color(200,200,200),
    CPlayers_textHovered = Color(255,150,0),
    CPlayers_noticeLabel = Color(160,160,160),

    Confirmation_frame = Color(48,48,48,100),
    Confirmation_text  = Color(255,150,0),
    Confirmation_ButtonsFrame  = Color(32,32,32,0),
    Confirmation_ButtonsText  = Color(200,200,200),
}
