kboard.Specs = kboard.Specs or {}
kboard.Specs.Personal = kboard.Specs.Personal or {}

include("kleaderboards/kboard_config.lua")
include("kleaderboards/shared/sh_kboard.lua")
include("kleaderboards/client/cl_kboard_draw.lua")
include("kleaderboards/client/cl_kboard_leaderboards.lua")
include("kleaderboards/client/cl_kboard_personalstats.lua")
include("kleaderboards/client/cl_kboard_serverpanel.lua")
include("kleaderboards/client/cl_kboard_connectedplayers.lua")


KLEADERBOARDS      = 1 -- Enums for deciding which panel the user is on.
KPERSONAL_STATS    = 2
KCONNECTED_PLAYERS = 3
KSERVER_STATS      = 4

local col_orange = Color(255,150,0)
local col_black  = Color(0,0,0)
local col_white  = Color(255,255,255)

for i = 1,45 do -- Create fonts of different sizes for resolution scaling
    surface.CreateFont( "kboard_Default"..i, {font = "Tahoma", size = i,weight = 1000,antialias = true})
end

local baseFrame = {}
local clply = LocalPlayer()
kboard.leaderboardTable = kboard.leaderboardTable or {}
kboard.personalTable = kboard.personalTable or {}
kboard.serverTable = kboard.serverTable or {}
kboard.weaponsTable = kboard.weaponsTable or {}

kboard.Specs.whiteSpace = 5

vgui.Register("mainFrame", baseFrame, "DFrame")

net.Receive("kboard_openMenu", function(len)

    kboard.Specs.totalPages = net.ReadUInt(16)
    local leaderboardLen = net.ReadUInt(16)
    local serverLen = net.ReadUInt(16)
    local weaponsLen = net.ReadUInt(16)

    kboard.leaderboardTable = net.ReadData(leaderboardLen)
    if (not isstring(kboard.leaderboardTable)) then clply:kboard_CMSG(kboard.errors.InvalidQuery.." (Client leaderboardTable1)") return end --error handling
    kboard.leaderboardTable = util.Decompress(kboard.leaderboardTable)
    if (not isstring(kboard.leaderboardTable)) then clply:kboard_CMSG(kboard.errors.InvalidQuery.." (Client leaderboardTable2)") return end --error handling
    kboard.leaderboardTable = util.JSONToTable(kboard.leaderboardTable)
    if (not istable(kboard.leaderboardTable)) then clply:kboard_CMSG(kboard.errors.InvalidQuery.." (Client leaderboardTable3)") return end --error handling
    
    kboard.serverTable = net.ReadData(serverLen)
    if (not isstring(kboard.serverTable)) then clply:kboard_CMSG(kboard.errors.InvalidQuery.." (Client serverTable1)") return end --error handling
    kboard.serverTable = util.Decompress(kboard.serverTable)
    if (not isstring(kboard.serverTable)) then clply:kboard_CMSG(kboard.errors.InvalidQuery.." (Client serverTable2)") return end --error handling
    kboard.serverTable = util.JSONToTable(kboard.serverTable)
    if (not istable(kboard.serverTable)) then clply:kboard_CMSG(kboard.errors.InvalidQuery.." (Client serverTable3)") return end --error handling

    kboard.weaponsTable = net.ReadData(weaponsLen)
    if (not isstring(kboard.weaponsTable)) then clply:kboard_CMSG(kboard.errors.InvalidQuery.." (Client weaponsTable1)") return end --error handling
    kboard.weaponsTable = util.Decompress(kboard.weaponsTable)
    if (not isstring(kboard.weaponsTable)) then clply:kboard_CMSG(kboard.errors.InvalidQuery.." (Client weaponsTable2)") return end --error handling 
    kboard.weaponsTable = util.JSONToTable(kboard.weaponsTable)
    if (not istable(kboard.weaponsTable)) then clply:kboard_CMSG(kboard.errors.InvalidQuery.." (Client weaponsTable3)") return end --error handling

    kboard.mainMenu()
end)

