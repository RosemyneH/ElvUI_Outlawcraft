local E, _, V, P, G = unpack(ElvUI)
local C, L = unpack(select(2, ...))

local function outlawOff()
	return not E:IsOutlawEnabled()
end

E.Options.args.outlaw = {
	order = 49,
	type = "group",
	name = L["Outlaw"],
	childGroups = "tab",
	get = function(info)
		local outlaw = E.private.outlaw
		if not outlaw then return true end
		return outlaw[info[#info]] ~= false
	end,
	set = function(info, value)
		E.private.outlaw = E.private.outlaw or {}
		E.private.outlaw[info[#info]] = value
		E:StaticPopup_Show("PRIVATE_RL")
	end,
	args = {
		intro = {
			order = 1,
			type = "description",
			name = L["OUTLAW_DESC"],
		},
		enable = {
			order = 2,
			type = "toggle",
			name = L["Enable Outlaw"],
			desc = L["OUTLAW_ENABLE_DESC"],
		},
		featuresHeader = {
			order = 3,
			type = "header",
			name = L["OutlawCraft"],
		},
		skin = {
			order = 4,
			type = "toggle",
			name = L["Outlaw Skin"],
			desc = L["OUTLAW_SKIN_DESC"],
			disabled = outlawOff,
			get = function()
				return E.private.addOnSkins and E.private.addOnSkins.OutlawCraft and true or false
			end,
			set = function(_, value)
				E.private.addOnSkins = E.private.addOnSkins or {}
				E.private.addOnSkins.OutlawCraft = value
				E:StaticPopup_Show("PRIVATE_RL")
			end,
		},
		craftTab = {
			order = 5,
			type = "toggle",
			name = L["Crafting Tab"],
			desc = L["OUTLAW_CRAFT_DESC"],
			disabled = outlawOff,
		},
		breakAll = {
			order = 6,
			type = "toggle",
			name = L["Break Down All"],
			desc = L["OUTLAW_BREAK_DESC"],
			disabled = outlawOff,
		},
		tooltips = {
			order = 7,
			type = "toggle",
			name = L["Tooltips"],
			desc = L["OUTLAW_TOOLTIP_DESC"],
			disabled = outlawOff,
		},
		loot = {
			order = 8,
			type = "toggle",
			name = L["Yield Loot Frame"],
			desc = L["OUTLAW_LOOT_DESC"],
			disabled = outlawOff,
		},
		hideExposure = {
			order = 9,
			type = "toggle",
			name = L["Hide Exposure"],
			desc = L["OUTLAW_EXPOSURE_DESC"],
			disabled = function()
				return not (_G.OutlawCraft and _G.OutlawCraft.Settings)
			end,
			get = function()
				local settings = _G.OutlawCraft and _G.OutlawCraft.Settings
				return settings and settings.Get("exposureMeter") == false
			end,
			set = function(_, value)
				local settings = _G.OutlawCraft and _G.OutlawCraft.Settings
				if settings then settings.Set("exposureMeter", not value) end
			end,
		},
	},
}
