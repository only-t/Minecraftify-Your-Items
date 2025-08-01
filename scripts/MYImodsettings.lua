-- [[ Define default values ]]
local loaded_settings = {  }
_G.MYI.ModGetPersistentData(_G.MYI.MOD_SETTINGS.FILENAME, function(_, data)
    if data == "" then -- Run only when the settings file is missing
        for _, setting in pairs(_G.MYI.MOD_SETTINGS.SETTINGS) do
            if loaded_settings[setting.ID] == nil then
                loaded_settings[setting.ID] = setting.DEFAULT
            end
        end

        _G.MYI.ModSetPersistentData(_G.MYI.MOD_SETTINGS.FILENAME, _G.json.encode(loaded_settings))
    else -- Otherwise just check for missing data
        loaded_settings = _G.json.decode(data)

        local was_updated = false
        for _, setting in pairs(_G.MYI.MOD_SETTINGS.SETTINGS) do
            if loaded_settings[setting.ID] == nil then
                loaded_settings[setting.ID] = setting.DEFAULT
                was_updated = true
            end
        end

        if was_updated then
            _G.MYI.ModSetPersistentData(_G.MYI.MOD_SETTINGS.FILENAME, _G.json.encode(loaded_settings))
        end
    end
end)

_G.MYI.CURRENT_SETTINGS = loaded_settings

-- [[ Add mod settings to the Game Options screen ]]
local MYISettingsTab = require("widgets/MYIsettingstab")
local OptionsScreen = require("screens/redux/optionsscreen")
local old_OptionsScreen_BuildMenu = OptionsScreen._BuildMenu
OptionsScreen._BuildMenu = function(self, subscreener, ...)
    subscreener.sub_screens[_G.MYI.MOD_CODE] = self.panel_root:AddChild(MYISettingsTab(self))
    local menu = old_OptionsScreen_BuildMenu(self, subscreener, ...)

	local myi_button = subscreener:MenuButton(_G.MYI.MOD_SETTINGS.TAB_NAME, _G.MYI.MOD_CODE, _G.MYI.MOD_SETTINGS.TOOLTIP, self.tooltip)
    menu:AddCustomItem(myi_button)
    local pos = _G.Vector3(0, 0, 0)
    pos.y = pos.y + menu.offset * (#menu.items - 1)
    myi_button:SetPosition(pos)
    
    return menu
end

local old_OptionsScreen_DoInit = OptionsScreen.DoInit
OptionsScreen.DoInit = function(self, ...)
    for id, setting in pairs(loaded_settings) do
        self.options[id] = setting
        self.working[id] = setting
    end

    old_OptionsScreen_DoInit(self, ...)
end

local old_OptionsScreen_Apply = OptionsScreen.Apply
OptionsScreen.Apply = function(self, ...)
    for _, setting in pairs(_G.MYI.MOD_SETTINGS.SETTINGS) do
        loaded_settings[setting.ID] = self.working[setting.ID]
    end

    _G.MYI.ModSetPersistentData(_G.MYI.MOD_SETTINGS.FILENAME, loaded_settings, function()
        _G.MYI.CURRENT_SETTINGS = loaded_settings
        _G.MYI.UpdateAffectedEntities()
    end)

    old_OptionsScreen_Apply(self, ...)
end

local function EnabledOptionsIndex(enabled)
    return enabled and 2 or 1
end

local function NumSpinnerOptionsIndex(val, min, step)
    return 1 + (val - min) / step
end

local old_OptionsScreen_InitializeSpinners = OptionsScreen.InitializeSpinners
OptionsScreen.InitializeSpinners = function(self, ...)
    for _, w in pairs(self.subscreener.sub_screens[_G.MYI.MOD_CODE].left_column) do
        if w.type == _G.MYI.SETTING_TYPES.SPINNER then
            w:SetSelectedIndex(EnabledOptionsIndex(self.working[w.setting_id]))
        end

        if w.type == _G.LFC.SETTING_TYPES.NUM_SPINNER then
            w:SetSelectedIndex(NumSpinnerOptionsIndex(self.working[w.setting_id], w.min, w.step))
        end

        if w.type == _G.LFC.SETTING_TYPES.KEY_SELECT then
            w:SetText(self.working[w.setting_id] ~= nil and _G.STRINGS.UI.CONTROLSSCREEN.INPUTS[1][self.working[w.setting_id]] or "")
        end
    end

    for _, w in pairs(self.subscreener.sub_screens[_G.MYI.MOD_CODE].right_column) do
        if w.type == _G.MYI.SETTING_TYPES.SPINNER then
            w:SetSelectedIndex(EnabledOptionsIndex(self.working[w.setting_id]))
        end

        if w.type == _G.LFC.SETTING_TYPES.NUM_SPINNER then
            w:SetSelectedIndex(NumSpinnerOptionsIndex(self.working[w.setting_id], w.min, w.step))
        end

        if w.type == _G.LFC.SETTING_TYPES.KEY_SELECT then
            w:SetText(self.working[w.setting_id] ~= nil and _G.STRINGS.UI.CONTROLSSCREEN.INPUTS[1][self.working[w.setting_id]] or "")
        end
    end

    old_OptionsScreen_InitializeSpinners(self, ...)
end