function baseFrame:Init()
    kboard.Specs.leaderboardPage = 1
    local scrW = ScrW()
    local scrH = ScrH()

    local defaultWidth = 1920 -- the default width this panel is created for. to decide how much to scale
    kboard.Specs.count = 0

    for i=1,10 do -- resolution scaling for fonts.
        if defaultWidth > scrW then 
            kboard.Specs.count = kboard.Specs.count + 1 
            defaultWidth = defaultWidth - 100
        end
    end 
    
    kboard.Specs.hasFocus = KLEADERBOARDS -- Important variable to decide which panel has focus atm

    kboard.Specs.frameSizeX = scrW - ((scrW / 16) *8)
    kboard.Specs.frameSizeY = scrH - ((scrH / 9) *4)

    kboard.Specs.closeSizeX = 35
    kboard.Specs.closeSizeY = 20
    kboard.Specs.Personal.fontSize = 25

    kboard.Specs.buttonsSizeX = kboard.Specs.frameSizeX * 0.3
    kboard.Specs.buttonsSizeY = kboard.Specs.frameSizeY - (kboard.Specs.whiteSpace * 2)
    kboard.Specs.buttonsPosX = kboard.Specs.whiteSpace
    kboard.Specs.buttonsPosY = kboard.Specs.whiteSpace

    kboard.Specs.titlePanelSizeX = kboard.Specs.frameSizeX - kboard.Specs.buttonsSizeX - (kboard.Specs.whiteSpace * 4)
    kboard.Specs.titlePanelSizeY = (kboard.Specs.frameSizeY - (kboard.Specs.whiteSpace * 2)) * 0.10 + 1
    kboard.Specs.titlePanelPosX = (kboard.Specs.whiteSpace * 3) + kboard.Specs.buttonsSizeX
    kboard.Specs.titlePanelPosY =  kboard.Specs.whiteSpace

    kboard.Specs.lineOffset = 0
    kboard.Specs.whiteLine1Y = kboard.Specs.titlePanelSizeY -1 
    kboard.Specs.whiteLine1X = (kboard.Specs.whiteSpace * (kboard.Specs.lineOffset/2))
    kboard.Specs.whiteLine1SizeX = kboard.Specs.titlePanelSizeX - (kboard.Specs.whiteSpace * kboard.Specs.lineOffset)

    kboard.Specs.contentPanelSizeX = kboard.Specs.frameSizeX - kboard.Specs.buttonsSizeX - (kboard.Specs.whiteSpace * 4)
    kboard.Specs.contentPanelSizeY = kboard.Specs.frameSizeY - (kboard.Specs.whiteSpace * 2) - kboard.Specs.titlePanelSizeY
    kboard.Specs.contentPanelPosX = (kboard.Specs.whiteSpace * 3) + kboard.Specs.buttonsSizeX
    kboard.Specs.contentPanelPosY = kboard.Specs.whiteSpace + kboard.Specs.titlePanelSizeY

    kboard.Specs.whiteLine2Offset = 10
    kboard.Specs.whiteLine2Y = kboard.Specs.frameSizeY * 0.05
    kboard.Specs.whiteLine2X = (kboard.Specs.whiteSpace * (kboard.Specs.whiteLine2Offset/2))
    kboard.Specs.whiteLine2SizeX = kboard.Specs.contentPanelSizeX - (kboard.Specs.whiteSpace * kboard.Specs.whiteLine2Offset)

    kboard.Specs.whiteLine3Offset = 10
    kboard.Specs.whiteLine3Y = kboard.Specs.contentPanelSizeY - (kboard.Specs.frameSizeY * 0.10)
    kboard.Specs.whiteLine3X = (kboard.Specs.whiteSpace * (kboard.Specs.whiteLine3Offset/2))
    kboard.Specs.whiteLine3SizeX = kboard.Specs.contentPanelSizeX - (kboard.Specs.whiteSpace * kboard.Specs.whiteLine3Offset)

    kboard.Specs.closePosX = kboard.Specs.contentPanelSizeX - kboard.Specs.closeSizeX
    kboard.Specs.closePosY = 0

    kboard.Specs.selectionButtonsSizeX = kboard.Specs.contentPanelSizeX
    kboard.Specs.selectionButtonsSizeY = kboard.Specs.buttonsSizeY * 0.17
    kboard.Specs.selectionFontSize = 30
    kboard.Specs.selectionFont = "kboard_Default"..(kboard.Specs.selectionFontSize - kboard.Specs.count)


    kboard.Specs.titleText = "Leaderboards"
    kboard.Specs.titleFontSize = 40
    kboard.Specs.titleFont = "kboard_Default"..(kboard.Specs.titleFontSize - kboard.Specs.count)

    kboard.Specs.titlePosX = kboard.Specs.whiteSpace
    kboard.Specs.titlePosY = kboard.Specs.whiteLine1Y - kboard.Specs.whiteSpace
    
