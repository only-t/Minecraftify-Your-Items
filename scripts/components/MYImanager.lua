local function ClearEffect(self)
    if self.inst.AnimState == nil then -- How?
        return
    end

    self.inst.AnimState:ClearDefaultEffectHandle()
    self.shader_set = false
    
    local floating = self.inst.components.floater and self.inst.components.floater.showing_effect or false
    if floating then
        self.inst.AnimState:SetFloatParams(-0.05, 1.0, self.inst.components.floater.bob_percent)
    else
        self.inst.AnimState:SetFloatParams(0, 0, 0)
    end
end

local MYIManager = Class(function(self, inst)
    self.inst = inst

    self.shader_set = false

    if not self.inst:IsAsleep() then
        self.inst:StartUpdatingComponent(self)
    end
end)

function MYIManager:OnRemoveEntity()
    self:OnRemoveFromEntity()
end

function MYIManager:OnRemoveFromEntity()
	self.inst:StopUpdatingComponent(self)
    ClearEffect(self)
end

function MYIManager:OnEntitySleep()
	self.inst:StopUpdatingComponent(self)
    ClearEffect(self) -- To remove the shadow
end

function MYIManager:OnEntityWake()
	self.inst:StartUpdatingComponent(self)
end

function MYIManager:OnUpdate()
    if self.inst.components.billboardfixmanager ~= nil then -- For the First Person Mod
        self.inst:RemoveComponent("billboardfixmanager")
        self.shader_set = false
    end

    if self.inst.replica.inventoryitem == nil or self.inst.replica.inventoryitem:IsHeld() then
        if self.shader_set then
            ClearEffect(self)
        end

        return
    end

    local _, _, _, orientation = self.inst.AnimState:GetHistoryData()
    if orientation == ANIM_ORIENTATION.BillBoard and not self.shader_set then
        self.inst.AnimState:SetDefaultEffectHandle(resolvefilepath("shaders/minecraftify_ent.ksh"))
        self.shader_set = true
    elseif orientation ~= ANIM_ORIENTATION.BillBoard and self.shader_set then
        ClearEffect(self)
    end

    if self.shader_set then
        local x, y, z = self.inst.Transform:GetWorldPosition()
        local floating = (self.inst.components.floater and self.inst.components.floater.showing_effect) or false
        local param_x = math.floor(x * 1000) -- Multiplying by 1000 for a 4 floating point precision, which is decent enough
        local param_y = TheCamera.pitch / 360 + math.floor(y * 100000) -- Y can get more precision because it will never get too big
        local param_z = math.floor(z * 1000)

        if MYI.GetModSetting(MYI.MOD_SETTINGS.SETTINGS.WORLD_Y.ID) then
            param_x = param_x + 0.5
        end

        if floating then
            param_z = param_z + 0.5
        end

        self.inst.AnimState:SetFloatParams(param_x, param_y, param_z)
    end
end

return MYIManager