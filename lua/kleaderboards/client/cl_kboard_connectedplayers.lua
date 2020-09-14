AddCSLuaFile()

kboard.Specs.Players = kboard.Specs.Players or {}
local count = count or 0
local meta = FindMetaTable("Player")
local kboard_answer

function kboard.callConnectedPlayers(parent,count)
    kboard.Specs.hasFocus = KCONNECTED_PLAYERS
    parent:Clear()
    kboard.playerVars(count)

    local playerFrame = vgui.Create("DScrollPanel", parent)
        playerFrame:SetSize(kboard.Specs.Players.playerFrameSizeX,kboard.Specs.Players.playerFrameSizeY)
        playerFrame:SetPos(kboard.Specs.Players.playerFramePosX,kboard.Specs.Players.playerFramePosY)
        playerFrame.Paint = function(s,w,h)
            kboard.paintFrame(w, h, kboard.colors.CPlayers_frameBackground, false)
        end
        kboard_cplyButtons(playerFrame, kboard.Specs.Players.playerButtonSizeX, kboard.Specs.Players.playerButtonSizeY, kboard.Specs.Players.playerButtonsPerRow)

    local clickNotice = vgui.Create("DLabel", parent)
        clickNotice:SetPos(kboard.Specs.Players.noticeLabelPosX,kboard.Specs.Players.noticeLabelPosY)
        clickNotice:SetFont(kboard.Specs.Players.noticeLabelFont)
        clickNotice:SetTextColor(kboard.colors.CPlayers_noticeLabel)
        clickNotice:SetText(kboard.Specs.Players.noticeLabelText)
        clickNotice:SizeToContents()
end

function kboard.playerVars(count)
    kboard.Specs.Players.playerFrameSizeX = kboard.Specs.whiteLine2SizeX
    kboard.Specs.Players.playerFrameSizeY = (kboard.Specs.whiteLine3Y - kboard.Specs.whiteLine2Y) - 1 
    kboard.Specs.Players.playerFramePosX  = kboard.Specs.whiteLine2X
    kboard.Specs.Players.playerFramePosY  = kboard.Specs.whiteLine2Y + 1

    kboard.Specs.Players.playerButtonFontSize = 25 - count
    kboard.Specs.Players.playerButtonFont = "kboard_Default"..(kboard.Specs.Players.playerButtonFontSize)

    kboard.Specs.Players.playerButtonsPerRow = 5
    kboard.Specs.Players.playerButtonSizeX = kboard.Specs.Players.playerFrameSizeX / kboard.Specs.Players.playerButtonsPerRow
    kboard.Specs.Players.playerButtonSizeY = 60 - (count * 2)

    kboard.Specs.Players.noticeLabelText = "Double Click Players To Open Their Personal Stats!"
    kboard.Specs.Players.noticeLabelFontSize = 18 - count
    kboard.Specs.Players.noticeLabelFont = "kboard_Default"..(kboard.Specs.Players.noticeLabelFontSize)
    surface.SetFont(kboard.Specs.Players.noticeLabelFont)
    local _,h = surface.GetTextSize(kboard.Specs.Players.noticeLabelText)
    kboard.Specs.Players.noticeLabelPosX = kboard.Specs.Players.playerFramePosX
    kboard.Specs.Players.noticeLabelPosY = kboard.Specs.Players.playerFramePosY - h -kboard.Specs.whiteSpace
end

function kboard_cplyButtons(parent, sizex, sizey, ppr)
    local countX = 0
    local countY = 0
    local posX
    local posY

    surface.SetFont(kboard.Specs.Players.playerButtonFont)
    for k,ply in ipairs(player.GetAll()) do
        kboardkey = k
        ply.kboardcolor = kboard.colors.CPlayers_buttonOdd
        if (countX >= ppr) then countX = 0 countY = countY + 1 end
        if (kboardkey % 2 == 0) then ply.kboardcolor = kboard.colors.CPlayers_buttonEven else ply.kboardcolor = kboard.colors.CPlayers_buttonOdd end
                     
        posX = (sizex * countX)
        posY = (sizey * countY)

        -- font scaling for player names
        local dif = 0
        local plyname = ply:Nick()
        local nameW,_ = surface.GetTextSize(plyname)
        if (nameW > sizex) then dif = nameW - sizex end
        local fontsize = kboard.Specs.Players.playerButtonFontSize - math.floor(dif / 5)
        if (fontsize < 15) then fontsize = 15 end
        local newfont = "kboard_Default"..fontsize

        local button = vgui.Create("DButton", parent)
        button:SetSize(sizex,sizey)
        button:SetPos(posX,posY)
        button:SetFont(newfont)
        button:SetTextColor(kboard.colors.CPlayers_textColor)
        button:SetText(plyname)
        button.Paint = function(s,w,h)
            if (s:IsHovered()) then button:SetTextColor(kboard.colors.CPlayers_textHovered) else button:SetTextColor(kboard.colors.CPlayers_textColor) end
            kboard.paintFrame(w, h, ply.kboardcolor, false)
        end
        button.DoDoubleClick = function(self)
            if (not IsValid(ply) || not ply:IsPlayer()) then return end
            net.Start("kboard_RequestPlayerData")
                net.WriteString(ply:SteamID())
            net.SendToServer()
        end
        countX = countX + 1
    end
end