-- Defined this way to make reusing for different mods easier
local MOD_CODE = "MYI"
local MOD_NAME = "Minecraftify Your Items!"

-- Good to define your entire environment in a special table.
-- Eliminates any potential mod incompatability with mods that use the same global names.
-- Unless they define a global of the same name as `MOD_CODE` i guess...
_G[MOD_CODE] = {
    MOD_CODE = MOD_CODE,
    MOD_NAME = MOD_NAME
}

---
--- Created specifically to print lines with a clear source, that being, the mod.
--- Functionally, it's a simple print with a prefix which can be defined either as a `PRINT`, a `WARN` or an `ERROR`.
---
--- Any additional parameters after `mainline` will be printed with an indentation.
---@param print_type int
---@param mainline any
---@vararg any
---@return void
local function modprint(print_type, mainline, ...)
    if mainline == nil then
        return
    end

    mainline = tostring(mainline)

    if print_type == _G[MOD_CODE].PRINT then
        print(_G[MOD_CODE].PRINT_PREFIX..mainline)
    elseif print_type == _G[MOD_CODE].WARN then
        print(_G[MOD_CODE].WARN_PREFIX..mainline)
    elseif print_type == _G[MOD_CODE].ERROR then
        print(_G[MOD_CODE].ERROR_PREFIX..mainline)
    end

    for _, line in ipairs({...}) do
        print("    "..tostring(line))
    end

    print("")
end

---
--- A custom assert that prints the mods special error message with the `ERROR` prefix.
--- The assertion fails after all provided lines are printed, assuming `cond` is `false`.
---
--- Any additional parameters after `mainline` will be printed with an indentation.
---@param cond bool
---@param mainline any
---@vararg any
---@return void
local function modassert(cond, mainline, ...)
    if not cond then
        modprint(_G[MOD_CODE].ERROR_PREFIX, mainline, ...)

        _G.error("Assertion failed!")
    end
end

---
--- Saves `data` as a persistent json string using `TheSim:SetPersistentString()`. The string is saved inside `filename`.
--- Currently only tested on client-sided mods.
---
--- `data` can be either a Lua table or a json string.
---
--- `cb` is an optional function that will run after a successful string save.
---@param filename string
---@param data table|str
---@param cb function
---@return void
local function ModSetPersistentData(filename, data, cb)
    if type(data) == "table" then
        data = _G.json.encode(data)
    elseif type(data) ~= "string" then
        modassert(false, "Failed to save persistent data!", "Data provided is neither a table nor a string!")
    end
    
    if cb == nil or type(cb) ~= "function" then
        _G.TheSim:SetPersistentString(filename, data, false)
        return
    end

    _G.TheSim:SetPersistentString(filename, data, false, cb)
end

---
--- Retrieves persistent data as a json string from `filename`.
--- Currently only tested on client-sided mods.
---
--- `cb` runs with 2 parameters: `success`, a boolean, and `data`, the json string. If `success` is `false` `data` is an empty string.
---@param filename string
---@param cb function
---@return void
local function ModGetPersistentData(filename, cb)
    modassert(type(cb) == "function", "Failed to load persistent data!", "cb needs to be a function!")
    _G.TheSim:GetPersistentString(filename, cb)
end

---
--- Retrieves current mod setting using `setting_id`. Will print a message if `setting_id` doesn't exist.
---@param setting_id string
---@return table
local function GetModSetting(setting_id)
    if _G[MOD_CODE].CURRENT_SETTINGS[setting_id] ~= nil then
        return _G[MOD_CODE].CURRENT_SETTINGS[setting_id]
    end

    modprint(_G[MOD_CODE].PRINT, "Trying to get mod setting "..tostring(setting_id).." but it does not seem to exist.")
end

-- [[ Disable for live builds ]]
_G[MOD_CODE].DEV = true

-- [[ Universal Variables ]]
_G[MOD_CODE].PRINT = 0
_G[MOD_CODE].WARN = 1
_G[MOD_CODE].ERROR = 2
_G[MOD_CODE].PRINT_PREFIX = "["..MOD_CODE.."] "..MOD_NAME.." - "
_G[MOD_CODE].WARN_PREFIX = "["..MOD_CODE.."] "..MOD_NAME.." - WARNING! "
_G[MOD_CODE].ERROR_PREFIX = "["..MOD_CODE.."] "..MOD_NAME.." - ERROR! "

_G[MOD_CODE].modprint = modprint
_G[MOD_CODE].modassert = modassert
_G[MOD_CODE].ModSetPersistentData = ModSetPersistentData
_G[MOD_CODE].ModGetPersistentData = ModGetPersistentData
_G[MOD_CODE].GetModSetting = GetModSetting


-- [[                                             ]] --
-- [[ Here is where mod specific env variables go ]] --
-- [[                                             ]] --

