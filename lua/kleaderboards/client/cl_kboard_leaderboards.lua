local parentPanel = parentPanel or {}
local lateCount = lateCount or 0
local sortOptions = nil

kboard.Specs.Leaderboards = kboard.Specs.Leaderboards or {}
kboard.Specs.totalPages = kboard.Specs.totalPages or 1
kboard.Specs.leaderboardPage = kboard.Specs.leaderboardPage or 1

local clply = LocalPlayer()

net.Receive("kboard_SendPageData", function(len)
    kboard.Specs.leaderboardPage = net.ReadUInt(16)

    table.Empty(kboard.leaderboardTable)
    kboard.leaderboardTable = net.ReadData(len)
    if (not isstring(kboard.leaderboardTable)) then clply:kboard_CMSG(kboard.errors.InvalidQuery.." Client leaderboardTable1") return end 

    kboard.leaderboardTable = util.Decompress(kboard.leaderboardTable)
    if (not isstring(kboard.leaderboardTable)) then clply:kboard_CMSG(kboard.errors.InvalidQuery.." Client leaderboardTable2") return end 

    kboard.leaderboardTable = util.JSONToTable(kboard.leaderboardTable)
    if (not istable(kboard.leaderboardTable)) then clply:kboard_CMSG(kboard.errors.InvalidQuery.." Client leaderboardTable3") return end 

    
    kboard.drawLeaderboards(parentPanel, lateCount)
end)

net.Receive("kboard_SendSortPage", function(len)
    if (sortOptions == nil) then return end
    kboard.Specs.totalPages = net.ReadUInt(16)
    local leaderboardlen = net.ReadUInt(16)
    local sortby = net.ReadString()

    table.Empty(kboard.leaderboardTable)
    kboard.leaderboardTable = net.ReadData(leaderboardlen)
    if (not isstring(kboard.leaderboardTable)) then clply:kboard_CMSG(kboard.errors.InvalidQuery.." Client sortedLeaderboardTable1") return end 

    kboard.leaderboardTable = util.Decompress(kboard.leaderboardTable)
    if (not isstring(kboard.leaderboardTable)) then clply:kboard_CMSG(kboard.errors.InvalidQuery.." Client sortedLeaderboardTable1") return end 

    kboard.leaderboardTable = util.JSONToTable(kboard.leaderboardTable)
    if (not istable(kboard.leaderboardTable)) then clply:kboard_CMSG(kboard.errors.InvalidQuery.." Client sortedLeaderboardTable1") return end 

    kboard.drawLeaderboards(parentPanel, lateCount)
    if (sortby == "KD") then 
        sortby = "K/D" 
    elseif (sortby == "PRounds") then 
        sortby = "Total Rounds" 
    elseif (sortby == "PropsSpawned") then 
        sortby = "Total Props" 
    end

    sortOptions:SetValue(sortby)
end)

