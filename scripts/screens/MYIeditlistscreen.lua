require "util"

local Widget = require "widgets/widget"
local Screen = require "widgets/screen"
local Text = require "widgets/text"
local Image = require "widgets/image"
local PopupDialogScreen = require "screens/redux/popupdialog"

local TEMPLATES = require "widgets/redux/templates"

local del_btn_width = 70
local del_btn_height = 40
local add_btn_width = 100
local add_btn_height = 50
local row_width, row_height = 585, 40

local function MakeUnsavedChangesWarningTooltip()
	local w = Text(CHATFONT, 25, "You have unsaved changes!")
	w:SetPosition(10, -580 / 2 + 15)
	w:SetHAlign(ANCHOR_RIGHT)
	w:SetVAlign(ANCHOR_TOP)
	w:SetRegionSize(500, 80)
	w:EnableWordWrap(true)

    return w
end

local function CheckIsDirty(self)
    if #self.data ~= #self.edited_data then
        return true
    end

    for i, data in ipairs(self.edited_data) do
        if self.data[i].data ~= data.data then
            return true
        end
    end

    return false
end

local MYIEditListScreen = Class(Screen, function(self, owner, list_title, data, onapply)
	Screen._ctor(self, "MYIEditListScreen")

    self.owner = owner
    self.onapply = onapply

    self.black = self:AddChild(TEMPLATES.BackgroundTint())
    self.root = self:AddChild(TEMPLATES.ScreenRoot())

    local btns = {
        { text = "Save Changes",            cb = function() self:Apply()  end },
        { text = STRINGS.UI.OPTIONS.CANCEL, cb = function() self:Cancel() end }
    }

    self.dialog = self.root:AddChild(TEMPLATES.RectangleWindow(row_width + 20, 580, nil, btns))

    self.header = self.dialog:AddChild(Widget("header"))
    self.header:SetPosition(0, 270)

    local title_max_w = 420
    local title_max_chars = 70
    local title = self.header:AddChild(Text(HEADERFONT, 28, ""))
    title:SetColour(UICOLOURS.GOLD_SELECTED)
	title:SetTruncatedString(list_title, title_max_w, title_max_chars, true)

    self.listpanel = self.dialog:InsertWidget(Widget("listpanel"))
    self.listpanel:SetPosition(0, 0)

    self.rows = {  }

	self.dirty = false

    local function OnTextInputted(w)
        self.edited_data[w.row_data.id].data = w.editline.textbox:GetString()

        if CheckIsDirty(self) then
            self:MakeDirty(true)
        else
            self:MakeDirty(false)
        end
    end

    local function ScrollWidgetsCtor(context, idx)
        local widget = Widget("row_"..idx)
        widget.bg = widget:AddChild(Image("images/frontend_redux.xml", "serverlist_listitem_normal.tex"))
        widget.bg:ScaleToSize(row_width + 20, row_height)
		widget.bg:SetClickable(false)
        
        widget.editline = widget:AddChild(TEMPLATES.StandardSingleLineTextEntry("", row_width - del_btn_width, row_height, CHATFONT, 28, ""))
        widget.editline:SetPosition(-del_btn_width / 2, 0)
        widget.editline:SetOnGainFocus( function() widget.editline.textbox:OnGainFocus() end )
        widget.editline:SetOnLoseFocus( function() widget.editline.textbox:OnLoseFocus() end )

        widget.editline.textbox:SetTextLengthLimit(50)
        widget.editline.textbox:SetForceEdit(true)
        widget.editline.textbox:EnableWordWrap(false)
        widget.editline.textbox:EnableScrollEditWindow(true)
        widget.editline.textbox:SetHelpTextEdit("")
        widget.editline.textbox.GetHelpText = function() return widget.editline:GetHelpText() end
        widget.editline.textbox.OnTextInputted = function() OnTextInputted(widget) end

        widget.editline.focus_forward = widget.editline.textbox

        widget.delbtn = widget:AddChild(TEMPLATES.StandardButton(function() self:DeleteRow(widget.row_data.id) end, "Delete", { del_btn_width, del_btn_height }))
        widget.delbtn:SetPosition((row_width - del_btn_width) / 2, 0)

        widget.editline:SetFocusChangeDir(MOVE_RIGHT, widget.delbtn)
        widget.delbtn:SetFocusChangeDir(MOVE_LEFT, widget.editline)

        widget.focus_forward = widget.editline

        widget.editline.ongainfocusfn = function() self.scroll_list:OnWidgetFocus(widget) end
        widget.delbtn.ongainfocusfn = function() self.scroll_list:OnWidgetFocus(widget) end

        table.insert(self.rows, widget)

        return widget
	end

    local function ApplyDataToWidget(context, widget, data, idx)
		if data then
            widget.row_data = data
            widget.bg:Show()
            widget.editline:Show()
            widget.editline.textbox:SetString(data.data)
            widget.delbtn:Show()

			widget:Enable()
        else
            widget.bg:Hide()
            widget.editline:Hide()
            widget.delbtn:Hide()

			widget:Disable()
		end
	end

    self.data = data or {  }
    self.edited_data = deepcopy(self.data)

    self.scroll_list = self.listpanel:AddChild(TEMPLATES.ScrollingGrid(
        self.data,
        {
            scroll_context = {  },
            widget_width  = row_width,
            widget_height = row_height,
			force_peek = true,
            num_visible_rows = 10,
            num_columns = 1,
            item_ctor_fn = ScrollWidgetsCtor,
            apply_fn = ApplyDataToWidget,
            scrollbar_offset = 20,
            scrollbar_height_offset = -60
        }
    ))
    self.scroll_list:SetPosition(0, 0)

	self.horizontal_line1 = self.scroll_list:AddChild(Image("images/global_redux.xml", "item_divider.tex"))
    self.horizontal_line1:SetPosition(0, self.scroll_list.visible_rows / 2 * row_height + 8)
    self.horizontal_line1:SetSize(row_width + 30, 5)

	self.horizontal_line2 = self.scroll_list:AddChild(Image("images/global_redux.xml", "item_divider.tex"))
    self.horizontal_line2:SetPosition(0, -(self.scroll_list.visible_rows / 2 * row_height + 8))
    self.horizontal_line2:SetSize(row_width + 30, 5)

    self.unsaved_icon = self.dialog:AddChild(Image("images/button_icons2.xml", "workshop_filter.tex"))
    self.unsaved_icon:SetPosition(row_width / 2, -(self.scroll_list.visible_rows / 2 * row_height + add_btn_height))
    self.unsaved_icon:ScaleToSize(50, 50)
    self.unsaved_icon.OnGainFocus = function(self, ...)
        self._base.OnGainFocus(self, ...)
        if self:IsVisible() then
            self.tooltip:Show()
        end
    end
    self.unsaved_icon.OnLoseFocus = function(self, ...)
        self._base.OnLoseFocus(self, ...)

        if not TheInput:ControllerAttached() then
            self.tooltip:Hide()
        end
    end

    self.unsaved_icon.tooltip = self.dialog:AddChild(MakeUnsavedChangesWarningTooltip())
    self.unsaved_icon:Hide()
    self.unsaved_icon.tooltip:Hide()

    self.addnewrowbtn = self.dialog:AddChild(TEMPLATES.StandardButton(function() self:AddNewRow() end, "Add New", { add_btn_width, add_btn_height }))
    self.addnewrowbtn:SetPosition((-row_width + add_btn_width) / 2, -(self.scroll_list.visible_rows / 2 * row_height + add_btn_height))

    self:_DoFocusHookups()
end)

