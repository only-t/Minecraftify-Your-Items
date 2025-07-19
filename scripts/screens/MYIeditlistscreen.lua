require "util"

local Widget = require "widgets/widget"
local Screen = require "widgets/screen"
local Text = require "widgets/text"
local Image = require "widgets/image"
local PopupDialogScreen = require "screens/redux/popupdialog"

local TEMPLATES = require "widgets/redux/templates"

local del_btn_width = 70
local del_btn_height = 40
local row_width, row_height = 585, 40

local function AddNewRow()
    
end

local function DeleteRow()
    
end

local MYIEditListScreen = Class(Screen, function(self, owner, list_title, data)
	Screen._ctor(self, "MYIEditListScreen")

    self.owner = owner

    self.black = self:AddChild(TEMPLATES.BackgroundTint())
    self.root = self:AddChild(TEMPLATES.ScreenRoot())

    local btns = {
        { text = STRINGS.UI.OPTIONS.APPLY,  cb = function() self:Apply()  end },
        { text = STRINGS.UI.OPTIONS.CANCEL, cb = function() self:Cancel() end }
    }

    self.dialog = self.root:AddChild(TEMPLATES.RectangleWindow(row_width + 20, 580, nil, btns))

    self.header = self.dialog:AddChild(Widget("header"))
    self.header:SetPosition(0, 270)

    self.unsaved_icon = self.dialog:AddChild(Image("images/button_icons2.xml", "workshop_filter.tex"))
    self.unsaved_icon:SetPosition((row_width + 20) / 2, -290 + 35)
    self.unsaved_icon:ScaleToSize(50, 50)
    self.unsaved_icon:Hide()

    local title_max_w = 420
    local title_max_chars = 70
    local title = self.header:AddChild(Text(HEADERFONT, 28, ""))
    title:SetColour(UICOLOURS.GOLD_SELECTED)
	title:SetTruncatedString(list_title, title_max_w, title_max_chars, true)

    self.listpanel = self.dialog:InsertWidget(Widget("listpanel"))
    self.listpanel:SetPosition(0, 0)

	self.dirty = false

    local function OnTextInputted(w)
        MYI.modprint(MYI.PRINT, "Editing data #"..w.row_data.id, "str - "..w.editableline.textbox:GetString())
    end

    local function ScrollWidgetsCtor(context, idx)
        local widget = Widget("row_"..idx)
        widget.bg = widget:AddChild(Image("images/frontend_redux.xml", "serverlist_listitem_normal.tex"))
        widget.bg:ScaleToSize(row_width + 20, row_height)
        
        widget.editableline = widget:AddChild(TEMPLATES.StandardSingleLineTextEntry("", row_width - del_btn_width, row_height, CHATFONT, 28, ""))
        widget.editableline:SetPosition(-del_btn_width / 2, 0)
        widget.editableline.textbox.OnTextInputted = function() OnTextInputted(widget) end

        widget.addnewbtn = widget:AddChild(TEMPLATES.StandardButton(AddNewRow, "Add New", { (row_width - del_btn_width) / 2, row_height }))
        widget.addnewbtn:SetPosition(-del_btn_width / 2, 0)

        widget.delbtn = widget:AddChild(TEMPLATES.StandardButton(DeleteRow, "Delete", { del_btn_width, del_btn_height }))
        widget.delbtn:SetPosition((row_width - del_btn_width) / 2, 0)

        return widget
	end

    local function ApplyDataToWidget(context, widget, data, idx)
		if data then
            widget.row_data = data
            widget.bg:Show()

            if data == "addnewbtn" then
                widget.addnewbtn:Show()
                widget.editableline:Hide()
                widget.delbtn:Hide()
            else
                widget.addnewbtn:Hide()
                widget.editableline:Show()
                widget.editableline.textbox:SetString(data.data)
                widget.delbtn:Show()
            end
        else
            widget.bg:Hide()
            widget.editableline:Hide()
            widget.addnewbtn:Hide()
            widget.delbtn:Hide()
		end
	end

    self.data = data or {  }
    table.insert(self.data, "addnewbtn") -- After the real data rows insert a special row for generating a "Add Tag" button

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

	if TheInput:ControllerAttached() then
        self.dialog.actions:Hide()
	end

	self.default_focus = self.scroll_list
end)

function MYIEditListScreen:Apply()
	if self:IsDirty() then
		-- KnownModIndex:SaveConfigurationOptions(function()
		-- 	self:MakeDirty(false)
		--     TheFrontEnd:PopScreen()
		-- end, self.modname, settings, self.client_config)
	else
		-- self:MakeDirty(false)
	    -- TheFrontEnd:PopScreen()
	end
	
	TheFrontEnd:PopScreen()
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

function MYIEditListScreen:Cancel()
	if self:IsDirty() and not (self.started_default and self:IsDefaultSettings()) then
		-- self:ConfirmRevert(function()
		-- 	self:MakeDirty(false)
		-- 	TheFrontEnd:PopScreen()
		--     TheFrontEnd:PopScreen()
		-- end)
	else
		-- self:MakeDirty(false)
	    -- TheFrontEnd:PopScreen()
	end
	
	TheFrontEnd:PopScreen()
end

function MYIEditListScreen:MakeDirty(dirty)
	if dirty ~= nil then
		self.dirty = dirty
	else
		self.dirty = true
	end
end

function MYIEditListScreen:IsDirty()
	return self.dirty
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
