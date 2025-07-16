local function modprint(print_type, mainline, ...)
    if mainline == nil then
        return
    end

    _G.assert(type(mainline) == "string", "mainline has to be a string!")

    if print_type == _G.MYI.PRINT then
        print(_G.MYI.PRINT_PREFIX..mainline)
    elseif print_type == _G.MYI.WARN then
        print(_G.MYI.WARN_PREFIX..mainline)
    elseif print_type == _G.MYI.ERROR then
        print(_G.MYI.ERROR_PREFIX..mainline)
    end

    for _, line in ipairs({...}) do
        print("    "..line)
    end

    print("")
end

local function modassert(cond, mainline, ...)
    if not cond then
        print(_G.MYI.ERROR_PREFIX..mainline)
        for _, line in ipairs({...}) do
            print("    "..line)
        end

        _G.error("Assertion failed!")
    end
end

_G.MYI = {
    DEV = true,

    -- Utility
    MOD_PRINT = 0,
    MOD_WARN = 1,
    MOD_ERROR = 2,
    PRINT_PREFIX = "[MYI] Minecraftify Your Items! - ",
    WARN_PREFIX = "[MYI] Minecraftify Your Items! - WARNING! ",
    ERROR_PREFIX = "[MYI] Minecraftify Your Items! - ERROR! ",

    modprint = modprint,
    modassert = modassert,
    
    -- Constants
    
    -- Mod settings
    SETTINGS = {
        NAME = "Minecraftify Your Items!",
        TOOLTIP = "Modify the mods settings",
        OPTIONS = {
            WORLD_Y = {
                NAME = "Use world Y axis:",
                OPTIONS_STR = "minecraftify_worldY",
                TOOLTIP = "Makes items stay perpendicular to the ground regardless of the cameras pitch.",
                DEFAULT = true
            },
            SHADOWS = {
                NAME = "Use shadows:",
                OPTIONS_STR = "minecraftify_shadows",
                TOOLTIP = "Creates minecraft style shadows under dropped items.\nMay affect performence.",
                DEFAULT = true
            },
            EXCLUDE_TAGS = {
                NAME = "Tag exclusion list:",
                OPTIONS_STR = "minecraftify_exclude_tags",
                TOOLTIP = "Create you very own exclusion list.\nItems with any of the tags from this list will not get the effect!",
                DEFAULT = {  }
            },
            EXCLUDE_PREFABS = {
                NAME = "Entity exclusion list:",
                OPTIONS_STR = "minecraftify_exclude_prefabs",
                TOOLTIP = "Create you very own exclusion list.\nItems from this list will not get the effect!\nYou must use entity prefabs for this list.",
                DEFAULT = {  }
            }
        }
    }
}