end

 
function kboard.mainMenu() -- the code for the main menu (Does not include code for the content of all panels)

    kboard.frame = vgui.Create("mainFrame")
        kboard.frame:SetSize(kboard.Specs.frameSizeX,kboard.Specs.frameSizeY)
        kboard.frame:Center()
        kboard.frame:MakePopup(true)
        kboard.frame:SetTitle("")
        kboard.frame:ShowCloseButton(false)
        kboard.frame.Paint = function(s,w,h)
            kboard.paintFrame(w, h, kboard.colors.frame)
        end

    local buttonsPanel = vgui.Create("DPanel", kboard.frame)
        buttonsPanel:SetSize(kboard.Specs.buttonsSizeX, kboard.Specs.buttonsSizeY)
        buttonsPanel:SetPos(kboard.Specs.buttonsPosX,kboard.Specs.buttonsPosY)
        buttonsPanel.Paint = function(s,w,h)
            kboard.paintFrame(w, h, kboard.colors.buttonsPanel)
        end

    kboard.titlePanel = vgui.Create("DPanel", kboard.frame)
        kboard.titlePanel:SetSize(kboard.Specs.titlePanelSizeX, kboard.Specs.titlePanelSizeY)
        kboard.titlePanel:SetPos(kboard.Specs.titlePanelPosX,kboard.Specs.titlePanelPosY)        
        kboard.titlePanel.Paint = function(s,w,h)
            kboard.paintFrame(w, h, kboard.colors.titlePanel, false)
            
            surface.SetDrawColor(kboard.colors.whiteLines)
            surface.DrawRect(kboard.Specs.whiteLine1X, kboard.Specs.whiteLine1Y, kboard.Specs.whiteLine1SizeX, 1) -- Draw White Line 1
        end

    kboard.contentPanel = vgui.Create("DPanel", kboard.frame)
        kboard.contentPanel:SetSize(kboard.Specs.contentPanelSizeX, kboard.Specs.contentPanelSizeY)
        kboard.contentPanel:SetPos(kboard.Specs.contentPanelPosX, kboard.Specs.contentPanelPosY)
        kboard.contentPanel.Paint = function(s,w,h)
            kboard.paintFrame(w, h, kboard.colors.contentPanel, false)
            if (kboard.Specs.hasFocus == KLEADERBOARDS || kboard.Specs.hasFocus == KCONNECTED_PLAYERS) then 
                surface.SetDrawColor(kboard.colors.whiteLines)
                surface.DrawRect(kboard.Specs.whiteLine2X, kboard.Specs.whiteLine2Y, kboard.Specs.whiteLine2SizeX, 1)
                surface.DrawRect(kboard.Specs.whiteLine3X, kboard.Specs.whiteLine3Y, kboard.Specs.whiteLine3SizeX, 1)
            end
        end


    kboard.titleLabel = vgui.Create("DLabel", kboard.titlePanel)
    kboard.setText(kboard.Specs.titleText, kboard.Specs.titleFont, kboard.titleLabel)
    
    kboard.clickOption(KLEADERBOARDS, "Leaderboards", kboard.titleLabel)
    kboard.drawLeaderboards(kboard.contentPanel, kboard.Specs.count)
    local buttonHovered = kboard.colors.closeText
    local closeButton = vgui.Create("DButton", kboard.titlePanel)
        closeButton:SetSize(kboard.Specs.closeSizeX,kboard.Specs.closeSizeY)
        closeButton:SetPos(kboard.Specs.closePosX,kboard.Specs.closePosY)
        closeButton:SetFont("kboard_Default16")
        closeButton:SetText("X")
        closeButton.DoClick = function(self)
            kboard.frame:Close()
        end
        closeButton.Paint = function(s,w,h)
            if closeButton:IsHovered() then buttonHovered = kboard.colors.closeHovered else buttonHovered = kboard.colors.closeText end
            closeButton:SetTextColor(buttonHovered)
            kboard.paintFrame(w, h, kboard.colors.closeButton, false)
        end
    
    local leaderboardsColor = kboard.colors.selectionButtons
    local leaderboardsTextColor = kboard.colors.selectionTextHovered
    local buttonLeaderboards = vgui.Create("DButton", buttonsPanel)
        buttonLeaderboards:SetSize(kboard.Specs.selectionButtonsSizeX,kboard.Specs.selectionButtonsSizeY)
        buttonLeaderboards:Dock(TOP)
        buttonLeaderboards:SetFont(kboard.Specs.selectionFont)
        buttonLeaderboards:SetText("Leaderboards")
        buttonLeaderboards.Paint = function(s,w,h)
            if (kboard.Specs.hasFocus == KLEADERBOARDS || s:IsHovered()) then 
                leaderboardsColor = kboard.colors.selectionHovered
            else
                leaderboardsColor = kboard.colors.selectionButtons
            end
            if (kboard.Specs.hasFocus == KLEADERBOARDS) then leaderboardsTextColor = kboard.colors.selectionTextHovered else leaderboardsTextColor = kboard.colors.selectionText end

            buttonLeaderboards:SetTextColor(leaderboardsTextColor)
            kboard.paintFrame(w, h, leaderboardsColor, false)
        end
        buttonLeaderboards.DoClick = function(self)
            kboard.clickOption(KLEADERBOARDS, "Leaderboards", kboard.titleLabel)
            kboard.drawLeaderboards(kboard.contentPanel, kboard.Specs.count)
        end

    local connectedPlayersColor = kboard.colors.selectionButtons
    local connectedPlayersTextColor = kboard.colors.selectionTextHovered
    local connectedPlayers = vgui.Create("DButton", buttonsPanel)
        connectedPlayers:SetSize(kboard.Specs.selectionButtonsSizeX,kboard.Specs.selectionButtonsSizeY)
        connectedPlayers:Dock(TOP)
        connectedPlayers:SetFont(kboard.Specs.selectionFont)
        connectedPlayers:SetText("Connected Players")
        connectedPlayers.Paint = function(s,w,h)
            if (kboard.Specs.hasFocus == KCONNECTED_PLAYERS || s:IsHovered()) then 
                connectedPlayersColor = kboard.colors.selectionHovered
            else
                connectedPlayersColor = kboard.colors.selectionButtons
            end
            if (kboard.Specs.hasFocus == KCONNECTED_PLAYERS) then connectedPlayersTextColor = kboard.colors.selectionTextHovered else connectedPlayersTextColor = kboard.colors.selectionText end

            connectedPlayers:SetTextColor(connectedPlayersTextColor)
            kboard.paintFrame(w, h, connectedPlayersColor, false)
        end
        connectedPlayers.DoClick = function(self)
            kboard.clickOption(KCONNECTED_PLAYERS, "Connected Players", kboard.titleLabel)
            kboard.callConnectedPlayers(kboard.contentPanel,kboard.Specs.count)
        end
 
    local personalColor = kboard.colors.selectionButtons
    local personalTextColor = kboard.colors.selectionText
    local buttonPersonal = vgui.Create("DButton", buttonsPanel)
        buttonPersonal:SetSize(kboard.Specs.selectionButtonsSizeX,kboard.Specs.selectionButtonsSizeY)
        buttonPersonal:Dock(TOP)
        buttonPersonal:SetFont(kboard.Specs.selectionFont)
        buttonPersonal:SetText("Player Stats")
        buttonPersonal.Paint = function(s,w,h)
            if (kboard.Specs.hasFocus == KPERSONAL_STATS || s:IsHovered()) then 
                personalColor = kboard.colors.selectionHovered
            else
                personalColor = kboard.colors.selectionButtons
            end
            if (kboard.Specs.hasFocus == KPERSONAL_STATS) then personalTextColor = kboard.colors.selectionTextHovered else personalTextColor = kboard.colors.selectionText end

            buttonPersonal:SetTextColor(personalTextColor)
            kboard.paintFrame(w, h, personalColor, false)
        end
        buttonPersonal.DoClick = function(self)
            net.Start("kboard_RequestPlayerData")
                net.WriteString(LocalPlayer():SteamID())
            net.SendToServer()
        end
    
    local serverStatsColor = kboard.colors.selectionButtons
    local serverTextColor = kboard.colors.selectionText
    local buttonServer = vgui.Create("DButton", buttonsPanel)
        buttonServer:SetSize(kboard.Specs.selectionButtonsSizeX,kboard.Specs.selectionButtonsSizeY)
        buttonServer:Dock(TOP)
        buttonServer:SetFont(kboard.Specs.selectionFont)
        buttonServer:SetText("Server Stats")
        buttonServer.Paint = function(s,w,h)
            if (kboard.Specs.hasFocus == KSERVER_STATS || s:IsHovered()) then 
                serverStatsColor = kboard.colors.selectionHovered
            else
                serverStatsColor = kboard.colors.selectionButtons
            end
            if (kboard.Specs.hasFocus == KSERVER_STATS) then serverTextColor = kboard.colors.selectionTextHovered else serverTextColor = kboard.colors.selectionText end

            buttonServer:SetTextColor(serverTextColor)
            kboard.paintFrame(w, h, serverStatsColor, false)
        end
        buttonServer.DoClick = function(self)
            kboard.clickOption(KSERVER_STATS, "Server Stats", kboard.titleLabel)
            kboard.drawServerStats(kboard.contentPanel, kboard.Specs.count)
        end
end

net.Receive("kboard_SendPlayerData", function(len)
    kboard.personalTable = net.ReadData(len)
    kboard.personalTable = util.Decompress(kboard.personalTable)
    kboard.personalTable = util.JSONToTable(kboard.personalTable)
    if (not istable(kboard.personalTable)) then return end
    local reqPly = player.GetBySteamID(kboard.personalTable.SteamID)


    kboard.drawPlayerStats(kboard.contentPanel, reqPly, kboard.Specs.count)
    kboard.clickOption(KPERSONAL_STATS, "Player Stats", kboard.titleLabel)
end)


function kboard.clickOption(focus, titleText, label) -- function to change title when one of the option buttons is clicked.
    kboard.Specs.titleText = titleText
    kboard.setText(kboard.Specs.titleText, kboard.Specs.titleFont, label)
end

net.Receive("kboard_SendMessage", function() 
    local msg = net.ReadString()
    chat.AddText(col_black, "[", col_orange,"KLeaderboards", col_black, "] ",col_white, msg)
end)