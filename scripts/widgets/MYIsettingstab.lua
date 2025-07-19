local Widget = require("widgets/widget")
local Grid = require("widgets/grid")
local Text = require("widgets/text")
local Image = require("widgets/image")
local MYIEditListScreen = require("screens/MYIeditlistscreen")

local TEMPLATES = require("widgets/redux/templates")

local label_width = 200
local spinner_width = 220
local spinner_height = 36
local narrow_field_nudge = -50
local space_between = 5

local function OpenList(optionsscreen, list_title, data)
	local editlist = MYIEditListScreen(optionsscreen, list_title, data)
	TheFrontEnd:PushScreen(editlist)
end

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

local function CreateSettingButton(labeltext, btn_action, tooltip_text)
    local font = CHATFONT
    local font_size = 25
    local offset = narrow_field_nudge

    local total_width = label_width + spinner_width + space_between
    local w = Widget("labelbtn")
    w.label = w:AddChild(Text(font, font_size, labeltext))
    w.label:SetPosition((-total_width / 2) + (label_width / 2) + offset, 0)
    w.label:SetRegionSize(label_width, spinner_height)
    w.label:SetHAlign(ANCHOR_RIGHT)
    w.label:SetColour(UICOLOURS.GOLD)
    w.btn = w:AddChild(TEMPLATES.StandardButton(btn_action, "Open", { spinner_width, spinner_height }))
    w.btn:SetPosition((total_width / 2) - (spinner_width / 2) + offset, 0)

    w.focus_forward = w.btn

    w.tooltip_text = tooltip_text

	AddListItemBackground(w)

	return w.btn
end

local function MakeTooltip(root)
	local w = root:AddChild(Text(CHATFONT, 25, ""))
	w:SetPosition(90, -275)
	w:SetHAlign(ANCHOR_LEFT)
	w:SetVAlign(ANCHOR_TOP)
	w:SetRegionSize(800, 80)
	w:EnableWordWrap(true)

	return w
end

local function AddSettingTooltip(widget, type, tooltip, tooltipdivider)
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
	widget.bg.onlosefocus = onlosefocus

	if type == MYI.SETTING_TYPES.SPINNER then
		widget.spinner.ongainfocusfn = ongainfocus
		widget.spinner.onlosefocusfn = onlosefocus
	elseif type == MYI.SETTING_TYPES.LIST then
		widget.btn.ongainfocus = ongainfocus
		widget.btn.onlosefocus = onlosefocus
	end
end

local MYISettingsTab = Class(Widget, function(self, owner, settings)
    self.owner = owner
	self.loaded_settings = settings
    Widget._ctor(self, "MYISettingsTab")

    self.grid = self:AddChild(Grid())
    self.grid:SetPosition(-90, 184, 0)

	self.left_column = {  }
	self.right_column = {  }
	for name, setting in pairs(MYI.MOD_SETTINGS.SETTINGS) do
		local widget_name = ""
		if setting.TYPE == MYI.SETTING_TYPES.SPINNER then
			widget_name = string.lower(setting.ID).."_spinner"
			self[widget_name] = CreateTextSpinner(setting.NAME, setting.VALUES, setting.TOOLTIP)
			self[widget_name].OnChanged = function(_, data)
				self.owner.working[setting.ID] = data
				self.owner:UpdateMenu()
			end
			self[widget_name].type = setting.TYPE
			self[widget_name].setting_id = setting.ID
		end
		
		if setting.TYPE == MYI.SETTING_TYPES.LIST then -- List mod setting gets a button created to open itself
			widget_name = string.lower(setting.ID).."_btn"
			self[widget_name] = CreateSettingButton(setting.NAME, function() OpenList(self.owner, setting.NAME, deepcopy(self.loaded_settings[setting.ID])) end, setting.TOOLTIP)
			self[widget_name].tooltip_text = setting.TOOLTIP
		end

		if widget_name ~= "" then
			self[widget_name]:Enable()
			self[widget_name].type = setting.TYPE
			self[widget_name].setting_id = setting.ID
			table.insert(setting.COLUMN == 1 and self.left_column or self.right_column, self[widget_name])
		else
			MYI.modprint(MYI.WARN, "Potentially invalid mod setting type detected! Check your environment file!", "Setting name - "..name, "Setting type - "..setting.TYPE)
		end
	end
	
	self.grid:UseNaturalLayout()
	self.grid:InitSize(2, math.max(#self.left_column, #self.right_column), 440, 40)

	local settings_tooltip = MakeTooltip(self)
	local settings_tooltip_divider = self:AddChild(Image("images/global_redux.xml", "item_divider.tex"))
	settings_tooltip_divider:SetPosition(90, -225)

	for k, v in ipairs(self.left_column) do
		self.grid:AddItem(v.parent, 1, k)
		AddSettingTooltip(v.parent, v.type, settings_tooltip, settings_tooltip_divider)
	end

	for k, v in ipairs(self.right_column) do
		self.grid:AddItem(v.parent, 2, k)
		AddSettingTooltip(v.parent, v.type, settings_tooltip, settings_tooltip_divider)
	end

    self.focus_forward = self.grid
end)

return MYISettingsTab