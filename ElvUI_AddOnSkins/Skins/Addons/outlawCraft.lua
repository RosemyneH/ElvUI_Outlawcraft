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
local GetContainerItemID = GetContainerItemID
local GetContainerNumSlots = GetContainerNumSlots
local GetItemQualityColor = GetItemQualityColor
local IsAltKeyDown = IsAltKeyDown
local IsControlKeyDown = IsControlKeyDown
local IsShiftKeyDown = IsShiftKeyDown
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
	if not E:IsOutlawEnabled() then return end

	local OC = _G.OutlawCraft
	if not OC then return end
	local outlaw = E.private.outlaw
	local UI = OC.UI

	if E.private.addOnSkins.OutlawCraft and UI then

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
	end

	-- ＼ʕ •ᴥ•ʔ／✿ A Crafting tab under the spellbook's school tabs, so the Blueprints window is one click away ✿ ＼ʕ •ᴥ•ʔ／
	local Builder, book = OC.Builder, _G.SpellBookFrame
	if outlaw.craftTab ~= false and Builder and book then
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

	-- ʕ •ᴥ•ʔ✿ One click for the whole Break down list, sat on that header. Each piece is its own cast, so the next waits until that piece is gone ✿ ʕ •ᴥ•ʔ
	if outlaw.breakAll ~= false and Builder and Builder.rows and Builder.Render and UI and OC.Send and OC.CMD_BREAK_DOWN then
		local BREAK_DOWN = 99
		local breakQueue, breakSent
		local breakAll = UI.Button(Builder.frame, "OutlawCraftBreakAll", "All", 36, 16)
		breakAll:Hide()

		local function SalvageByEntry(entry)
			for _, row in ipairs(Builder.salvage or {}) do
				if row.entry == entry then return row end
			end
		end

		local function UpdateBreakAll()
			local ready = 0
			for _, row in ipairs(Builder.salvage or {}) do
				if row.reason == 0 and (row.have or 0) > 0 then ready = ready + 1 end
			end
			local host
			if breakQueue or ready > 0 then
				for _, row in ipairs(Builder.rows) do
					if row.button and row.button.header == BREAK_DOWN then
						host = row
						break
					end
				end
			end
			breakAll.stopping = breakQueue ~= nil
			if not host then
				breakAll:Hide()
				return
			end
			breakAll:SetParent(host.button)
			breakAll:ClearAllPoints()
			breakAll:SetPoint("RIGHT", host.count, "LEFT", -2, 0)
			breakAll:SetFrameLevel(host.button:GetFrameLevel() + 5)
			breakAll:SetText(breakQueue and "Stop" or "All")
			breakAll:Show()
			host.label:ClearAllPoints()
			host.label:SetPoint("LEFT", host.button, "LEFT", 18, 0)
			host.label:SetPoint("RIGHT", breakAll, "LEFT", -4, 0)
		end

		local function SendBreak(row)
			local qty = math.min(row.have or 1, 100)
			local msg = OC.CMD_BREAK_DOWN .. row.entry
			if qty > 1 then msg = msg .. "," .. qty end
			breakSent = { entry = row.entry, have = row.have }
			OC.Send(msg)
		end

		local function SendNextBreak()
			if not breakQueue then return end
			while #breakQueue > 0 do
				local row = SalvageByEntry(table.remove(breakQueue, 1))
				if row and row.reason == 0 and (row.have or 0) > 0 then
					SendBreak(row)
					UpdateBreakAll()
					return
				end
			end
			breakQueue, breakSent = nil, nil
			UpdateBreakAll()
		end

		local function AdvanceBreakQueue()
			if not breakSent then return end
			local row = SalvageByEntry(breakSent.entry)
			local have = row and row.have or 0
			if have < breakSent.have then
				if row and row.reason == 0 and have > 0 then
					tinsert(breakQueue, 1, row.entry)
				end
				breakSent = nil
				SendNextBreak()
			end
		end

		breakAll:SetScript("OnClick", function()
			if breakQueue then
				breakQueue, breakSent = nil, nil
				UpdateBreakAll()
				return
			end
			local queue = {}
			for _, row in ipairs(Builder.salvage or {}) do
				if row.reason == 0 and (row.have or 0) > 0 then
					tinsert(queue, row.entry)
				end
			end
			if #queue == 0 then return end
			breakQueue = queue
			SendNextBreak()
		end)
		breakAll:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			if self.stopping then
				GameTooltip:SetText("Stop")
				GameTooltip:AddLine("Leave the piece already started. Skip the rest.", 1, 1, 1, true)
			else
				GameTooltip:SetText("Break down all")
				GameTooltip:AddLine("Every piece you can break down, one after another.", 1, 1, 1, true)
			end
			GameTooltip:Show()
		end)
		breakAll:SetScript("OnLeave", GameTooltip_Hide)

		hooksecurefunc(Builder, "Render", function()
			AdvanceBreakQueue()
			UpdateBreakAll()
		end)
		UpdateBreakAll()
	end

	-- ʕ •ᴥ•ʔ✿ Shift-click on Deposit All sends bag stacks the chest already holds. Anything else stays in the bags. A plain click is still Deposit All ✿ ʕ •ᴥ•ʔ
	local function ContainerHas(entry)
		entry = tonumber(entry)
		if not entry or entry == 0 or not OC.Lockbox then return false end
		local items = OC.Lockbox.items
		if items then
			for _, row in ipairs(items) do
				if tonumber(row.entry) == entry and not row.coin then return true end
			end
		end
		local slots = OC.Lockbox.slots
		if slots then
			for _, slot in ipairs(slots) do
				if tonumber(slot.entry) == entry and not slot.coin then return true end
			end
		end
	end

	local depositAll = OC.Lockbox and OC.Lockbox.depositAllButton
	if depositAll and OC.Send and OC.CMD_DEPOSIT then
		depositAll:SetScript("OnClick", function()
			if not IsShiftKeyDown() or IsAltKeyDown() or IsControlKeyDown() then
				OC.Lockbox.DepositAll()
				return
			end
			if OC.Lockbox.readOnly or not OC.Lockbox.IsOpen() then return end
			for b = 0, 4 do
				for s = 1, GetContainerNumSlots(b) or 0 do
					local entry = GetContainerItemID(b, s)
					if ContainerHas(entry) then
						OC.Send(OC.CMD_DEPOSIT .. b .. "," .. s)
					end
				end
			end
		end)
		depositAll:HookScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:SetText("Deposit All")
			GameTooltip:AddLine("Shift-click deposits only items already in the chest.", 1, 1, 1, true)
			GameTooltip:Show()
		end)
		depositAll:HookScript("OnLeave", GameTooltip_Hide)
	end

	-- ʕ •ᴥ•ʔ✿ Sort fills each column downward. Common on the left, rarer to the right. Same item keeps its own column when the grid has room. One real move at a time, the chest's own LBM ✿ ʕ •ᴥ•ʔ
	local lockFrame = OC.Lockbox and OC.Lockbox.frame
	if lockFrame and lockFrame.AddBarButton and OC.UI and OC.UI.Button and OC.Send and OC.CMD_MOVE and OC.Lockbox.Render then
		local sortButton = OC.UI.Button(lockFrame, "ElvUIOutlawLockboxSort", "Sort", 44, 22)
		lockFrame:AddBarButton(sortButton)
		sortButton:Hide()

		local sorting
		local sorter = CreateFrame("Frame")
		sorter:Hide()

		local function StackKey(item)
			return tostring(item.entry) .. ":" .. tostring(item.count or 0) .. ":" .. tostring(item.quality or 0)
		end

		local function ColumnLists(columns, capacity, blocked)
			local cols = {}
			for c = 0, columns - 1 do
				local list, row = {}, 0
				while true do
					local cell = row * columns + c
					if cell >= capacity then break end
					if not blocked[cell] then tinsert(list, cell) end
					row = row + 1
				end
				cols[c + 1] = list
			end
			return cols
		end

		-- ʕ ◕ᴥ◕ ʔ✿ gapped gives each kind a fresh column. Tight packs straight down when that would run out of columns ✿ ʕ ◕ᴥ◕ ʔ
		local function Assign(groups, colLists, gapped)
			local columns, col, row = #colLists, 1, 1
			local cellOf = {}
			for g = 1, #groups do
				local group = groups[g]
				if gapped and row > 1 then
					col, row = col + 1, 1
				end
				for n = 1, #group.items do
					while col <= columns and row > #colLists[col] do
						col, row = col + 1, 1
					end
					if col > columns then return end
					cellOf[group.items[n].index] = colLists[col][row]
					row = row + 1
				end
			end
			return cellOf
		end

		local function PlanSort(items, capacity)
			items = items or {}
			capacity = capacity or 0
			if capacity < 1 then return {} end

			local columns = 6
			if OC.Lockbox.Grid then
				local grid = OC.Lockbox.Grid()
				if grid and grid.columns and grid.columns > 0 then columns = grid.columns end
			elseif OC.UI.ContainerColumns then
				columns = OC.UI.ContainerColumns(capacity)
			end

			local blocked, sortable = {}, {}
			for i = 1, #items do
				local it = items[i]
				if it and it.index ~= nil then
					if it.coin then
						blocked[it.index] = true
					elseif it.entry and it.entry ~= 0 then
						tinsert(sortable, it)
					end
				end
			end
			local groups, grouped = {}, {}
			for i = 1, #sortable do
				local it = sortable[i]
				local key = tostring(it.entry) .. ":" .. tostring(it.quality or 0)
				local group = grouped[key]
				if not group then
					group = { entry = it.entry, quality = it.quality or 0, items = {} }
					grouped[key] = group
					groups[#groups + 1] = group
				end
				tinsert(group.items, it)
			end
			-- ʕ •ᴥ•ʔ✿ Poor sits on the right. Everything else runs common to rare, tallest stack of that kind first ✿ ʕ •ᴥ•ʔ
			local function Rank(quality)
				if not quality or quality <= 0 then return 100 end
				return quality
			end
			table.sort(groups, function(a, b)
				local ra, rb = Rank(a.quality), Rank(b.quality)
				if ra ~= rb then return ra < rb end
				if #a.items ~= #b.items then return #a.items > #b.items end
				local na = a.items[1] and a.items[1].name or ""
				local nb = b.items[1] and b.items[1].name or ""
				if na ~= nb then return na < nb end
				return (a.entry or 0) < (b.entry or 0)
			end)
			for i = 1, #groups do
				table.sort(groups[i].items, function(a, b)
					if (a.count or 0) ~= (b.count or 0) then return (a.count or 0) > (b.count or 0) end
					return (a.index or 0) < (b.index or 0)
				end)
			end

			local cols = ColumnLists(columns, capacity, blocked)
			local cellOf = Assign(groups, cols, true) or Assign(groups, cols, false)
			if not cellOf then return {} end

			local at, want = {}, {}
			for i = 1, #sortable do
				local it = sortable[i]
				at[it.index] = StackKey(it)
				local cell = cellOf[it.index]
				if cell then want[cell] = StackKey(it) end
			end

			local moves = {}
			for cell = 0, capacity - 1 do
				local wk = want[cell]
				if wk and at[cell] ~= wk then
					local src
					for j = 0, capacity - 1 do
						if j ~= cell and at[j] == wk and want[j] ~= wk then
							src = j
							break
						end
					end
					if not src then
						for j = 0, capacity - 1 do
							if j ~= cell and at[j] == wk then
								src = j
								break
							end
						end
					end
					if src and src ~= cell then
						at[src], at[cell] = at[cell], at[src]
						moves[#moves + 1] = { from = src, to = cell }
					end
				end
			end
			return moves
		end

		local function Signature()
			local parts = {}
			local items = OC.Lockbox.items or {}
			for i = 1, #items do
				local it = items[i]
				if it and it.index ~= nil then
					parts[#parts + 1] = it.index .. "=" .. (it.entry or 0) .. ":" .. (it.count or 0)
				end
			end
			table.sort(parts)
			return table.concat(parts, "|")
		end

		local function SyncSortButton()
			if OC.Lockbox.readOnly then
				sortButton:Hide()
			else
				sortButton:Show()
				sortButton:SetText(sorting and "Stop" or "Sort")
			end
		end

		local function StopSort(reason)
			if not sorting then return end
			local moves = sorting.moves
			sorting = nil
			sorter:Hide()
			sortButton:SetText("Sort")
			if reason == false then return end
			if reason then
				OC.Print("Sort stopped: " .. reason .. ".")
			elseif moves == 0 then
				OC.Print("The lockbox is already sorted.")
			else
				OC.Print("Lockbox sorted.")
			end
		end

		local function SortStep()
			if not sorting then return end
			if not OC.Lockbox.IsOpen() then return StopSort(false) end
			if OC.Lockbox.readOnly then return StopSort(false) end
			if GetCursorInfo and GetCursorInfo() then return StopSort("you are holding something") end
			local moves = PlanSort(OC.Lockbox.items, OC.Lockbox.capacity)
			local move = moves[1]
			if not move then return StopSort() end
			if sorting.moves >= sorting.limit then return StopSort("it was going round in circles") end
			local token = move.from .. "," .. move.to
			if sorting.last == token then return StopSort("a move was refused") end
			sorting.last = token
			sorting.moves = sorting.moves + 1
			sorting.wait = true
			sorting.since = GetTime()
			sorting.sig = Signature()
			OC.Send(OC.CMD_MOVE .. token)
		end

		local function StartSort()
			if sorting or not OC.Lockbox.IsOpen() or OC.Lockbox.readOnly then return end
			if GetCursorInfo and GetCursorInfo() then
				OC.Print("Sort: you are holding something.")
				return
			end
			sorting = {
				moves = 0, since = GetTime(), wait = false, sig = Signature(),
				limit = (OC.Lockbox.capacity or 24) * 3 + 10,
			}
			sorter:Show()
			sortButton:SetText("Stop")
			SortStep()
		end

		sortButton:SetScript("OnClick", function()
			if sorting then StopSort("you stopped it") else StartSort() end
		end)
		sortButton:SetScript("OnEnter", function()
			GameTooltip:SetOwner(sortButton, "ANCHOR_BOTTOM")
			GameTooltip:SetText(sorting and "Stop" or "Sort")
			GameTooltip:AddLine("Columns fill downward. Common on the left, rarer to the right. Each item keeps its own column when there is room.", 1, 1, 1, true)
			GameTooltip:Show()
		end)
		sortButton:SetScript("OnLeave", GameTooltip_Hide)

		sorter:SetScript("OnUpdate", function()
			if not sorting then return end
			if not OC.Lockbox.IsOpen() then return StopSort(false) end
			if GetCursorInfo and GetCursorInfo() then return StopSort("you are holding something") end
			if sorting.wait and GetTime() - sorting.since > 5 then
				StopSort("a move did not finish")
			end
		end)

		lockFrame:HookScript("OnHide", function()
			if sorting then StopSort(false) end
		end)

		hooksecurefunc(OC.Lockbox, "Render", function()
			if sorting and sorting.wait then
				local sig = Signature()
				if sig ~= sorting.sig then
					sorting.sig = sig
					sorting.wait = false
					SortStep()
				end
			end
			SyncSortButton()
		end)
	end

	-- ʕ •ᴥ•ʔ✿ Shift-click a bag item to pour every stack of it in, and only when the open container already holds it. Wrapped so the chat link does not also fire ✿ ʕ •ᴥ•ʔ
	local modifiedClick = _G.ContainerFrameItemButton_OnModifiedClick
	if modifiedClick and OC.Lockbox and OC.Send and OC.CMD_DEPOSIT then
		local function SmartDeposit(button, mouseButton)
			if mouseButton and mouseButton ~= "LeftButton" then return end
			if not IsShiftKeyDown() or IsAltKeyDown() or IsControlKeyDown() then return end
			local box = OC.Lockbox
			if not box.IsOpen() or box.readOnly then return end
			local parent = button and button.GetParent and button:GetParent()
			if not parent or not parent.GetID or not button.GetID then return end
			local bag, slot = parent:GetID(), button:GetID()
			if not bag or bag < 0 or bag > 4 then return end
			local entry = GetContainerItemID(bag, slot)
			if not ContainerHas(entry) then return end
			for b = 0, 4 do
				for s = 1, GetContainerNumSlots(b) or 0 do
					if GetContainerItemID(b, s) == entry then
						OC.Send(OC.CMD_DEPOSIT .. b .. "," .. s)
					end
				end
			end
			return true
		end

		_G.ContainerFrameItemButton_OnModifiedClick = function(button, mouseButton)
			if SmartDeposit(button, mouseButton) then return end
			return modifiedClick(button, mouseButton)
		end
	end

	-- ʕノ•ᴥ•ʔノ✿ ElvUI owns the tooltip look, OutlawCraft keeps its maker and realm lines ✿ ʕノ•ᴥ•ʔノ
	if outlaw.tooltips ~= false and E.private.tooltip.enable and OC.Tooltip and OC.Tooltip.OTHER_ADDONS then
		tinsert(OC.Tooltip.OTHER_ADDONS, "ElvUI")
		OC.Tooltip.ApplyStyle = E.noop
	end
end)