function kboard.drawLeaderboards(parent, count)
    kboard.Specs.hasFocus = KLEADERBOARDS
    parentPanel = parent
    lateCount = count

    parent:Clear()
    kboard.leaderboardVars(count)

    local bottomLine = 1

    dlist = vgui.Create("DListView", parent)
    dlist:SetSize(kboard.Specs.whiteLine2SizeX,kboard.Specs.Leaderboards.listViewSizeY)
    dlist:SetPos(kboard.Specs.Leaderboards.listViewPosX,kboard.Specs.Leaderboards.listViewPosY)
    dlist:SetHeaderHeight(kboard.Specs.Leaderboards.listHeaderHeight)
    dlist:SetDataHeight(kboard.Specs.Leaderboards.dataHeight)
    dlist:SetSortable(false)
    dlist.Paint = function(s,w,h)
        kboard.paintFrame(w, h, kboard.colors.Leaderboards_frameBackground, false)
    end

    for _,v in ipairs(kboard.leaderboardColumns) do
        if (not v.show) then continue end
        dlist:AddColumn(v.name)
    end
    
    kboard.callDList(dlist)

    function dlist:DoDoubleClick(lineid, line)
        local steamid = tostring(line:GetValue(#kboard.leaderboardColumns))
        if (not isstring(steamid)) then return end
        net.Start("kboard_RequestPlayerData")
            net.WriteString(steamid)
        net.SendToServer()
    end

    local clickNotice = vgui.Create("DLabel", parent)
    clickNotice:SetPos(kboard.Specs.Leaderboards.noticeLabelPosX,kboard.Specs.Leaderboards.noticeLabelPosY)
    clickNotice:SetFont(kboard.Specs.Leaderboards.noticeLabelFont)
    clickNotice:SetTextColor(kboard.colors.Leaderboards_noticeLabel)
    clickNotice:SetText(kboard.Specs.Leaderboards.noticeLabelText)
    clickNotice:SizeToContents()

    local pagesLabel = vgui.Create("DLabel", parent)
        pagesLabel:SetPos(kboard.Specs.Leaderboards.pagesLabelPosX,kboard.Specs.Leaderboards.pagesLabelPosY)
        pagesLabel:SetFont(kboard.Specs.Leaderboards.pagesLabelFont)
        pagesLabel:SetTextColor(kboard.colors.Leaderboards_pageLabel)
        pagesLabel:SetText(kboard.Specs.Leaderboards.pagesLabelText)
        pagesLabel:SizeToContents()
    
    local nextButton = vgui.Create("DButton", parent)
        nextButton:SetSize(kboard.Specs.Leaderboards.nextButtonSizeX,kboard.Specs.Leaderboards.nextButtonSizeY)
        nextButton:SetPos(kboard.Specs.Leaderboards.nextButtonPosX,kboard.Specs.Leaderboards.nextButtonPosY)
        nextButton:SetFont(kboard.Specs.Leaderboards.nextButtonFont)
        nextButton:SetTextColor(kboard.colors.Leaderboards_nextButtonText)
        nextButton:SetText("Next >")

    kboard.Specs.nextButtonBorder = kboard.colors.Leaderboards_nextButtonBorder
    nextButton.Paint = function(s,w,h)
        if (s:IsHovered()) then 
            kboard.Specs.nextButtonBorder = kboard.colors.Leaderboards_nextButtonHovered 
        else 
            kboard.Specs.nextButtonBorder = kboard.colors.Leaderboards_nextButtonBorder 
        end

        kboard.paintFrame(w, h, kboard.colors.Leaderboards_nextButton, false)
        surface.SetDrawColor(kboard.Specs.nextButtonBorder)
        surface.DrawRect(0, h - bottomLine, w, bottomLine) -- Draw White Line 1
    end
    nextButton.DoClick = function(self)

        net.Start("kboard_RequestPageData")
            net.WriteUInt(1, 3)
            net.WriteUInt(kboard.Specs.leaderboardPage, 16)
        net.SendToServer()
    end

    local prevButton = vgui.Create("DButton", parent)
    prevButton:SetSize(kboard.Specs.Leaderboards.prevButtonSizeX,kboard.Specs.Leaderboards.prevButtonSizeY)
    prevButton:SetPos(kboard.Specs.Leaderboards.prevButtonPosX,kboard.Specs.Leaderboards.prevButtonPosY)
    prevButton:SetFont(kboard.Specs.Leaderboards.prevButtonFont)
    prevButton:SetTextColor(kboard.colors.Leaderboards_prevButtonText)
    prevButton:SetText("< Previous")

    kboard.Specs.prevButtonBorder = kboard.colors.Leaderboards_prevButtonBorder
    prevButton.Paint = function(s,w,h)
        if (s:IsHovered()) then 
            kboard.Specs.prevButtonBorder = kboard.colors.Leaderboards_prevButtonHovered 
        else 
            kboard.Specs.prevButtonBorder = kboard.colors.Leaderboards_prevButtonBorder 
        end

        kboard.paintFrame(w, h, kboard.colors.Leaderboards_prevButton, false)
        surface.SetDrawColor(kboard.Specs.prevButtonBorder)
        surface.DrawRect(0, h - bottomLine, w, bottomLine) -- Draw White Line 1
    end
    prevButton.DoClick = function(self)

        net.Start("kboard_RequestPageData")
            net.WriteUInt(-1, 3)
            net.WriteUInt(kboard.Specs.leaderboardPage, 16)
        net.SendToServer()
    end

    local sortOptionsLabel = vgui.Create("DLabel", parent)
        sortOptionsLabel:SetPos(kboard.Specs.Leaderboards.sortOptionsLabelPosX, kboard.Specs.Leaderboards.sortOptionsLabelPosY)
        sortOptionsLabel:SetFont(kboard.Specs.Leaderboards.sortOptionsLabelFont)
        sortOptionsLabel:SetTextColor(kboard.colors.Leaderboards_sortLabel)
        sortOptionsLabel:SetText(kboard.Specs.Leaderboards.sortOptionsLabelText)
        sortOptionsLabel:SizeToContents()

    sortOptions = vgui.Create("DComboBox", parent)
        sortOptions:SetSize(kboard.Specs.Leaderboards.sortOptionsSizeX, kboard.Specs.Leaderboards.sortOptionsSizeY)
        sortOptions:SetPos(kboard.Specs.Leaderboards.sortOptionsPosX, kboard.Specs.Leaderboards.sortOptionsPosY)
        sortOptions:SetText(kboard.leaderboardSortBy)
    for _,v in ipairs(kboard.sortOptions) do
        sortOptions:AddChoice(v.name)
    end

    sortOptions.OnSelect = function( self, index, value )
        local sortby = value
        if (value == "Total Props") then sortby = "PropsSpawned" end
        if (value == "Total Rounds") then sortby = "PRounds" end
        if (value == "K/D") then sortby = "KD" end

        net.Start("kboard_RequestSortPage")
            net.WriteString(sortby)
        net.SendToServer()
    end
end

-- Function exists to not overpopulate the code. --
function kboard.callDList(parent)
    for _,v in ipairs(parent.Columns) do
        v.Header:SetFont(kboard.Specs.Leaderboards.listHeaderFont)
        v.Header:SetTextColor(kboard.colors.Leaderboards_columnHeaderText) -- Color header text
        v.Header.Paint = function(s,w,h)
            kboard.paintFrame(w, h, kboard.colors.Leaderboards_columnHeaderBackground, false)
        end
    end

    local vtable = {}
    local value
    for k,v in ipairs(kboard.leaderboardTable) do
        table.Empty(vtable)

        for _,i in ipairs(kboard.leaderboardColumns) do
            value = v[i.sqlID]
            if (value == "NULL" || value == nil) then value = 0 end
            table.insert(vtable, value)
        end

        parent:AddLine(unpack(vtable))
    end

    for k,v in pairs(parent:GetLines()) do
        v.Paint = function(s,w,h)
            local lineColorEven = kboard.colors.Leaderboards_evenLineColor
            local lineColorOdd  = kboard.colors.Leaderboards_oddLineColor
            if (v:IsHovered()) then
                if (v:GetID() % 2 != 0) then lineColorOdd = kboard.colors.Leaderboards_LineHovered else lineColorEven = kboard.colors.Leaderboards_LineHovered end
            end
            if (v:GetID() % 2 != 0) then
                kboard.paintFrame(w, h, lineColorOdd, false)
            else 
                kboard.paintFrame(w, h, lineColorEven, false)
            end
        end
        for id, pnl in pairs(v.Columns) do
            if not pnl.SetFont then continue end
            pnl:SetFont(kboard.Specs.Leaderboards.dataFont)
            pnl:SetTextColor(kboard.colors.Leaderboards_LineTextColor)
            pnl:SetContentAlignment(5)        
        end
    end
end

function kboard.leaderboardVars(count)

    kboard.Specs.Leaderboards.listHeaderFontSize = 20
    kboard.Specs.Leaderboards.listHeaderFont = "kboard_Default"..(kboard.Specs.Leaderboards.listHeaderFontSize - count)
    kboard.Specs.Leaderboards.listHeaderHeight = 20

    kboard.Specs.Leaderboards.listViewSizeX = kboard.Specs.whiteLine2SizeX
    kboard.Specs.Leaderboards.listViewSizeY = (kboard.Specs.whiteLine3Y - kboard.Specs.whiteLine2Y) - 1 
    kboard.Specs.Leaderboards.listViewPosX = kboard.Specs.whiteLine2X
    kboard.Specs.Leaderboards.listViewPosY = kboard.Specs.frameSizeY * 0.05 + 1

    kboard.Specs.Leaderboards.dataFontSize = 20
    kboard.Specs.Leaderboards.dataFont = "kboard_Default"..(kboard.Specs.Leaderboards.dataFontSize - count)
    kboard.Specs.Leaderboards.dataHeight = (kboard.Specs.Leaderboards.listViewSizeY - kboard.Specs.Leaderboards.listHeaderHeight) / kboard.leaderboardRows

    kboard.Specs.Leaderboards.nextButtonFontSize = 15
    kboard.Specs.Leaderboards.nextButtonFont = "kboard_Default"..(kboard.Specs.Leaderboards.nextButtonFontSize - count)

    kboard.Specs.Leaderboards.nextButtonSizeX = 80
    kboard.Specs.Leaderboards.nextButtonSizeY = 30
    kboard.Specs.Leaderboards.nextButtonPosX  = kboard.Specs.whiteLine2X + kboard.Specs.whiteLine2SizeX - kboard.Specs.Leaderboards.nextButtonSizeX
    kboard.Specs.Leaderboards.nextButtonPosY  = kboard.Specs.whiteLine3Y + kboard.Specs.whiteSpace

    kboard.Specs.Leaderboards.prevButtonFontSize = 15
    kboard.Specs.Leaderboards.prevButtonFont = "kboard_Default"..(kboard.Specs.Leaderboards.nextButtonFontSize - count)
    kboard.Specs.Leaderboards.prevButtonSizeX = 80
    kboard.Specs.Leaderboards.prevButtonSizeY = 30
    kboard.Specs.Leaderboards.prevButtonPosX  = kboard.Specs.whiteLine2X
    kboard.Specs.Leaderboards.prevButtonPosY  = kboard.Specs.whiteLine3Y + kboard.Specs.whiteSpace

    kboard.Specs.Leaderboards.pagesLabelText = kboard.Specs.leaderboardPage.."/"..kboard.Specs.totalPages
    kboard.Specs.Leaderboards.pagesLabelFontSize = 25
    kboard.Specs.Leaderboards.pagesLabelFont = "kboard_Default"..(kboard.Specs.Leaderboards.pagesLabelFontSize - count)
    surface.SetFont(kboard.Specs.Leaderboards.pagesLabelFont)
    local pageW,_ = surface.GetTextSize(kboard.Specs.Leaderboards.pagesLabelText)

    kboard.Specs.Leaderboards.pagesLabelPosX = ((kboard.Specs.Leaderboards.listViewSizeX + kboard.Specs.Leaderboards.listViewPosX) / 2) - (pageW / 2)
    kboard.Specs.Leaderboards.pagesLabelPosY = kboard.Specs.whiteLine3Y + kboard.Specs.whiteSpace

    kboard.Specs.Leaderboards.noticeLabelText = "Double click Players to open their Personal Page!"
    kboard.Specs.Leaderboards.noticeLabelFontSize = 15
    kboard.Specs.Leaderboards.noticeLabelFont = "kboard_Default"..(kboard.Specs.Leaderboards.noticeLabelFontSize - count)
    surface.SetFont(kboard.Specs.Leaderboards.noticeLabelFont)
    local _,h = surface.GetTextSize(kboard.Specs.Leaderboards.noticeLabelText)
    kboard.Specs.Leaderboards.noticeLabelPosX = kboard.Specs.Leaderboards.listViewPosX
    kboard.Specs.Leaderboards.noticeLabelPosY = kboard.Specs.Leaderboards.listViewPosY - h -kboard.Specs.whiteSpace

    kboard.Specs.Leaderboards.sortOptionsSizeX = 70
    kboard.Specs.Leaderboards.sortOptionsSizeY = 20
    kboard.Specs.Leaderboards.sortOptionsPosX = (kboard.Specs.Leaderboards.listViewSizeX + kboard.Specs.Leaderboards.listViewPosX) - kboard.Specs.Leaderboards.sortOptionsSizeX
    kboard.Specs.Leaderboards.sortOptionsPosY = kboard.Specs.Leaderboards.listViewPosY - kboard.Specs.Leaderboards.sortOptionsSizeY - kboard.Specs.whiteSpace

    kboard.Specs.Leaderboards.sortOptionsLabelText = "Sort By:"
    kboard.Specs.Leaderboards.sortOptionsLabelFontSize = 15
    kboard.Specs.Leaderboards.sortOptionsLabelFont = "kboard_Default"..(kboard.Specs.Leaderboards.sortOptionsLabelFontSize - count) 
    surface.SetFont(kboard.Specs.Leaderboards.sortOptionsLabelFont)
    local sortW,sortH = surface.GetTextSize(kboard.Specs.Leaderboards.sortOptionsLabelText)
    kboard.Specs.Leaderboards.sortOptionsLabelPosX = kboard.Specs.Leaderboards.sortOptionsPosX - sortW - kboard.Specs.whiteSpace
    kboard.Specs.Leaderboards.sortOptionsLabelPosY = kboard.Specs.Leaderboards.sortOptionsPosY + (sortH / 4)

end
