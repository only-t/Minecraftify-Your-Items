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
        
        widget.editline = widget:AddChild(TEMPLATES.StandardSingleLineTextEntry("", row_width - del_btn_width, row_height, CHATFONT, 28, ""))
        widget.editline:SetPosition(-del_btn_width / 2, 0)
        widget.editline.textbox.OnTextInputted = function() OnTextInputted(widget) end

        widget.delbtn = widget:AddChild(TEMPLATES.StandardButton(function() self:DeleteRow(widget.row_data.id) end, "Delete", { del_btn_width, del_btn_height }))
        widget.delbtn:SetPosition((row_width - del_btn_width) / 2, 0)

        return widget
	end

    local function ApplyDataToWidget(context, widget, data, idx)
		if data then
            widget.row_data = data
            widget.bg:Show()
            widget.editline:Show()
            widget.editline.textbox:SetString(data.data)
            widget.delbtn:Show()
        else
            widget.bg:Hide()
            widget.editline:Hide()
            widget.delbtn:Hide()
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
        if TheInput:ControllerAttached() then
            return
        end

        if self:IsVisible() then
            self.tooltip:Show()
        end
    end
    self.unsaved_icon.OnLoseFocus = function(self, ...)
        self._base.OnLoseFocus(self, ...)

        if TheInput:ControllerAttached() then
            return
        end

        self.tooltip:Hide()
    end

    self.unsaved_icon.tooltip = self.dialog:AddChild(MakeUnsavedChangesWarningTooltip())
    self.unsaved_icon:Hide()
    self.unsaved_icon.tooltip:Hide()

    self.addnewrowbtn = self.scroll_list:AddChild(TEMPLATES.StandardButton(function() self:AddNewRow() end, "Add New", { add_btn_width, add_btn_height }))
    self.addnewrowbtn:SetPosition((-row_width + add_btn_width) / 2, -(self.scroll_list.visible_rows / 2 * row_height + add_btn_height))

	if TheInput:ControllerAttached() then
        self.dialog.actions:Hide()
	end

	self.default_focus = self.scroll_list
end)

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

    self.scroll_list:SetItemsData(self.edited_data)
end

function MYIEditListScreen:MakeDirty(dirty)
	if dirty ~= nil then
		self.dirty = dirty
	else
		self.dirty = true
	end

    if self.dirty then
        self.unsaved_icon:Show()

        if TheInput:ControllerAttached() then
            self.unsaved_icon.tooltip:Show()
        end
    else
        self.unsaved_icon:Hide()

        if TheInput:ControllerAttached() then
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

return MYIEditListScreen
