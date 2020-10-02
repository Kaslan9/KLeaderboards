AddCSLuaFile()

local pnl = FindMetaTable("Panel")
local plymeta = FindMetaTable("Player")

function kboard.paintFrame(frameSizeX, frameSizeY, frameColor)
    
    if (!isnumber(frameSizeX)) then Error("Number expected, got "..type(frameSizeX)) end
    if (!isnumber(frameSizeY)) then Error("Number expected, got "..type(frameSizeY))  end
    if (!IsColor(frameColor)) then Error("Color expected, got "..type(frameColor)) end

    surface.SetDrawColor(frameColor.r,frameColor.g, frameColor.b, frameColor.a)
    surface.DrawRect(0,0 , frameSizeX, frameSizeY) -- Draw Frame
end

function pnl:kboard_setText(text, font, color,posx, posy)
    self:SetPos(posx,posy)
    self:SetFont(font)
    self:SetTextColor(color)
    self:SetText(text)
    self:SizeToContents()
end

function pnl:kboard_centerTextH(text, font)
    local _,ph = self:GetParent():GetSize()
    surface.SetFont(font)
    local _,h = surface.GetTextSize(text)

    return ((ph - h) / 2)
end

function pnl:kboard_createPanels(table, category)
    kboard.PersonalVars(kboard.Specs.Personal.countForWeapons, nil)
    local countx = 0
    local county = 0
    for _,v in ipairs(kboard.weaponList) do
        if (v.category != category.name) then continue end

        if countx == 3 then countx = 0 county = county + 1 end
        local panelPosX = kboard.Specs.Personal.WeaponPanelPosX + (kboard.Specs.Personal.WeaponPanelSizeX * countx) + kboard.Specs.whiteSpace
        local panelPosY = (kboard.Specs.Personal.WeaponPanelSizeY  * county) + kboard.Specs.whiteSpace
        if (table.Name == nil) then 
            weaponKills = table[1][v.sqlname]
        else
            weaponKills = table[v.sqlname]
        end
        if (weaponKills == nil || weaponKills == "NULL") then weaponKills = 0 end

        kboard_panel(v.name, self,panelPosX, panelPosY,weaponKills , kboard.colors.Personal_weaponPanelText, kboard.colors.Personal_weaponPanel , kboard.Specs.Personal.WeaponFont)

        countx = countx + 1
    end
end

function kboard_panel(weapon, parent, posX, posY, kills, textColor, frameColor, font)
    local bottomLine = 1

    local weapons = vgui.Create("DPanel", parent)
    weapons:SetSize(kboard.Specs.Personal.WeaponPanelSizeX,kboard.Specs.Personal.WeaponPanelSizeY)
    weapons:SetPos(posX, posY)
    weapons.Paint = function(s,w,h)
        kboard.paintFrame(w, h, frameColor)
        surface.SetDrawColor(kboard.colors.Personal_weaponBottomLine)
        surface.DrawRect(0, h - bottomLine, w, bottomLine)
    end 

    local text = weapon..": "..kills
    local weaponsText = vgui.Create("DLabel", weapons)
    local h = weaponsText:kboard_centerTextH(text, font)
    weaponsText:kboard_setText(text, font, textColor,kboard.Specs.whiteSpace, h)

end


-- converts time in seconds to format: ww dd hh mm ss
function kboard_timeToStr( time )
	local tmp = time
	local s = tmp % 60
	tmp = math.floor( tmp / 60 )
	local m = tmp % 60
	tmp = math.floor( tmp / 60 )
	local h = tmp % 24
	tmp = math.floor( tmp / 24 )
	local d = tmp % 7
	local w = math.floor( tmp / 7 )

    return string.format( "%02iw %id %02ih %02im %02is", w, d, h, m, s ) 
end

function kboard.updateTextPos(text, font) -- Update Text Pos for resolution scaling and titles
    surface.SetFont(font)
    local _, h = surface.GetTextSize(text)
    local y = kboard.Specs.whiteLine1Y - kboard.Specs.whiteSpace - h
    local x = kboard.Specs.titlePosX
    return x,y
end

function kboard.setText(text, font, label) -- Set the text for resolution scaling and titles
    label:SetFont(font)
    label:SetPos(kboard.updateTextPos(text,font))
    label:SetText(text)
    label:SizeToContents()
end

function plymeta:kboard_CMSG(msg)
    chat.AddText(col_black, "[", col_orange,"KLeaderboards", col_black, "] ",col_white, msg)
end