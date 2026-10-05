local E, L, V, P, G = unpack(select(2, ...)); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local DT = E:GetModule("DataTexts")

--Lua functions
local format = string.format
--WoW API / Variables
local hooksecurefunc = hooksecurefunc

local NEED_EVENTS = {"PLAYER_ENTERING_WORLD", "UNIT_AURA", "PLAYER_ALIVE", "PLAYER_UNGHOST"}

local function Hex(r, g, b)
	return E:RGBToHex(r, g, b)
end

local function Colored(r, g, b, text)
	return Hex(r, g, b)..text.."|r"
end

-- ʕ •ᴥ•ʔ✿ Needs come straight off OutlawCraft's own reader, so the bars and the datatext never disagree ✿ ʕ •ᴥ•ʔ
local function Needs()
	return _G.OutlawCraft and _G.OutlawCraft.Needs
end

local function Exposure()
	return _G.OutlawCraft and _G.OutlawCraft.Exposure
end

local function RegisterNeedsText(name, format_)
	local function OnEvent(self, event, unit)
		if event == "UNIT_AURA" and unit ~= "player" then return end
		local N = Needs()
		if not N then self.text:SetText(name..": --") return end
		local hunger, thirst = N.Read()
		self.text:SetText(format_(N, hunger, thirst))
	end

	local function OnEnter(self)
		local N = Needs()
		if not N then return end
		local hunger, thirst = N.Read()
		local percent = N.RegenPercent(hunger, thirst)

		DT:SetupTooltip(self)
		DT.tooltip:AddLine("Food & Water")
		DT.tooltip:AddLine(" ")
		DT.tooltip:AddDoubleLine("Hunger", hunger, 1, 1, 1, N.Colour("hunger", hunger))
		DT.tooltip:AddLine(N.Describe("hunger", hunger), 0.7, 0.7, 0.7, true)
		DT.tooltip:AddLine(" ")
		DT.tooltip:AddDoubleLine("Thirst", thirst, 1, 1, 1, N.Colour("thirst", thirst))
		DT.tooltip:AddLine(N.Describe("thirst", thirst), 0.7, 0.7, 0.7, true)
		DT.tooltip:AddLine(" ")
		DT.tooltip:AddDoubleLine("Regeneration from food and water", percent.."%", 1, 1, 1, N.RegenColour(percent))
		DT.tooltip:Show()
	end

	DT:RegisterDatatext(name, NEED_EVENTS, OnEvent, nil, nil, OnEnter, nil, name)
end

RegisterNeedsText("Hunger", function(N, hunger)
	return "Hunger: "..Hex(N.Colour("hunger", hunger))..hunger.."|r"
end)

RegisterNeedsText("Thirst", function(N, _, thirst)
	return "Thirst: "..Hex(N.Colour("thirst", thirst))..thirst.."|r"
end)

RegisterNeedsText("Hunger Regen", function(N, hunger, thirst)
	local percent = N.RegenPercent(hunger, thirst)
	return "Regen: "..Hex(N.RegenColour(percent))..percent.."%|r"
end)

RegisterNeedsText("Food & Water", function(N, hunger, thirst)
	return Hex(N.Colour("hunger", hunger))..hunger.."|r "..Hex(N.Colour("thirst", thirst))..thirst.."|r"
end)

-- ʕ ◕ᴥ◕ ʔ✿ Exposure is pushed by the server, so the datatext follows OutlawCraft's own Refresh ✿ ʕ ◕ᴥ◕ ʔ
local COMFORTABLE, DRY = 2, 0
local exposurePanels = {}
local exposureHooked

local function ExposureOnEvent(self)
	exposurePanels[self] = true

	local X = Exposure()
	if X and not exposureHooked then
		exposureHooked = true
		hooksecurefunc(X, "Refresh", function()
			for panel in pairs(exposurePanels) do
				if panel:GetScript("OnEvent") == ExposureOnEvent then
					ExposureOnEvent(panel)
				end
			end
		end)
	end

	local s = X and X.state
	if not s then self.text:SetText("Exposure: --") return end

	local hc = X.HEAT_COLOURS[s.heatStage] or X.HEAT_COLOURS[2]
	local wc = X.WET_COLOURS[s.wetStage] or X.WET_COLOURS[0]
	local hide = E.db.datatexts.hideExposureNormal
	local parts = {}
	if not (hide and s.heatStage == COMFORTABLE) then
		parts[#parts + 1] = Colored(hc[1], hc[2], hc[3], X.HEAT_STAGES[s.heatStage] or "")
	end
	if not (hide and s.wetStage == DRY) then
		parts[#parts + 1] = Colored(wc[1], wc[2], wc[3], X.WET_STAGES[s.wetStage] or "")
	end
	self.text:SetText(table.concat(parts, " / "))
end

local function ExposureOnClick(self, button)
	if button ~= "RightButton" then return end
	E.db.datatexts.hideExposureNormal = not E.db.datatexts.hideExposureNormal
	ExposureOnEvent(self)
end

local function ExposureOnEnter(self)
	local X = Exposure()
	local s = X and X.state
	if not s then return end

	local hc = X.HEAT_COLOURS[s.heatStage] or X.HEAT_COLOURS[2]
	local wc = X.WET_COLOURS[s.wetStage] or X.WET_COLOURS[0]

	DT:SetupTooltip(self)
	DT.tooltip:AddLine("Exposure")
	DT.tooltip:AddLine(" ")
	DT.tooltip:AddDoubleLine("Body heat", format("%s (%d)", X.HEAT_STAGES[s.heatStage] or "", s.heat), 1, 1, 1, hc[1], hc[2], hc[3])
	DT.tooltip:AddDoubleLine("Wetness", format("%s (%d%%)", X.WET_STAGES[s.wetStage] or "", s.wetness), 1, 1, 1, wc[1], wc[2], wc[3])
	if s.flags and s.flags > 0 then DT.tooltip:AddLine(" ") end
	if X.Has(s.flags, 1) then DT.tooltip:AddLine("Sheltered", 0.7, 0.7, 0.7) end
	if X.Has(s.flags, 2) then DT.tooltip:AddLine("By a fire", 0.7, 0.7, 0.7) end
	if X.Has(s.flags, 4) then DT.tooltip:AddLine("Rained or snowed on", 0.7, 0.7, 0.7) end
	DT.tooltip:AddLine(" ")
	DT.tooltip:AddLine("Right-click: hide Comfortable / Dry", 0.6, 0.6, 0.6)
	DT.tooltip:Show()
end

DT:RegisterDatatext("Exposure", {"PLAYER_ENTERING_WORLD"}, ExposureOnEvent, nil, ExposureOnClick, ExposureOnEnter, nil, "Exposure")
