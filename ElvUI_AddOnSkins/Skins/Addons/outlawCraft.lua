local E, L, V, P, G = unpack(ElvUI)
local S = E:GetModule("Skins")
local AS = E:GetModule("AddOnSkins")

if not AS:IsAddonLODorEnabled("OutlawCraft") then return end

local _G = _G
local pairs, ipairs, unpack, type = pairs, ipairs, unpack, type
local floor = math.floor
local find, format, lower = string.find, string.format, string.lower
local tinsert = table.insert
local EnumerateFrames = EnumerateFrames
local GetItemQualityColor = GetItemQualityColor
local hooksecurefunc = hooksecurefunc

local function Hex(r, g, b)
	return format("%02x%02x%02x", floor(r * 255 + 0.5), floor(g * 255 + 0.5), floor(b * 255 + 0.5))
end

local function Palette()
	local value = E.media.rgbvaluecolor
	local backdrop = E.media.backdropcolor
	local fade = E.media.backdropfadecolor
	local border = E.media.bordercolor
	local black, white = {0, 0, 0}, {1, 1, 1}
	local soft, muted, dim = {0.9, 0.9, 0.9}, {0.6, 0.6, 0.6}, {0.5, 0.5, 0.5}

	return {
		shadow = black, window = fade, edge = border, bar = backdrop, barEdge = border,
		pane = fade, rule = border, ruleSoft = border, card = backdrop, input = fade,
		button = backdrop, buttonEdge = border, buttonHot = value,
		primary = backdrop, primaryHot = value,
		selected = {value[1] * 0.3, value[2] * 0.3, value[3] * 0.3},
		banner = backdrop, bannerEdge = value,
		gold = value, goldBright = value, goldDim = value, badge = value,
		text = white, textSoft = soft, textButton = white, muted = muted, dim = dim,
		unusable = dim, bannerText = white, onBadge = black, onPrimary = white,
	}
end

