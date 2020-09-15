local fontCount = 0
local pnl = FindMetaTable("Panel")
kboard.Specs.Server = kboard.Specs.Server or {}

function kboard.drawServerStats(parent, count) -- Function to draw the actual panel
    kboard.Specs.hasFocus = KSERVER_STATS

    parent:Clear()
    kboard.ServerVars(count)
    local bottomLine = 1

    local generalPanelText = vgui.Create("DLabel", parent)
    generalPanelText:kboard_setText(kboard.Specs.Server.generalName, kboard.Specs.Server.generalFont, Server_generalText ,kboard.Specs.Server.generalTextPosX, kboard.Specs.Server.generalTextPosY)

    local generalPanel = vgui.Create("DHorizontalScroller", parent)
    generalPanel:SetSize(kboard.Specs.Server.generalPanelSizeX,kboard.Specs.Server.generalPanelSizeY)
    generalPanel:SetPos(kboard.Specs.Server.generalPanelPosX,kboard.Specs.Server.generalPanelPosY)
    generalPanel:SetOverlap( -(kboard.Specs.whiteSpace * 1.5) )
    generalPanel:SetUseLiveDrag( true )
    generalPanel.btnRight:SetText(">")
    generalPanel.btnRight:SetTextColor(kboard.colors.Server_scrollButtonsText)
    generalPanel.btnRight.Paint = function(s,w,h)
        kboard.paintFrame(w, h, kboard.colors.Server_scrollButtons, false)
    end
    generalPanel.btnLeft:SetText("<")
    generalPanel.btnLeft:SetTextColor(kboard.colors.Server_scrollButtonsText)
    generalPanel.btnLeft.Paint = function(s,w,h)
        kboard.paintFrame(w, h, kboard.colors.Server_scrollButtons, false)
    end
    generalPanel.Paint = function(s,w,h)
        kboard.paintFrame(w, h, kboard.colors.Server_generalBackground, false)
        surface.SetDrawColor(kboard.colors.whiteLines)
        surface.DrawRect(0, h - bottomLine, w, bottomLine) -- Draw White Line 1
    end
    kboard.drawStatBoxes("general", generalPanel)


    local GMPanelText = vgui.Create("DLabel", parent)
    GMPanelText:kboard_setText(kboard.Specs.Server.GMText, kboard.Specs.Server.GMFont, kboard.colors.Server_GMText ,kboard.Specs.Server.GMTextPosX, kboard.Specs.Server.GMTextPosY)

    local GMPanel = vgui.Create("DHorizontalScroller", parent)
    GMPanel:SetSize(kboard.Specs.Server.GMPanelSizeX,kboard.Specs.Server.GMPanelSizeY)
    GMPanel:SetPos(kboard.Specs.Server.GMPanelPosX,kboard.Specs.Server.GMPanelPosY)
    GMPanel:SetOverlap( -(kboard.Specs.whiteSpace * 1.5) )
    GMPanel.Paint = function(s,w,h)
        kboard.paintFrame(w, h, kboard.colors.Server_GMBackground, false)
        surface.SetDrawColor(kboard.colors.whiteLines)
        surface.DrawRect(0, h - bottomLine, w, bottomLine) -- Draw White Line 1
    end
    GMPanel.btnRight:SetText(">")
    GMPanel.btnRight:SetTextColor(kboard.colors.Server_scrollButtonsText)
    GMPanel.btnRight.Paint = function(s,w,h)
        kboard.paintFrame(w, h, kboard.colors.Server_scrollButtons, false)
    end
    GMPanel.btnLeft:SetText("<")
    GMPanel.btnLeft:SetTextColor(kboard.colors.Server_scrollButtonsText)
    GMPanel.btnLeft.Paint = function(s,w,h)
        kboard.paintFrame(w, h, kboard.colors.Server_scrollButtons, false)
    end

    kboard.drawStatBoxes(kboard.serverStatCategory, GMPanel)

    local weaponsPanelText = vgui.Create("DLabel", parent)
    weaponsPanelText:kboard_setText(kboard.Specs.Server.weaponsText, kboard.Specs.Server.weaponsTextFont, kboard.colors.Server_weaponsText ,kboard.Specs.Server.weaponsTextPosX, kboard.Specs.Server.weaponsTextPosY)

    local weaponsPanel = vgui.Create("DPropertySheet", parent)
    weaponsPanel:SetSize(kboard.Specs.Server.weaponsPanelSizeX,kboard.Specs.Server.weaponsPanelSizeY)
    weaponsPanel:SetPos(kboard.Specs.Server.weaponsPanelPosX,kboard.Specs.Server.weaponsPanelPosY)
    weaponsPanel.Paint = function(s,w,h)
        kboard.paintFrame(w, h, kboard.colors.Server_weaponsBackground, false)
        surface.SetDrawColor(kboard.colors.whiteLines)
        surface.DrawRect(0, h - bottomLine, w, bottomLine) -- Draw White Line 1
    end
    for _,v in pairs(kboard.weaponListCategories) do
        v.pnl = vgui.Create("DPanel", weaponsPanel)
        weaponsPanel:AddSheet(v.name, v.pnl, nil)

        v.pnl.Paint = function(s,w,h)
            kboard.paintFrame(w, h, Color(255,255,255,0), false)
        end
        v.pnl:kboard_createPanels(kboard.weaponsTable, v)
    end

    for k, v in pairs(weaponsPanel.Items) do -- Color the tabs
        if (!v.Tab) then continue end
        v.Tab.Paint = function(self,w,h)
            kboard.paintFrame(w, h, Color(255,255,255,0), false)
        end
    end
