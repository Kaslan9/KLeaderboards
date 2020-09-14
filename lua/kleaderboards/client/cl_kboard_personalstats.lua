local meta = getmetatable("Player")
local pnl = FindMetaTable("Panel")
kboard.Specs.Personal.countForWeapons = kboard.Specs.Personal.countForWeapons or 0

function kboard.drawPlayerStats(parent, ply, count)
    kboard.Specs.Personal.countForWeapons = count
    kboard.Specs.hasFocus = KPERSONAL_STATS
    parent:Clear()
    kboard.PersonalVars(kboard.Specs.Personal.countForWeapons, ply)
    local bottomLine = 1

    local plypic = nil
    if (IsValid(ply) && ply:IsPlayer()) then plypic = ply end

    local avatar = vgui.Create("AvatarImage", parent)
        avatar:SetSize(kboard.Specs.Personal.avatarSize,kboard.Specs.Personal.avatarSize)
        avatar:SetPos(kboard.Specs.Personal.avatarPosX,kboard.Specs.Personal.avatarPosY)
        avatar:SetPlayer(plypic, kboard.Specs.Personal.avatarSize)
    
    local namePanel = vgui.Create("DPanel", parent)
        namePanel:SetSize(kboard.Specs.Personal.namePanelSizeX,kboard.Specs.Personal.namePanelSizeY)
        namePanel:SetPos(kboard.Specs.Personal.namePanelPosX,kboard.Specs.Personal.namePanelPosY)
        namePanel.Paint = function(s,w,h)
            kboard.paintFrame(w, h, kboard.colors.Personal_namePanel, false)
            surface.SetDrawColor(kboard.colors.Personal_namePanelBorder)
            surface.DrawRect(0, h - bottomLine, w, bottomLine)
        end

    if (kboard.enableUTime && not isbool(ply)) then
        local UTimePanel = vgui.Create("DPanel", parent)
            UTimePanel:SetSize(kboard.Specs.Personal.UTimePanelSizeX,kboard.Specs.Personal.UTimePanelSizeY)
            UTimePanel:SetPos(kboard.Specs.Personal.UTimePanelPosX,kboard.Specs.Personal.UTimePanelPosY)
            UTimePanel.Paint = function(s,w,h)
                kboard.paintFrame(w, h, kboard.colors.Personal_namePanel, false)
            surface.SetDrawColor(kboard.colors.Personal_namePanelBorder)
            surface.DrawRect(0, h - bottomLine, w, bottomLine)
            end
        local timeSecs = ply:GetUTimeTotalTime()
        local UTimeText = "N/A"
        if (timeSecs != nil) then UTimeText = "Time Played: "..kboard_timeToStr(timeSecs) end
        surface.SetFont(kboard.Specs.Personal.UTimeFont)
        local _,h = surface.GetTextSize(UTimeText)
        local playerUTime = vgui.Create("DLabel", UTimePanel)
        playerUTime:kboard_setText(UTimeText, kboard.Specs.Personal.UTimeFont, kboard.colors.Personal_UTimeText,kboard.Specs.Personal.UTimePosX, kboard.Specs.Personal.UTimePosY)
    end

    local plyName = kboard.personalTable.Name
    local playerName = vgui.Create("DLabel", namePanel)
    playerName:kboard_setText(plyName, kboard.Specs.Personal.nameFont, kboard.colors.Personal_nameColor,kboard.Specs.Personal.namePosX, kboard.Specs.Personal.namePosY)

    
    local generalPanel = vgui.Create("DPanel", parent)
        generalPanel:SetSize(kboard.Specs.Personal.generalPanelSizeX,kboard.Specs.Personal.generalPanelSizeY)
        generalPanel:SetPos(kboard.Specs.Personal.generalPanelPosX,kboard.Specs.Personal.generalPanelPosY)
        generalPanel.Paint = function(s,w,h)
            kboard.paintFrame(w, h, kboard.colors.Personal_generalPanel, false)
            surface.SetDrawColor(kboard.colors.Personal_generalPanelBorder)
            surface.DrawRect(0, h - bottomLine, w, bottomLine)
        end
    
    local killsText = "Kills: "..kboard.personalTable.Kills
    local playerKills = vgui.Create("DLabel", generalPanel)
    playerKills:kboard_setText(killsText, kboard.Specs.Personal.killsFont, kboard.colors.Personal_killsText,kboard.Specs.Personal.killsPosX, kboard.Specs.Personal.killsPosY)

    local deathText = "Deaths: "..kboard.personalTable.Deaths
    surface.SetFont(kboard.Specs.Personal.deathsFont)
    local _, h = surface.GetTextSize(deathText) 
    local playerDeaths = vgui.Create("DLabel", generalPanel)
        playerDeaths:kboard_setText(deathText, kboard.Specs.Personal.deathsFont, kboard.colors.Personal_deathsText,kboard.Specs.Personal.deathsPosX, kboard.Specs.Personal.deathsPosY - h)


    local kdText = "K/D: "..kboard.personalTable.KD
    surface.SetFont(kboard.Specs.Personal.kdFont)
    local w = surface.GetTextSize(kdText)
    local playerKD = vgui.Create("DLabel", generalPanel)
        playerKD:kboard_setText(kdText, kboard.Specs.Personal.kdFont, kboard.colors.Personal_kdText,kboard.Specs.Personal.kdPosX, kboard.Specs.Personal.kdPosY)

    kboard.CreateStatsPanels(parent, kboard.Specs.Personal.statsPanelPosX, kboard.Specs.Personal.statsPanelPosY, kboard.Specs.Personal.statsPanelSizeX, kboard.Specs.Personal.statsPanelSizeY)


    local weaponsLabel = vgui.Create("DLabel", parent)
    weaponsLabel:kboard_setText(kboard.Specs.Personal.weaponsLabelText, kboard.Specs.Personal.weaponsLabelFont, kboard.colors.Personal_weaponPanelText ,kboard.Specs.Personal.weaponsLabelPosX, kboard.Specs.Personal.weaponsLabelPosY)

    local weaponsPanel = vgui.Create("DPropertySheet", parent)
    weaponsPanel:SetSize(kboard.Specs.Personal.weaponsPanelSizeX,kboard.Specs.Personal.weaponsPanelSizeY)
    weaponsPanel:SetPos(kboard.Specs.Personal.weaponsPanelPosX,kboard.Specs.Personal.weaponsPanelPosY)
    weaponsPanel.Paint = function(s,w,h)
        kboard.paintFrame(w, h, kboard.colors.Personal_weaponsBackground, false)
        surface.SetDrawColor(kboard.colors.Personal_generalPanelBorder)
        surface.DrawRect(0, h - bottomLine, w, bottomLine)
    end

    for _,v in pairs(kboard.weaponListCategories) do
        v.pnl = vgui.Create("DPanel", weaponsPanel)
        weaponsPanel:AddSheet(v.name, v.pnl, nil)

        v.pnl.Paint = function(s,w,h)
            kboard.paintFrame(w, h, Color(255,255,255,0), false)
        end
        v.pnl:kboard_createPanels(kboard.personalTable, v)
    end

    for k, v in pairs(weaponsPanel.Items) do -- Color the tabs
        if (!v.Tab) then continue end
        v.Tab.Paint = function(self,w,h)
            kboard.paintFrame(w, h, Color(255,255,255,0), false)
        end
    end
