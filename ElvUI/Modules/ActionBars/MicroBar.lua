local E, L, V, P, G = unpack(select(2, ...)); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local AB = E:GetModule("ActionBars")

--Lua functions
local _G = _G
local unpack = unpack
--WoW API / Variables
local CreateFrame = CreateFrame
local GameTooltip = GameTooltip
local InCombatLockdown = InCombatLockdown
local RegisterStateDriver = RegisterStateDriver

_G.SHOW_TALENT_LEVEL = 1

local MICRO_BUTTONS = {
	"CharacterMicroButton",
	"SpellbookMicroButton",
	"TalentMicroButton",
	"AchievementMicroButton",
	"QuestLogMicroButton",
	"SocialsMicroButton",
	"PVPMicroButton",
	"LFDMicroButton",
	"MainMenuMicroButton",
	"HelpMicroButton",
}

do
	local existing = {}
	for i = 1, #MICRO_BUTTONS do
		if _G[MICRO_BUTTONS[i]] then
			existing[#existing + 1] = MICRO_BUTTONS[i]
		end
	end
	MICRO_BUTTONS = existing
end

local function onEnter(button)
	if AB.db.microbar.mouseover then
		E:UIFrameFadeIn(ElvUI_MicroBar, 0.2, ElvUI_MicroBar:GetAlpha(), AB.db.microbar.alpha)
	end

	if button and button ~= ElvUI_MicroBar and button.backdrop then
		button.backdrop:SetBackdropBorderColor(unpack(E.media.rgbvaluecolor))
	end
end

local function onLeave(button)
	if AB.db.microbar.mouseover then
		E:UIFrameFadeOut(ElvUI_MicroBar, 0.2, ElvUI_MicroBar:GetAlpha(), 0)
	end

	if button and button ~= ElvUI_MicroBar and button.backdrop then
		button.backdrop:SetBackdropBorderColor(unpack(E.media.bordercolor))
	end
end

function AB:HandleMicroButton(button)
	if not button then return end
	local pushed = button:GetPushedTexture()
	local normal = button:GetNormalTexture()
	local disabled = button:GetDisabledTexture()
	local highlight = button:GetHighlightTexture()

	local f = CreateFrame("Frame", nil, button)
	f:SetFrameLevel(button:GetFrameLevel() - 1)
	f:SetTemplate("Default", true)
	f:SetOutside(button)
	button.backdrop = f

	button:SetParent(ElvUI_MicroBar)
	if highlight then highlight:Kill() end
	button:HookScript("OnEnter", onEnter)
	button:HookScript("OnLeave", onLeave)
	button:SetHitRectInsets(0, 0, 0, 0)
	button:Show()

	local l, r, t, b = 0.17, 0.87, 0.5, 0.908
	if button.useFullIcon then
		l, r, t, b = unpack(E.TexCoords)
	end

	if pushed then
		pushed:SetTexCoord(l, r, t, b)
		pushed:SetInside(f)
	end

	if normal then
		normal:SetTexCoord(l, r, t, b)
		normal:SetInside(f)
	end

	if disabled then
		disabled:SetTexCoord(l, r, t, b)
		disabled:SetInside(f)
	end
end

function AB:UpdateMicroButtonsParent()
	if CharacterMicroButton:GetParent() == ElvUI_MicroBar then return end

	for i = 1, #MICRO_BUTTONS do
		local button = _G[MICRO_BUTTONS[i]]
		if button then
			button:SetParent(ElvUI_MicroBar)
		end
	end

	AB:UpdateMicroPositionDimensions()
end

function AB:UpdateMicroBarVisibility()
	if InCombatLockdown() then
		AB.NeedsUpdateMicroBarVisibility = true
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end

	local visibility = self.db.microbar.visibility
	if visibility and string.match(visibility, "[\n\r]") then
		visibility = string.gsub(visibility, "[\n\r]", "")
	end

	RegisterStateDriver(ElvUI_MicroBar.visibility, "visibility", (self.db.microbar.enabled and visibility) or "hide")
end

function AB:UpdateMicroPositionDimensions()
	if not ElvUI_MicroBar then return end

	local numRows = 1
	local prevButton = ElvUI_MicroBar
	local offset = E:Scale(E.PixelMode and 1 or 3)
	local spacing = E:Scale(offset + self.db.microbar.buttonSpacing)

	for i = 1, #MICRO_BUTTONS do
		local button = _G[MICRO_BUTTONS[i]]
		if button then
			local lastColumnButton = i - self.db.microbar.buttonsPerRow
			lastColumnButton = _G[MICRO_BUTTONS[lastColumnButton]]

			button:Size(self.db.microbar.buttonSize, self.db.microbar.buttonSize * 1.4)
			button:ClearAllPoints()

			if prevButton == ElvUI_MicroBar then
				button:Point("TOPLEFT", prevButton, "TOPLEFT", offset, -offset)
			elseif (i - 1) % self.db.microbar.buttonsPerRow == 0 and lastColumnButton then
				button:Point("TOP", lastColumnButton, "BOTTOM", 0, -spacing)
				numRows = numRows + 1
			else
				button:Point("LEFT", prevButton, "RIGHT", spacing, 0)
			end

			prevButton = button
		end
	end

	if AB.db.microbar.mouseover and not ElvUI_MicroBar:IsMouseOver() then
		ElvUI_MicroBar:SetAlpha(0)
	else
		ElvUI_MicroBar:SetAlpha(self.db.microbar.alpha)
	end

	AB.MicroWidth = (((CharacterMicroButton:GetWidth() + spacing) * self.db.microbar.buttonsPerRow) - spacing) + (offset * 2)
	AB.MicroHeight = (((CharacterMicroButton:GetHeight() + spacing) * numRows) - spacing) + (offset * 2)
	ElvUI_MicroBar:Size(AB.MicroWidth, AB.MicroHeight)

	if ElvUI_MicroBar.mover then
		if self.db.microbar.enabled then
			E:EnableMover(ElvUI_MicroBar.mover:GetName())
		else
			E:DisableMover(ElvUI_MicroBar.mover:GetName())
		end
	end

	self:UpdateMicroBarVisibility()
end

local function BuildIcon()
	return select(3, GetSpellInfo(901514)) or "Interface\\Icons\\Trade_Engineering"
end

function AB:SetupBuildMicroButton()
	local button = _G.LFDMicroButton
	if not button then return end

	local icon = BuildIcon()
	button:SetNormalTexture(icon)
	button:SetPushedTexture(icon)
	button:SetDisabledTexture(icon)
	button:Enable()

	local l, r, t, b = unpack(E.TexCoords)
	for _, tex in ipairs({button:GetNormalTexture(), button:GetPushedTexture(), button:GetDisabledTexture()}) do
		if tex then
			tex:SetTexCoord(l, r, t, b)
			if button.backdrop then tex:SetInside(button.backdrop) end
		end
	end

	button.tooltipText = "Build Menu"
	button.newbieText = "Open the Blueprints window."
	button:SetScript("OnClick", function()
		local Builder = _G.OutlawCraft and _G.OutlawCraft.Builder
		if not Builder then return end
		if Builder.IsOpen() then Builder.Close() else Builder.Open() end
	end)
	if not button.buildTip then
		button.buildTip = true
		button:HookScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText("Build Menu", 1, 1, 1)
			GameTooltip:AddLine("Open the Blueprints window.", 1, 1, 1, true)
			GameTooltip:Show()
		end)
	end
