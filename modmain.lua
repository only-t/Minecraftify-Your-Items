env._G = GLOBAL._G
GLOBAL.setfenv(1, env)

Assets = {
    Asset("SHADER", "shaders/minecraftify_ent.ksh")
}

PrefabFiles = {
    "mc_item_shadows"
}

-- [[ Mod environment ]]
modimport("scripts/MYIenv")

if _G.MYI.DEV then
    _G.MYI.inspect = require("inspect")
end
--

-- Custom settings because configuration_options are annoying to use
modimport("scripts/MYImodsettings")

-- Misc. changes
AddPrefabPostInitAny(function(inst)
    if not _G.TheNet:IsDedicated() and inst.AnimState then
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