-- [[ Constants ]]
-- EMPTY

-- [[ Mod Settings ]] -- Not to be confused with configuration_options.
                      -- These show up in Game Options and can be updated during gameplay.
local enableDisableOptions = {
    { text = _G.STRINGS.UI.OPTIONS.DISABLED, data = false },
    { text = _G.STRINGS.UI.OPTIONS.ENABLED,  data = true  }
}

_G[MOD_CODE].SETTING_TYPES = {
    SPINNER = "spinner",
    LIST = "list",
}

_G[MOD_CODE].MOD_SETTINGS = {
    FILENAME = "MYI_settings",
    TAB_NAME = "Minecraftify Your Items!",
    TOOLTIP = "Modify the mods settings",
    SETTINGS = {
        WORLD_Y = {
            ID = "MYI_world_y",
            SPINNER_TITLE = "Use world Y axis:",
            TOOLTIP = "Makes items stay perpendicular to the ground regardless of the cameras pitch.",
            COLUMN = 1,
            TYPE = _G[MOD_CODE].SETTING_TYPES.SPINNER,
            VALUES = enableDisableOptions,
            DEFAULT = true
        },
        SHADOWS = {
            ID = "MYI_shadows",
            SPINNER_TITLE = "Use shadows:",
            TOOLTIP = "Creates minecraft style shadows under dropped items.\nMay affect performence.",
            COLUMN = 1,
            TYPE = _G[MOD_CODE].SETTING_TYPES.SPINNER,
            VALUES = enableDisableOptions,
            DEFAULT = true
        },
        EXCLUDE_TAGS = {
            ID = "MYI_exclude_tags",
            SPINNER_TITLE = "Tag exclusion list:",
            TOOLTIP = "Create you very own exclusion list.\nItems with any of the tags from this list will not get the minecraft effect!",
            COLUMN = 2,
            TYPE = _G[MOD_CODE].SETTING_TYPES.LIST,
            DEFAULT = {
                { id = 1, data = "flying" },
                { id = 2, data = "heavy" },
                { id = 3, data = "structure" },
                { id = 4, data = "furnituredecor" }
            }
        },
        EXCLUDE_PREFABS = {
            ID = "MYI_exclude_prefabs",
            SPINNER_TITLE = "Entity exclusion list:",
            TOOLTIP = "Create you very own exclusion list.\nItems from this list will not get the minecraft effect!\nYou must use entity prefabs for this list.",
            COLUMN = 2,
            TYPE = _G[MOD_CODE].SETTING_TYPES.LIST,
            DEFAULT = {
                { id = 1, data = "fireflies" }
            }
        }
    }
}

_G[MOD_CODE].CURRENT_SETTINGS = {  }

-- [[ Misc. Variables ]]
_G[MOD_CODE].AffectedEntities = {  }

_G[MOD_CODE].EnableForEntity = function(ent)
    if ent.components and ent.components.MYImanager == nil then
        ent:AddComponent("MYImanager")
        _G[MOD_CODE].AffectedEntities[ent.GUID] = ent
    end
end

_G[MOD_CODE].DisableForEntity = function(ent)
    if ent.components and ent.components.MYImanager then
        ent:RemoveComponent("MYImanager")
    end
    
    _G[MOD_CODE].AffectedEntities[ent.GUID] = nil
end

_G[MOD_CODE].ShouldBeAffected = function(ent)
    if ent.replica.inventoryitem == nil or ent.replica.combat then
        return false
    end

    local exclude_prefabs = {  }
    for _, entry in ipairs(_G[MOD_CODE].CURRENT_SETTINGS[_G[MOD_CODE].MOD_SETTINGS.SETTINGS.EXCLUDE_PREFABS.ID]) do
        table.insert(exclude_prefabs, entry.data)
    end

    if table.contains(exclude_prefabs, ent.prefab) then
        return false
    end

    local exclude_tags = {  }
    for _, entry in ipairs(_G[MOD_CODE].CURRENT_SETTINGS[_G[MOD_CODE].MOD_SETTINGS.SETTINGS.EXCLUDE_TAGS.ID]) do
        table.insert(exclude_tags, entry.data)
    end

    if #exclude_tags == 0 then
        return true
    end

    if ent:HasAnyTag(_G.unpack(exclude_tags)) then
        return false
    end

    return true
end

_G[MOD_CODE].UpdateAffectedEntities = function()
    for _, ent in pairs(_G.Ents) do
        local is_affected = ent.components.MYImanager ~= nil
        if _G[MOD_CODE].ShouldBeAffected(ent) then
            if not is_affected then
                _G[MOD_CODE].EnableForEntity(ent)
            end
        elseif is_affected then
            _G[MOD_CODE].DisableForEntity(ent)
        end
    end
end