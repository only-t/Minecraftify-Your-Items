env._G = GLOBAL._G
GLOBAL.setfenv(1, env)

Assets = {
    Asset("SHADER", "shaders/minecraftify_ent.ksh")
}

PrefabFiles = {
    "MYIshadows"
}

-- [[ Mod environment ]]
modimport("scripts/MYIenv")

if _G.MYI.DEV then
    _G.MYI.inspect = require("inspect")
end
--

-- Custom settings because configuration_options are annoying to use
modimport("scripts/MYImodsettings")

-- [[ Misc. changes ]]
AddPrefabPostInitAny(function(inst)
    if not _G.TheNet:IsDedicated() and inst.AnimState then
        inst:DoTaskInTime(0, function() -- Wait 1 frame for the replica components to get created on the client
            if inst.replica.inventoryitem and not inst.replica.combat and _G.MYI.ShouldBeAffected(inst) then
                _G.MYI.EnableForEntity(inst)
            end
        end)
    end
end)

AddPlayerPostInit(function(inst)
    if not _G.TheNet:IsDedicated() then
        inst.MYIshadows = _G.SpawnPrefab("MYIshadows")
        inst.MYIshadows.entity:SetParent(inst.entity)
    end
end)
--