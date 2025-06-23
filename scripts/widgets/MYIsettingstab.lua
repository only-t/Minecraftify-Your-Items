local Widget = require("widgets/widget")
local Grid = require("widgets/grid")
local Text = require("widgets/text")
local Image = require("widgets/image")

local TEMPLATES = require("widgets/redux/templates")

local label_width = 200
local spinner_width = 220
local spinner_height = 36
local narrow_field_nudge = -50
local space_between = 5

local function AddListItemBackground(w)
	local total_width = label_width + spinner_width + space_between
	w.bg = w:AddChild(TEMPLATES.ListItemBackground(total_width + 15, spinner_height + 5))
	w.bg:SetPosition(-40, 0)
	w.bg:MoveToBack()
end

local function CreateTextSpinner(labeltext, spinnerdata, tooltip_text)
	local w = TEMPLATES.LabelSpinner(labeltext, spinnerdata, label_width, spinner_width, spinner_height, space_between, nil, nil, narrow_field_nudge, nil, nil, tooltip_text)
	AddListItemBackground(w)

	return w.spinner
end

local function MakeSpinnerTooltip(root)
	local spinner_tooltip = root:AddChild(Text(CHATFONT, 25, ""))
	spinner_tooltip:SetPosition(90, -275)
	spinner_tooltip:SetHAlign(ANCHOR_LEFT)
	spinner_tooltip:SetVAlign(ANCHOR_TOP)
	spinner_tooltip:SetRegionSize(800, 80)
	spinner_tooltip:EnableWordWrap(true)

	return spinner_tooltip
end

local function AddSpinnerTooltip(widget, tooltip, tooltipdivider)
	tooltipdivider:Hide()

	local function ongainfocus()
		if tooltip and widget.tooltip_text then
			tooltip:SetString(widget.tooltip_text)
			tooltipdivider:Show()
		end
	end
	
	local function onlosefocus()
		if widget.parent and not widget.parent.focus then
			tooltip:SetString("")
			tooltipdivider:Hide()
		end
	end

	widget.bg.ongainfocus = ongainfocus

	if widget.spinner then
		widget.spinner.ongainfocusfn = ongainfocus
	elseif widget.button then
		widget.button.ongainfocus = ongainfocus
	end

	widget.bg.onlosefocus = onlosefocus

	if widget.spinner then
		widget.spinner.onlosefocusfn = onlosefocus
	elseif widget.button then
		widget.button.onlosefocus = onlosefocus
	end
end

local enableDisableOptions = {
    { text = STRINGS.UI.OPTIONS.DISABLED, data = false },
    { text = STRINGS.UI.OPTIONS.ENABLED,  data = true  }
}

local MinecraftifySettingsTab = Class(Widget, function(self, owner)
    self.owner = owner
    Widget._ctor(self, "MinecraftifySettingsTab")

    self.grid_graphics = self:AddChild(Grid())
    self.grid_graphics:SetPosition(-90, 184, 0)

    self.worldYSpinner = CreateTextSpinner(MYI.SETTINGS.OPTIONS.WORLD_Y.NAME, enableDisableOptions, MYI.SETTINGS.OPTIONS.WORLD_Y.TOOLTIP)
    self.worldYSpinner.OnChanged = function(_, data)
		self.owner.working[MYI.SETTINGS.OPTIONS.WORLD_Y.OPTIONS_STR] = data
		self.owner:UpdateMenu()
	end
    self.worldYSpinner:Enable()

    self.shadowsSpinner = CreateTextSpinner(MYI.SETTINGS.OPTIONS.SHADOWS.NAME, enableDisableOptions, MYI.SETTINGS.OPTIONS.SHADOWS.TOOLTIP)
    self.shadowsSpinner.OnChanged = function(_, data)
		self.owner.working[MYI.SETTINGS.OPTIONS.SHADOWS.OPTIONS_STR] = data
		self.owner:UpdateMenu()
	end
    self.shadowsSpinner:Enable()

	self.left_spinners_graphics = {}
    table.insert(self.left_spinners_graphics, self.worldYSpinner)
    table.insert(self.left_spinners_graphics, self.shadowsSpinner)

	self.grid_graphics:UseNaturalLayout()
	self.grid_graphics:InitSize(2, math.max(#self.left_spinners_graphics, 0), 440, 40)

	local spinner_tooltip = MakeSpinnerTooltip(self)
	local spinner_tooltip_divider = self:AddChild(Image("images/global_redux.xml", "item_divider.tex"))
	spinner_tooltip_divider:SetPosition(90, -225)

	for k, v in ipairs(self.left_spinners_graphics) do
		self.grid_graphics:AddItem(v.parent, 1, k)
		AddSpinnerTooltip(v.parent, spinner_tooltip, spinner_tooltip_divider)
	end

    self.focus_forward = self.grid_graphics
end)

return MinecraftifySettingsTab