S:AddCallbackForAddon("OutlawCraft", "OutlawCraft", function()
	if not E.private.addOnSkins.OutlawCraft then return end

	local OC = _G.OutlawCraft
	if not OC or not OC.UI then return end
	local UI = OC.UI

	-- ʕ •ᴥ•ʔ✿ Windows built at load keep their palette colours, so remember them before the swap ✿ ʕ •ᴥ•ʔ
	local palette = Palette()
	local remap = {}
	for key, colour in pairs(UI.COLOUR) do
		if palette[key] then
			remap[Hex(colour.r, colour.g, colour.b)] = palette[key]
		end
	end
	for key, rgb in pairs(palette) do
		local colour = UI.COLOUR[key]
		if colour then
			colour.r, colour.g, colour.b = rgb[1], rgb[2], rgb[3]
			colour.hex = E:RGBToHex(rgb[1], rgb[2], rgb[3])
		end
	end

	local ocFonts = {}
	for face, path in pairs(UI.FONT) do
		ocFonts[lower(path)] = true
		UI.FONT[face] = E.media.normFont
	end

	local function Recolour(r, g, b)
		if not r then return end
		return remap[Hex(r, g, b)]
	end

	local function RestyleFont(obj)
		local path, size, flags = obj:GetFont()
		if path and ocFonts[lower(path)] then
			obj:SetFont(E.media.normFont, size, flags)
		end
		local r, g, b, a = obj:GetTextColor()
		local rgb = Recolour(r, g, b)
		if rgb then obj:SetTextColor(rgb[1], rgb[2], rgb[3], a) end
	end

	local function RestyleTexture(tex)
		local path = tex:GetTexture()
		if type(path) ~= "string" then return end
		path = lower(path)
		if not (find(path, "white8x8", 1, true) or find(path, "addons\\outlawcraft\\textures\\ui", 1, true)) then return end
		local r, g, b, a = tex:GetVertexColor()
		local rgb = Recolour(r, g, b)
		if rgb then tex:SetVertexColor(rgb[1], rgb[2], rgb[3], a) end
	end

	local function StyleWindow(frame)
		frame:SetTemplate("Transparent")
		if frame.shadow then
			for _, strip in ipairs(frame.shadow) do strip:Hide() end
		end
	end

	local function PaintSlotBorder(slot)
		local quality = slot.quality
		if quality and quality >= 2 then
			local r, g, b = GetItemQualityColor(quality)
			slot:SetBackdropBorderColor(r, g, b)
		else
			slot:SetBackdropBorderColor(unpack(E.media.bordercolor))
		end
		slot.glow:Hide()
	end

	local function StyleSlot(slot)
		if slot.isSkinned then return end
		slot:SetNormalTexture(nil)
		slot:SetTemplate("Default", true)
		slot:StyleButton()
		if slot.icon then
			slot.icon:SetTexCoord(unpack(E.TexCoords))
			slot.icon:SetInside()
		end
		hooksecurefunc(slot, "SetItem", PaintSlotBorder)
		hooksecurefunc(slot, "Clear", PaintSlotBorder)
		PaintSlotBorder(slot)
		slot.isSkinned = true
	end

	local function StyleScrollThumb(bar)
		local thumb = bar.GetThumbTexture and bar:GetThumbTexture()
		if thumb then thumb:SetVertexColor(unpack(E.media.rgbvaluecolor)) end
	end

	local owned = {}
	local function IsOC(frame)
		if not frame then return false end
		if owned[frame] ~= nil then return owned[frame] end
		local name = frame:GetName()
		local result = (frame.ocSkinned or frame.ocKey or (name and find(name, "^OutlawCraft")) or IsOC(frame:GetParent())) and true or false
		owned[frame] = result
		return result
	end

	local function Restyle(frame)
		if frame.ocSkinned and frame.GetBackdropColor then
			local r, g, b, a = frame:GetBackdropColor()
			local rgb = Recolour(r, g, b)
			if rgb then frame:SetBackdropColor(rgb[1], rgb[2], rgb[3], a) end
			r, g, b, a = frame:GetBackdropBorderColor()
			rgb = Recolour(r, g, b)
			if rgb then frame:SetBackdropBorderColor(rgb[1], rgb[2], rgb[3], a) end
		end

		if frame.bar and frame.close and frame.shadow then
			StyleWindow(frame)
		elseif frame.glow and frame.SetItem then
			StyleSlot(frame)
		end

		local objectType = frame:GetObjectType()
		if objectType == "EditBox" then
			RestyleFont(frame)
		elseif objectType == "Slider" then
			StyleScrollThumb(frame)
		end

		for _, region in ipairs({frame:GetRegions()}) do
			local regionType = region:GetObjectType()
			if regionType == "Texture" then
				RestyleTexture(region)
			elseif regionType == "FontString" then
				RestyleFont(region)
			end
		end
	end

	local obj = EnumerateFrames()
	while obj do
		if IsOC(obj) then Restyle(obj) end
		obj = EnumerateFrames(obj)
	end

	-- ʕ ◕ᴥ◕ ʔ✿ Windows and slots built later go through the kit, so wrap it ✿ ʕ ◕ᴥ◕ ʔ
	local Window, ItemSlot, SkinScrollBar = UI.Window, UI.ItemSlot, UI.SkinScrollBar
	function UI.Window(...)
		local window = Window(...)
		StyleWindow(window)
		return window
	end
	function UI.ItemSlot(...)
		local slot = ItemSlot(...)
		StyleSlot(slot)
		return slot
	end
	function UI.SkinScrollBar(name)
		SkinScrollBar(name)
		local bar = _G[name.."ScrollBar"]
		if bar then StyleScrollThumb(bar) end
	end

	-- ＼ʕ •ᴥ•ʔ／✿ A Crafting tab under the spellbook's school tabs, so the Blueprints window is one click away ✿ ＼ʕ •ᴥ•ʔ／
	local Builder, book = OC.Builder, _G.SpellBookFrame
	if Builder and book then
		local BLUEPRINTS_SPELL = 901514
		local icon = select(3, GetSpellInfo(BLUEPRINTS_SPELL)) or "Interface\\Icons\\Trade_Engineering"

		local tab = CreateFrame("CheckButton", "OutlawCraftSpellBookCraftTab", book)
		tab:Size(32)
		tab:SetNormalTexture(icon)
		tab:GetNormalTexture():SetTexCoord(unpack(E.TexCoords))
		tab:GetNormalTexture():SetInside()
		tab:SetTemplate("Default", true)
		tab:StyleButton(nil, true)

		local function Place()
			local last
			for i = _G.MAX_SKILLLINE_TABS, 1, -1 do
				local skillTab = _G["SpellBookSkillLineTab"..i]
				if skillTab and skillTab:IsShown() then last = skillTab break end
			end
			tab:ClearAllPoints()
			if last then
				tab:Point("TOPLEFT", last, "BOTTOMLEFT", 0, -17)
			else
				tab:Point("TOPLEFT", book, "TOPRIGHT", -33, -65)
			end
			if book.bookType == _G.BOOKTYPE_PET then tab:Hide() else tab:Show() end
			tab:SetChecked(Builder.IsOpen())
		end

		tab:SetScript("OnClick", function(self)
			if Builder.IsOpen() then Builder.Close() else Builder.Open() end
			self:SetChecked(Builder.IsOpen())
		end)
		tab:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText("Crafting")
			GameTooltip:AddLine("Open the Blueprints crafting window.", 1, 1, 1, true)
			GameTooltip:Show()
		end)
		tab:SetScript("OnLeave", GameTooltip_Hide)

		book:HookScript("OnShow", Place)
		if _G.SpellBookFrame_UpdateSkillLineTabs then
			hooksecurefunc("SpellBookFrame_UpdateSkillLineTabs", Place)
		end
		Builder.frame:HookScript("OnShow", function() tab:SetChecked(true) end)
		Builder.frame:HookScript("OnHide", function() tab:SetChecked(false) end)
		Place()
	end

	-- ʕノ•ᴥ•ʔノ✿ ElvUI owns the tooltip look, OutlawCraft keeps its maker and realm lines ✿ ʕノ•ᴥ•ʔノ
	if E.private.tooltip.enable and OC.Tooltip and OC.Tooltip.OTHER_ADDONS then
		tinsert(OC.Tooltip.OTHER_ADDONS, "ElvUI")
		OC.Tooltip.ApplyStyle = E.noop
	end
end)
