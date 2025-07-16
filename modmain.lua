env._G = GLOBAL._G
GLOBAL.setfenv(1, env)

Assets = {
    Asset("SHADER", "shaders/minecraftify_ent.ksh")
}

PrefabFiles = {
    "mc_item_shadows"
}

modimport("scripts/MYIenv")

local function TagsCheck(inst)
    return not inst:HasTag("flying") and
           not inst:HasTag("heavy") and
           not inst:HasTag("structure") and
           not inst:HasTag("furnituredecor")
end

AddPrefabPostInitAny(function(inst)
    if not _G.TheNet:IsDedicated() and inst.AnimState and TagsCheck(inst) then
        inst:DoTaskInTime(0, function() -- Wait 1 frame for the replica components to get created on the client
            if inst.replica.inventoryitem and not inst.replica.combat then
                inst:AddComponent("MYImanager")
            end
        end)
    end
end)

AddPlayerPostInit(function(inst)
    if not _G.TheNet:IsDedicated() then
        inst.mc_item_shadows = _G.SpawnPrefab("mc_item_shadows")
        inst.mc_item_shadows.entity:SetParent(inst.entity)
        inst.mc_items = {  } -- Holds information about existing MC items to generate shadows under them
    end
end)

local MYISettingsTab = require("widgets/MYIsettingstab")
local OptionsScreen = require("screens/redux/optionsscreen")
local old_OptionsScreen_BuildMenu = OptionsScreen._BuildMenu
OptionsScreen._BuildMenu = function(self, subscreener, ...)
    subscreener.sub_screens["MYI"] = self.panel_root:AddChild(MYISettingsTab(self))
    local menu = old_OptionsScreen_BuildMenu(self, subscreener, ...)

	local myi_button = subscreener:MenuButton(_G.MYI.SETTINGS.NAME, "MYI", _G.MYI.SETTINGS.TOOLTIP, self.tooltip)
    menu:AddCustomItem(myi_button)
    local pos = _G.Vector3(0, 0, 0)
    pos.y = pos.y + menu.offset * (#menu.items - 1)
    myi_button:SetPosition(pos)
    
    return menu
end

local function EnabledOptionsIndex(enabled)
    return enabled and 2 or 1
end

if _G.Profile:GetValue(_G.MYI.SETTINGS.OPTIONS.WORLD_Y.OPTIONS_STR) == nil then
    _G.Profile:SetValue(_G.MYI.SETTINGS.OPTIONS.WORLD_Y.OPTIONS_STR, _G.MYI.SETTINGS.OPTIONS.WORLD_Y.DEFAULT)
end

if _G.Profile:GetValue(_G.MYI.SETTINGS.OPTIONS.SHADOWS.OPTIONS_STR) == nil then
    _G.Profile:SetValue(_G.MYI.SETTINGS.OPTIONS.SHADOWS.OPTIONS_STR, _G.MYI.SETTINGS.OPTIONS.SHADOWS.DEFAULT)
end

local old_OptionsScreen_DoInit = OptionsScreen.DoInit
OptionsScreen.DoInit = function(self, ...)
    self.options[_G.MYI.SETTINGS.OPTIONS.WORLD_Y.OPTIONS_STR] = _G.Profile:GetValue(_G.MYI.SETTINGS.OPTIONS.WORLD_Y.OPTIONS_STR)
    self.working[_G.MYI.SETTINGS.OPTIONS.WORLD_Y.OPTIONS_STR] = _G.Profile:GetValue(_G.MYI.SETTINGS.OPTIONS.WORLD_Y.OPTIONS_STR)

    self.options[_G.MYI.SETTINGS.OPTIONS.SHADOWS.OPTIONS_STR] = _G.Profile:GetValue(_G.MYI.SETTINGS.OPTIONS.SHADOWS.OPTIONS_STR)
    self.working[_G.MYI.SETTINGS.OPTIONS.SHADOWS.OPTIONS_STR] = _G.Profile:GetValue(_G.MYI.SETTINGS.OPTIONS.SHADOWS.OPTIONS_STR)

    old_OptionsScreen_DoInit(self, ...)
end

local old_OptionsScreen_Apply = OptionsScreen.Apply
OptionsScreen.Apply = function(self, ...)
    _G.Profile:SetValue(_G.MYI.SETTINGS.OPTIONS.WORLD_Y.OPTIONS_STR, self.working[_G.MYI.SETTINGS.OPTIONS.WORLD_Y.OPTIONS_STR])
    _G.Profile:SetValue(_G.MYI.SETTINGS.OPTIONS.SHADOWS.OPTIONS_STR, self.working[_G.MYI.SETTINGS.OPTIONS.SHADOWS.OPTIONS_STR])

    if _G.ThePlayer then -- Player exists == we're changing settings during playtime
        _G.ThePlayer.mc_items = {  } -- Reset the mc item tracker
    end

    old_OptionsScreen_Apply(self, ...)
end

local old_OptionsScreen_InitializeSpinners = OptionsScreen.InitializeSpinners
OptionsScreen.InitializeSpinners = function(self, ...)
    self.subscreener.sub_screens["MYI"].worldYSpinner:SetSelectedIndex(EnabledOptionsIndex(self.working[_G.MYI.SETTINGS.OPTIONS.WORLD_Y.OPTIONS_STR]))
    self.subscreener.sub_screens["MYI"].shadowsSpinner:SetSelectedIndex(EnabledOptionsIndex(self.working[_G.MYI.SETTINGS.OPTIONS.SHADOWS.OPTIONS_STR]))

    old_OptionsScreen_InitializeSpinners(self, ...)
end