end

function AB:UpdateMicroButtons()
	if _G.PVPMicroButtonTexture and _G.PVPMicroButton then
		PVPMicroButtonTexture:Point("TOPLEFT", PVPMicroButton, "TOPLEFT")
		PVPMicroButtonTexture:Point("BOTTOMRIGHT", PVPMicroButton, "BOTTOMRIGHT")
		PVPMicroButtonTexture:SetTexture("Interface\\AddOns\\ElvUI\\media\\textures\\PVP-Icons")

		if PVPMicroButton.minLevel and E.mylevel < PVPMicroButton.minLevel then
			PVPMicroButtonTexture:SetDesaturated(true)
		else
			PVPMicroButtonTexture:SetDesaturated(false)
		end
	end

	if _G.TalentMicroButton then
		_G.SHOW_TALENT_LEVEL = 1
		TalentMicroButton:Enable()
		if _G.MicroButtonTooltipText and _G.TALENTS then
			TalentMicroButton.tooltipText = MicroButtonTooltipText(TALENTS, "TOGGLETALENTS")
		end
	end

	self:SetupBuildMicroButton()
	self:UpdateMicroPositionDimensions()
end

function AB:SetupMicroBar()
	local microBar = CreateFrame("Frame", "ElvUI_MicroBar", E.UIParent)
	microBar:Point("TOPLEFT", E.UIParent, "TOPLEFT", 4, -4)
	microBar:SetFrameStrata("LOW")
	microBar:EnableMouse(true)
	microBar:SetScript("OnEnter", onEnter)
	microBar:SetScript("OnLeave", onLeave)

	microBar.visibility = CreateFrame("Frame", nil, E.UIParent, "SecureHandlerStateTemplate")
	microBar.visibility:SetScript("OnShow", function() microBar:Show() end)
	microBar.visibility:SetScript("OnHide", function() microBar:Hide() end)

	for i = 1, #MICRO_BUTTONS do
		self:HandleMicroButton(_G[MICRO_BUTTONS[i]])
	end

	self:SetupBuildMicroButton()

	if CharacterMicroButton and CharacterMicroButton.backdrop then
		MicroButtonPortrait:SetInside(CharacterMicroButton.backdrop)
	end

	if PVPMicroButtonTexture then
		if E.myfaction == "Alliance" then
			PVPMicroButtonTexture:SetTexCoord(0.545, 0.935, 0.070, 0.940)
		else
			PVPMicroButtonTexture:SetTexCoord(0.100, 0.475, 0.070, 0.940)
		end
	end

	self:SecureHook("VehicleMenuBar_MoveMicroButtons", "UpdateMicroButtonsParent")
	self:SecureHook("UpdateMicroButtons")

	self:UpdateMicroPositionDimensions()
	if MainMenuBarPerformanceBar then
		MainMenuBarPerformanceBar:Kill()
	end

	E:CreateMover(microBar, "MicrobarMover", L["Micro Bar"], nil, nil, nil, "ALL,ACTIONBARS", nil, "actionbar,microbar")
end