end

function kboard.drawStatBoxes(category, parent)
    local boxSizeX = kboard.Specs.Server.statBoxSizeX    
    local boxSizeY = kboard.Specs.Server.statBoxSizeY  

    for _,v in ipairs(kboard.Server.trackedStats[category]) do
        if (not v.show) then continue end
        
        local val = kboard.serverTable[1][v.sqlID]
        if (val == nil) then val = "N/A" end

        local box = vgui.Create("DPanel", parent)
            box:SetSize(boxSizeX,boxSizeY)
            box:Dock(LEFT)
            box:DockMargin(5,5,0,5)
            box.Paint = function(s,w,h)
                kboard.paintFrame(w, h, kboard.colors.Server_boxColor, false)
            end
            box:kboard_boxText(v.name, val, kboard.Specs.Server.statBoxFont, kboard.colors.Server_boxTextColor)
            parent:AddPanel( box )
    end
end
function pnl:kboard_boxText(text, value, font, color)
    surface.SetFont(font)
    local textW,_ = surface.GetTextSize(text)
    local panelW,panelH = self:GetSize()
    local titlePosX = (panelW / 2) - (textW /2 )
    local titlePosY = kboard.Specs.whiteSpace
    local titleLabel = vgui.Create("DLabel", self)
        titleLabel:SetPos(titlePosX,titlePosY)
        titleLabel:SetFont(font)
        titleLabel:SetTextColor(color)
        titleLabel:SetText(text)
        titleLabel:SizeToContents()

    local valueW, valueH = surface.GetTextSize(value)
    local valuePosX = (panelW /2) - (valueW / 2)
    local valuePosY =  panelH - valueH - (kboard.Specs.whiteSpace * 2)

    local valueLabel = vgui.Create("DLabel", self)
        valueLabel:SetPos(valuePosX,valuePosY)
        valueLabel:SetFont(font)
        valueLabel:SetTextColor(color)
        valueLabel:SetText(value)
        valueLabel:SizeToContents()
