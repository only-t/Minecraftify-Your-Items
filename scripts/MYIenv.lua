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
local function modsetpersistentdata(filename, data, cb)
    if type(data) == "table" then
        data = json.encode(data)
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
local function modgetpersistentdata(filename, cb)
    modassert(type(cb) == "function", "Failed to load persistent data!", "cb needs to be a function!")
    _G.TheSim:GetPersistentString(filename, cb)
end

-- [[ Disable for live builds ]]
_G[MOD_CODE].DEV = true

-- [[ Universal variables ]]
_G[MOD_CODE].PRINT = 0
_G[MOD_CODE].WARN = 1
_G[MOD_CODE].ERROR = 2
_G[MOD_CODE].PRINT_PREFIX = "["..MOD_CODE.."] "..MOD_NAME.." - "
_G[MOD_CODE].WARN_PREFIX = "["..MOD_CODE.."] "..MOD_NAME.." - WARNING! "
_G[MOD_CODE].ERROR_PREFIX = "["..MOD_CODE.."] "..MOD_NAME.." - ERROR! "

_G[MOD_CODE].modprint = modprint
_G[MOD_CODE].modassert = modassert
_G[MOD_CODE].modsetpersistentdata = modsetpersistentdata
_G[MOD_CODE].modgetpersistentdata = modgetpersistentdata


-- [[                                             ]] --
-- [[ Here is where mod specific env variables go ]] --
-- [[                                             ]] --

-- [[ Constants ]]
-- EMPTY

-- [[ Mod settings ]] -- Not to be confused with configuration_options.
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
            NAME = "Use world Y axis:",
            TOOLTIP = "Makes items stay perpendicular to the ground regardless of the cameras pitch.",
            COLUMN = 1,
            TYPE = _G[MOD_CODE].SETTING_TYPES.SPINNER,
            VALUES = enableDisableOptions,
            DEFAULT = true
        },
        SHADOWS = {
            ID = "MYI_shadows",
            NAME = "Use shadows:",
            TOOLTIP = "Creates minecraft style shadows under dropped items.\nMay affect performence.",
            COLUMN = 1,
            TYPE = _G[MOD_CODE].SETTING_TYPES.SPINNER,
            VALUES = enableDisableOptions,
            DEFAULT = true
        },
        EXCLUDE_TAGS = {
            ID = "MYI_exclude_tags",
            NAME = "Tag exclusion list:",
            TOOLTIP = "Create you very own exclusion list.\nItems with any of the tags from this list will not get the minecraft effect!",
            COLUMN = 2,
            TYPE = _G[MOD_CODE].SETTING_TYPES.LIST,
            DEFAULT = {
                { id = 0, data = "flying" },
                { id = 1, data = "heavy" },
                { id = 2, data = "structure" },
                { id = 3, data = "furnituredecor" }
            }
        },
        EXCLUDE_PREFABS = {
            ID = "MYI_exclude_prefabs",
            NAME = "Entity exclusion list:",
            TOOLTIP = "Create you very own exclusion list.\nItems from this list will not get the minecraft effect!\nYou must use entity prefabs for this list.",
            COLUMN = 2,
            TYPE = _G[MOD_CODE].SETTING_TYPES.LIST,
            DEFAULT = {  }
        }
    }
}