local TEXTURE = "images/circle.tex"
local SHADER = "shaders/vfx_particle.ksh"

local COLOUR_ENVELOPE_NAME = "mc_item_shadows_colour_envelope"
local SCALE_ENVELOPE_NAME = "mc_item_shadows_scale_envelope"

local assets = {
    Asset("IMAGE", TEXTURE),
    Asset("SHADER", SHADER)
}

local function InitEnvelope()
    EnvelopeManager:AddColourEnvelope(
        COLOUR_ENVELOPE_NAME,
        {
            { 0, { 0, 0, 0, 0.6 } }
        }
   )

   EnvelopeManager:AddVector2Envelope(
       SCALE_ENVELOPE_NAME,
       {
           { 0, { 1.4, 1.4 } }
       }
   )

    InitEnvelope = nil
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    
    inst.persists = false

    if InitEnvelope ~= nil then
        InitEnvelope()
    end

    local effect = inst.entity:AddVFXEffect()
    effect:InitEmitters(1)
    effect:SetRenderResources(0, resolvefilepath(TEXTURE), resolvefilepath(SHADER))
    effect:SetUVFrameSize(0, 1, 1)
    effect:SetMaxNumParticles(0, 1000) -- 1000 should be enough, even megabasers shouldn't reach this amount of items on screen
    effect:SetMaxLifetime(0, 0)
    effect:SetColourEnvelope(0, COLOUR_ENVELOPE_NAME)
    effect:SetScaleEnvelope(0, SCALE_ENVELOPE_NAME)
    effect:SetBlendMode(0, BLENDMODE.Premultiplied)
    effect:SetSortOrder(0, 1)
    effect:SetSortOffset(0, 1)
    effect:SetLayer(0, LAYER_GROUND)
    effect:SetWorldSpaceEmitter(0, true)

    effect:SetSpawnVectors(0,
        0, 0, 1,
        1, 0, 0
    )

    EmitterManager:AddEmitter(inst, nil, function()
        effect:ClearAllParticles(0)

        if not MYI.CURRENT_SETTINGS[MYI.MOD_SETTINGS.SETTINGS.SHADOWS.ID] then
            return
        end

        for _, ent in pairs(MYI.AffectedEntities) do
            if ent.components.MYImanager.shader_set then
                local pos = ent:GetPosition()
                effect:AddParticleUV(
                    0,
                    0,               -- lifetime
                    pos.x, 0, pos.z, -- position
                    0, 0, 0,         -- velocity
                    0, 0             -- uv offset
                )
            end
        end
    end)

    return inst
end

return Prefab("myishadows", fn, assets)