end
-- holds all information about panels relating to Server Stats
function kboard.ServerVars(count)

    -- General Panel --
    kboard.Specs.Server.generalName = "General Stats"
    kboard.Specs.Server.generalTextPosX = kboard.Specs.whiteSpace
    kboard.Specs.Server.generalTextPosY = 10
    kboard.Specs.Server.generalFontSize = 30
    kboard.Specs.Server.generalFont = "kboard_Default"..(kboard.Specs.Server.generalFontSize - fontCount)

    surface.SetFont(kboard.Specs.Server.generalFont)
    local _,generalH = surface.GetTextSize(kboard.Specs.Server.generalName)
    kboard.Specs.Server.generalPanelSizeX = kboard.Specs.titlePanelSizeX - (kboard.Specs.whiteSpace * 2)
    kboard.Specs.Server.generalPanelSizeY = kboard.Specs.contentPanelSizeY * 0.2
    kboard.Specs.Server.generalPanelPosX = kboard.Specs.whiteSpace
    kboard.Specs.Server.generalPanelPosY = kboard.Specs.Server.generalTextPosY + generalH + kboard.Specs.whiteSpace

    -- GM Panel --
    kboard.Specs.Server.GMText =  kboard.serverStatLabel.." Stats"
    kboard.Specs.Server.GMTextPosX = kboard.Specs.whiteSpace
    kboard.Specs.Server.GMTextPosY = kboard.Specs.Server.generalPanelPosY + kboard.Specs.Server.generalPanelSizeY + (kboard.Specs.whiteSpace * 2)
    kboard.Specs.Server.GMFontSize = 30
    kboard.Specs.Server.GMFont = "kboard_Default"..(kboard.Specs.Server.GMFontSize - count)

    surface.SetFont(kboard.Specs.Server.GMFont)
    local _,GMH = surface.GetTextSize(kboard.Specs.Server.GMText)
    kboard.Specs.Server.GMPanelSizeX = kboard.Specs.Server.generalPanelSizeX
    kboard.Specs.Server.GMPanelSizeY = kboard.Specs.Server.generalPanelSizeY
    kboard.Specs.Server.GMPanelPosX = kboard.Specs.Server.generalPanelPosX
    kboard.Specs.Server.GMPanelPosY = kboard.Specs.Server.GMTextPosY + GMH + kboard.Specs.whiteSpace

    -- Weapon Stats --
    kboard.Specs.Server.weaponsText = "Total Weapon Kills"
    kboard.Specs.Server.weaponsTextPosX = kboard.Specs.whiteSpace
    kboard.Specs.Server.weaponsTextPosY = kboard.Specs.Server.GMPanelSizeY + kboard.Specs.Server.GMPanelPosY + (kboard.Specs.whiteSpace * 2)
    kboard.Specs.Server.weaponsTextFontSize = 30
    kboard.Specs.Server.weaponsTextFont = "kboard_Default"..(kboard.Specs.Server.weaponsTextFontSize - count)

    surface.SetFont(kboard.Specs.Server.weaponsTextFont)
    local _, weaponsH = surface.GetTextSize(kboard.Specs.Server.weaponsText)
    kboard.Specs.Server.weaponsPanelSizeX = kboard.Specs.Server.GMPanelSizeX
    kboard.Specs.Server.weaponsPanelSizeY = kboard.Specs.contentPanelSizeY - (kboard.Specs.Server.weaponsTextPosY + weaponsH) - (kboard.Specs.whiteSpace * 2)
    kboard.Specs.Server.weaponsPanelPosX  = kboard.Specs.whiteSpace
    kboard.Specs.Server.weaponsPanelPosY  = kboard.Specs.Server.weaponsTextPosY + weaponsH + kboard.Specs.whiteSpace

    -- Stat Boxes --
    kboard.Specs.Server.statBoxSizeX = kboard.Specs.Server.generalPanelSizeX / 3
    kboard.Specs.Server.statBoxSizeY = kboard.Specs.Server.generalPanelSizeY - (kboard.Specs.whiteSpace * 2)

    kboard.Specs.Server.statBoxFontSize = 25
    kboard.Specs.Server.statBoxFont = "kboard_Default"..(kboard.Specs.Server.statBoxFontSize - count)
end