end

function kboard.CreateStatsPanels(parent, initialX, initialY, sizeX, sizeY)
    local countX = 0
    local countY = 0
    local ogSizeX = sizeX
    local posX, posY
    local value
    for _,v in ipairs(kboard.personalStats) do
        if (countX >= 2) then countX = 0 countY = countY + 1 end
        posX = initialX + ((sizeX + kboard.Specs.whiteSpace) * countX) 
        posY = initialY + ((sizeY + kboard.Specs.whiteSpace) * countY)
        if (countX == 1) then sizeX = sizeX - kboard.Specs.whiteSpace else sizeX = ogSizeX end
        local statPanel = vgui.Create("DPanel", parent)
        statPanel:SetSize(sizeX,sizeY)
        statPanel:SetPos(posX,posY)
        statPanel.Paint = function(s,w,h)
            kboard.paintFrame(w, h, kboard.colors.Personal_statsPanel, false)
            surface.SetDrawColor(kboard.colors.Personal_generalPanelBorder)
            surface.DrawRect(0, h - 1, w, 1)
        end

        value = kboard.personalTable[v.sqlID]
        if (v.sqlID == "RoundsWon") then value = kboard.personalTable.TRounds + kboard.personalTable.IRounds + kboard.personalTable.DRounds end
        local statsText = v.name.." : "..value
        local statsLabel = vgui.Create("DLabel", statPanel)
        local statsTextH = statsLabel:kboard_centerTextH(statsText,kboard.Specs.Personal.statsFont)
        statsLabel:kboard_setText(statsText, kboard.Specs.Personal.statsFont, kboard.colors.Personal_statsText,initialX, statsTextH)

        countX = countX + 1
    end