function MYIEditListScreen:_DoFocusHookups()
    self.scroll_list:ClearFocusDirs()
    self.addnewrowbtn:ClearFocusDirs()

    if self.scroll_list.items == nil or #self.scroll_list.items <= 0 then
        self.default_focus = self.addnewrowbtn
        self.addnewrowbtn:SetFocus()
    else
        self.default_focus = self.scroll_list
        self.scroll_list:SetFocusChangeDir(MOVE_DOWN, self.addnewrowbtn)
        self.addnewrowbtn:SetFocusChangeDir(MOVE_UP, self.scroll_list.widgets_to_update[math.min(#self.edited_data, #self.scroll_list.widgets_to_update - 1)])
    end
end

function MYIEditListScreen:GetHelpText()
	local t = {  }
	local controller_id = TheInput:GetControllerID()

	table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_CANCEL) .. " " .. STRINGS.UI.HELP.BACK)
    
	if self:IsDirty() then
		table.insert(t, TheInput:GetLocalizedControl(controller_id, CONTROL_MENU_START) .. " " .. STRINGS.UI.HELP.APPLY)
	end

	return table.concat(t, "  ")
end

function MYIEditListScreen:AddNewRow()
    table.insert(self.edited_data, { id = #self.edited_data + 1, data = "" })
    self:UpdateList()
end

function MYIEditListScreen:DeleteRow(row_id)
    table.remove(self.edited_data, row_id)

    for i = row_id, #self.edited_data, 1 do -- Adjust the row ids
        self.edited_data[i].id = self.edited_data[i].id - 1
    end

    self:UpdateList()
end

function MYIEditListScreen:UpdateList()
    if CheckIsDirty(self) then
        self:MakeDirty(true)
    else
        self:MakeDirty(false)
    end

    if #self.edited_data <= 0 then
        self.scroll_list.widgets_to_update[1]:SetFocus()
    end

    self.scroll_list:SetItemsData(self.edited_data)

    self:_DoFocusHookups()
end

function MYIEditListScreen:MakeDirty(dirty)
	if dirty ~= nil then
		self.dirty = dirty
	else
		self.dirty = true
	end

    if self.dirty then
        self.unsaved_icon:Show()

        if self.is_controller_attached then
            self.unsaved_icon.tooltip:Show()
        end
    else
        self.unsaved_icon:Hide()

        if self.is_controller_attached then
            self.unsaved_icon.tooltip:Hide()
        end
    end
end

function MYIEditListScreen:IsDirty()
	return self.dirty
end

function MYIEditListScreen:Apply()
	if self:IsDirty() then
        self.data = self.edited_data
        if self.onapply then
            self.onapply(self.data)
        end
        TheFrontEnd:PopScreen()
	else
		self:MakeDirty(false)
	    TheFrontEnd:PopScreen()
	end
end

function MYIEditListScreen:Cancel()
	if self:IsDirty() then
		self:ConfirmRevert(function()
			self:MakeDirty(false)
			TheFrontEnd:PopScreen()
		    TheFrontEnd:PopScreen()
		end)
	else
		self:MakeDirty(false)
	    TheFrontEnd:PopScreen()
	end
end

function MYIEditListScreen:ConfirmRevert(callback)
	TheFrontEnd:PushScreen(
		PopupDialogScreen(STRINGS.UI.OPTIONS.BACKTITLE, STRINGS.UI.OPTIONS.BACKBODY,
            {
                {
                    text = STRINGS.UI.OPTIONS.YES,
                    cb = callback or function() TheFrontEnd:PopScreen() end
                },
                {
                    text = STRINGS.UI.OPTIONS.NO,
                    cb = function()
                        TheFrontEnd:PopScreen()
                    end
                }
            }
		)
	)
end

function MYIEditListScreen:OnControllerChanged(attached)
	if attached then
        self.dialog.actions:Hide()

        if self.dirty then
            self.unsaved_icon.tooltip:Show()
        end
    else
        self.dialog.actions:Show()
        self.unsaved_icon.tooltip:Hide()
	end
end

function MYIEditListScreen:OnControl(control, down)
    if MYIEditListScreen._base.OnControl(self, control, down) then return true end

    if not down then
	    if control == CONTROL_CANCEL then
			self:Cancel()
            return true
	    elseif control == CONTROL_MENU_START and TheInput:ControllerAttached() and not TheFrontEnd.tracking_mouse then
            self:Apply()
            return true
        end
	end
end

function MYIEditListScreen:OnUpdate()
    local is_attached = TheInput:ControllerAttached()

    if self.is_controller_attached ~= is_attached then
        self.is_controller_attached = is_attached
        self:OnControllerChanged(is_attached)
    end
end

return MYIEditListScreen
