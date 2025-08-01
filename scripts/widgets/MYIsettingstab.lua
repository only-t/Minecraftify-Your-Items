local Widget = require("widgets/widget")
local Grid = require("widgets/grid")
local Text = require("widgets/text")
local Image = require("widgets/image")
local PopupDialogScreen = require "screens/redux/popupdialog"
local MYIEditListScreen = require("screens/MYIeditlistscreen")

local TEMPLATES = require("widgets/redux/templates")

local label_width = 200
local spinner_width = 220
local spinner_height = 36
local narrow_field_nudge = -50
local space_between = 5

local function OpenList(optionsscreen, list_title, data, onapply)
	local editlist = MYIEditListScreen(optionsscreen, list_title, data, onapply)
	TheFrontEnd:PushScreen(editlist)
end

local function AddListItemBackground(w)
	local total_width = label_width + spinner_width + space_between
	w.bg = w:AddChild(TEMPLATES.ListItemBackground(total_width + 15, spinner_height + 5))
	w.bg:SetPosition(-40, 0)
	w.bg:MoveToBack()
end

local function CreateNumericSpinner(labeltext, values, tooltip_text)
	local spinnerdata = {  }
	for i = values[1], values[2], values[3] do
		table.insert(spinnerdata, { text = tostring(i), data = i })
	end

	local w = TEMPLATES.LabelSpinner(labeltext, spinnerdata, label_width, spinner_width, spinner_height, space_between, nil, nil, narrow_field_nudge, nil, nil, tooltip_text)
	AddListItemBackground(w)
	return w.spinner
end

local function CreateTextSpinner(labeltext, spinnerdata, tooltip_text)
	local w = TEMPLATES.LabelSpinner(labeltext, spinnerdata, label_width, spinner_width, spinner_height, space_between, nil, nil, narrow_field_nudge, nil, nil, tooltip_text)
	AddListItemBackground(w)

	return w.spinner
end

local function CreateKeySelection(labeltext, btn_action, tooltip_text)
    local font = CHATFONT
    local font_size = 25
    local offset = narrow_field_nudge

    local total_width = label_width + spinner_width + space_between
    local w = Widget("labelbindingbtn")
    w.label = w:AddChild(Text(font, font_size, labeltext))
    w.label:SetPosition((-total_width / 2) + (label_width / 2) + offset, 0)
    w.label:SetRegionSize(label_width, spinner_height)
    w.label:SetHAlign(ANCHOR_RIGHT)
    w.label:SetColour(UICOLOURS.GOLD)

	w.binding_btn = w:AddChild(ImageButton("images/global_redux.xml", "blank.tex", "spinner_focus.tex"))
	w.binding_btn:ForceImageSize(spinner_width, spinner_height)
	w.binding_btn:SetTextColour(UICOLOURS.GOLD_CLICKABLE)
	w.binding_btn:SetFont(CHATFONT)
	w.binding_btn:SetTextSize(30)
	w.binding_btn:SetPosition((total_width / 2) - (spinner_width / 2) + offset, 0)
	w.binding_btn:SetOnClick(btn_action)
	w.binding_btn:SetTextFocusColour(UICOLOURS.GOLD_FOCUS)

	w.binding_btn:SetDisabledFont(CHATFONT)
	w.binding_btn:SetText("")

    w.focus_forward = w.binding_btn

    w.tooltip_text = tooltip_text

	AddListItemBackground(w)

	return w.binding_btn
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

	if type == MYI.SETTING_TYPES.SPINNER or type == MYI.SETTING_TYPES.NUM_SPINNER then
		widget.spinner.ongainfocusfn = ongainfocus
		widget.spinner.onlosefocusfn = onlosefocus
	elseif type == MYI.SETTING_TYPES.LIST then
		widget.btn.ongainfocus = ongainfocus
		widget.btn.onlosefocus = onlosefocus
	elseif type == MYI.SETTING_TYPES.KEY_SELECT then
		widget.binding_btn.ongainfocusfn = ongainfocus
		widget.binding_btn.onlosefocusfn = onlosefocus
	end
end

local MYISettingsTab = Class(Widget, function(self, owner)
    self.owner = owner
    Widget._ctor(self, "MYISettingsTab")

    self.grid = self:AddChild(Grid())
    self.grid:SetPosition(-90, 184, 0)

	self.left_column = {  }
	self.right_column = {  }
	for name, setting in pairs(MYI.MOD_SETTINGS.SETTINGS) do
		local widget_name = ""
		if setting.TYPE == MYI.SETTING_TYPES.SPINNER then
			widget_name = string.lower(setting.ID).."_spinner"
			self[widget_name] = CreateTextSpinner(setting.SPINNER_TITLE, setting.VALUES, setting.TOOLTIP)
			self[widget_name].OnChanged = function(_, data)
				self.owner.working[setting.ID] = data
				self.owner:UpdateMenu()
			end
		end
		
		if setting.TYPE == MYI.SETTING_TYPES.NUM_SPINNER then
			widget_name = string.lower(setting.ID).."_spinner"
			self[widget_name] = CreateNumericSpinner(setting.SPINNER_TITLE, setting.VALUES, setting.TOOLTIP)
			self[widget_name].OnChanged = function(_, data)
				self.owner.working[setting.ID] = data
				self.owner:UpdateMenu()
			end
			self[widget_name].min = setting.VALUES[1]
			self[widget_name].step = setting.VALUES[3]
		end
		
		if setting.TYPE == MYI.SETTING_TYPES.KEY_SELECT then
			widget_name = string.lower(setting.ID).."_key_selection"
			self[widget_name] = CreateKeySelection(setting.SPINNER_TITLE,
			function()
				local key_str = STRINGS.UI.CONTROLSSCREEN.INPUTS[1][setting.DEFAULT]
				local subtext = STRINGS.UI.CONTROLSSCREEN.CONTROL_SELECT.."\n\n"..string.format(STRINGS.UI.CONTROLSSCREEN.DEFAULT_CONTROL_TEXT, key_str)
				local popup = PopupDialogScreen(setting.SPINNER_TITLE, subtext, {  })
				popup.dialog.body:SetPosition(0, 0)
				popup.OnControl = function(_, control, down)
					if control == CONTROL_CANCEL and not down then
						TheFrontEnd:PopScreen()
						return false
					end
				end
				popup.OnRawKey = function(_, key, down)
					if key ~= KEY_ESCAPE and down then
						self[widget_name]:OnChanged(key)
						TheFrontEnd:PopScreen()
					end

					return false
				end

				TheFrontEnd:PushScreen(popup)
			end,
			setting.TOOLTIP)
			self[widget_name].OnChanged = function(binding_btn, data)
				binding_btn:SetText(STRINGS.UI.CONTROLSSCREEN.INPUTS[1][data])
				self.owner.working[setting.ID] = data
				self.owner:UpdateMenu()
			end
		end
		
		if setting.TYPE == MYI.SETTING_TYPES.LIST then -- List mod setting gets a button created to open itself
			widget_name = string.lower(setting.ID).."_btn"
			self[widget_name] = CreateSettingButton(setting.SPINNER_TITLE,
				function()
					OpenList(self.owner, setting.SPINNER_TITLE, deepcopy(self.owner.working[setting.ID]), function(data)
						self.owner.working[setting.ID] = data
						if #self.owner.working[setting.ID] ~= #self.owner.options[setting.ID] then
							self.owner:MakeDirty()
							return
						end

						self.owner:UpdateMenu()
					end)
				end,
				setting.TOOLTIP
			)
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