end

function kboard.PersonalVars(count, ply)
    
    -- Player Avatar Personal --
    kboard.Specs.Personal.avatarSize = 128 - (count * 5)
    kboard.Specs.Personal.avatarPosX = kboard.Specs.whiteSpace
    kboard.Specs.Personal.avatarPosY = kboard.Specs.whiteSpace

    -- Name Panel Text/Size in personal --
    kboard.Specs.Personal.namePanelSizeX = kboard.Specs.contentPanelSizeX - kboard.Specs.Personal.avatarSize - (kboard.Specs.whiteSpace * 3)
    kboard.Specs.Personal.namePanelSizeY = kboard.Specs.frameSizeY * 0.06
    kboard.Specs.Personal.namePanelPosX = (kboard.Specs.whiteSpace * 2) + kboard.Specs.Personal.avatarSize
    kboard.Specs.Personal.namePanelPosY = kboard.Specs.whiteSpace

    kboard.Specs.Personal.namePosX = 2
    kboard.Specs.Personal.namePosY = 2
    kboard.Specs.Personal.nameFontSize = 30
    kboard.Specs.Personal.nameFont = "kboard_Default"..(kboard.Specs.Personal.nameFontSize - count)

    -- UTime Panel/Text Personal Panel -- (Includes generalPanel pos/size)
    if (kboard.enableUTime && not isbool(ply)) then 
        kboard.Specs.Personal.UTimePanelSizeX = kboard.Specs.contentPanelSizeX - kboard.Specs.Personal.avatarSize - (kboard.Specs.whiteSpace * 3)
        kboard.Specs.Personal.UTimePanelSizeY = kboard.Specs.frameSizeY * 0.06
        kboard.Specs.Personal.UTimePanelPosX = (kboard.Specs.whiteSpace * 2) + kboard.Specs.Personal.avatarSize
        kboard.Specs.Personal.UTimePanelPosY = kboard.Specs.Personal.namePanelSizeY + kboard.Specs.whiteSpace * 2

        kboard.Specs.Personal.UTimeFontSize = kboard.Specs.Personal.fontSize
        kboard.Specs.Personal.UTimeFont = "kboard_Default"..(kboard.Specs.Personal.UTimeFontSize - count)
        kboard.Specs.Personal.UTimePosX = 5
        kboard.Specs.Personal.UTimePosY = 5

        kboard.Specs.Personal.generalPanelSizeX = kboard.Specs.contentPanelSizeX - kboard.Specs.Personal.avatarSize - (kboard.Specs.whiteSpace * 3)
        kboard.Specs.Personal.generalPanelSizeY = kboard.Specs.Personal.avatarSize - (kboard.Specs.Personal.namePanelSizeY + kboard.Specs.Personal.UTimePanelSizeY) - (kboard.Specs.whiteSpace *2)
        kboard.Specs.Personal.generalPanelPosX = (kboard.Specs.whiteSpace * 2) + kboard.Specs.Personal.avatarSize
        kboard.Specs.Personal.generalPanelPosY = kboard.Specs.Personal.namePanelPosY + kboard.Specs.Personal.namePanelSizeY + kboard.Specs.Personal.UTimePanelSizeY + (kboard.Specs.whiteSpace *2)
    else
        kboard.Specs.Personal.generalPanelSizeX = kboard.Specs.contentPanelSizeX - kboard.Specs.Personal.avatarSize - (kboard.Specs.whiteSpace * 3)
        kboard.Specs.Personal.generalPanelSizeY = kboard.Specs.Personal.avatarSize - kboard.Specs.Personal.namePanelSizeY - kboard.Specs.whiteSpace
        kboard.Specs.Personal.generalPanelPosX = (kboard.Specs.whiteSpace * 2) + kboard.Specs.Personal.avatarSize
        kboard.Specs.Personal.generalPanelPosY = kboard.Specs.Personal.namePanelPosY + kboard.Specs.Personal.namePanelSizeY + kboard.Specs.whiteSpace
    end

    -- Kills Personal Text and Pos -- 
    kboard.Specs.Personal.killsFontSize = 24
    kboard.Specs.Personal.killsFont = "kboard_Default"..(kboard.Specs.Personal.killsFontSize - count)
    kboard.Specs.Personal.killsPosX = kboard.Specs.whiteSpace
    kboard.Specs.Personal.killsPosY = -1

    -- Deaths Personal Text and Pos --
    kboard.Specs.Personal.deathsFontSize = 24
    kboard.Specs.Personal.deathsFont = "kboard_Default"..(kboard.Specs.Personal.deathsFontSize - count)
    kboard.Specs.Personal.deathsPosX = kboard.Specs.whiteSpace
    kboard.Specs.Personal.deathsPosY = kboard.Specs.Personal.generalPanelSizeY

    -- KD Personal Text and Pos -- 
    kboard.Specs.Personal.kdFontSize = 24
    kboard.Specs.Personal.kdFont = "kboard_Default"..(kboard.Specs.Personal.kdFontSize - count)
    kboard.Specs.Personal.kdPosX = (kboard.Specs.Personal.generalPanelSizeX / 2) + kboard.Specs.whiteSpace * 3
    kboard.Specs.Personal.kdPosY = -1

    -- Total Rounds Personal Panel --
    kboard.Specs.Personal.statsPanelSizeX = kboard.Specs.contentPanelSizeX / 2 - kboard.Specs.whiteSpace
    kboard.Specs.Personal.statsPanelSizeY = kboard.Specs.contentPanelSizeY * 0.065
    kboard.Specs.Personal.statsPanelPosX = kboard.Specs.whiteSpace or kboard.Specs.Personal.namePanelPosX
    kboard.Specs.Personal.statsPanelPosY = kboard.Specs.Personal.generalPanelSizeY + kboard.Specs.Personal.generalPanelPosY + kboard.Specs.whiteSpace

    kboard.Specs.Personal.statsFontSize = kboard.Specs.Personal.fontSize
    kboard.Specs.Personal.statsFont = "kboard_Default"..(kboard.Specs.Personal.statsFontSize - count)
    kboard.Specs.Personal.statsPosX = kboard.Specs.whiteSpace

    -- Weapon List Personal Panel --
    kboard.Specs.Personal.weaponsLabelText = "Weapon Kills:"
    kboard.Specs.Personal.weaponsLabelPosX = kboard.Specs.whiteSpace
    kboard.Specs.Personal.weaponsLabelPosY = (kboard.Specs.contentPanelSizeY * 0.54) + kboard.Specs.whiteSpace * 2
    kboard.Specs.Personal.weaponsLabelFontSize = 25
    kboard.Specs.Personal.weaponsLabelFont = "kboard_Default"..(kboard.Specs.Personal.weaponsLabelFontSize - count)

    surface.SetFont(kboard.Specs.Personal.weaponsLabelFont)
    local _,weaponH = surface.GetTextSize(kboard.Specs.Personal.weaponsLabelText)
    kboard.Specs.Personal.weaponsPanelSizeX = kboard.Specs.contentPanelSizeX - (kboard.Specs.whiteSpace * 2)
    kboard.Specs.Personal.weaponsPanelSizeY = kboard.Specs.contentPanelSizeY - (kboard.Specs.Personal.weaponsLabelPosY+ weaponH + (kboard.Specs.whiteSpace * 2) - 1) 
    kboard.Specs.Personal.weaponsPanelPosX = kboard.Specs.whiteSpace
    kboard.Specs.Personal.weaponsPanelPosY = kboard.Specs.Personal.weaponsLabelPosY + weaponH + kboard.Specs.whiteSpace

    -- Weapon List Panels --
    kboard.Specs.Personal.WeaponFontSize = 20
    kboard.Specs.Personal.WeaponFont = "kboard_Default"..(kboard.Specs.Personal.WeaponFontSize - count)
    kboard.Specs.Personal.WeaponPanelPosX = kboard.Specs.whiteSpace
    kboard.Specs.Personal.WeaponPanelPosY = kboard.Specs.whiteSpace
    kboard.Specs.Personal.WeaponPanelSizeX = (kboard.Specs.Personal.weaponsPanelSizeX - (kboard.Specs.whiteSpace * 4)) / 3
    kboard.Specs.Personal.WeaponPanelSizeY = kboard.Specs.Personal.weaponsPanelSizeY / 9


    --kboard.Specs.Personal.tabFontSize = 10
    --kboard.Specs.Personal.tabFont = "kboard_Default"..(kboard.Specs.Personal.tabFontSize - count)
end

