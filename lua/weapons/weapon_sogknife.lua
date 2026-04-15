if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "SOG SEAL 2000"
SWEP.Instructions = "A serious big knife used by seals (special forces of the US Navy). A good choice for a melee weapon.\n\nLMB to attack.\nR + LMB to change attack mode.\nRMB to block."
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.WorldModel = "models/weapons/combatknife/tactical_knife_iw7_wm.mdl"
SWEP.WorldModelReal = "models/weapons/gleb/c_knife_t.mdl"
SWEP.WorldModelExchange = "models/zcity/weapons/w_sog_knife.mdl"
SWEP.DontChangeDropped = true
SWEP.modelscale = 1.4
SWEP.modelscale2 = 1

SWEP.SuicidePos = Vector(16, -1, -3)
SWEP.SuicideAng = Angle(-40, 180, 0)
SWEP.SuicideCutVec = Vector(1, -5, 4)
SWEP.SuicideCutAng = Angle(10, 0, 0)
SWEP.SuicideTime = 0.5
SWEP.CanSuicide = true

SWEP.BleedMultiplier = 1.35
SWEP.PainMultiplier = 1.55

SWEP.DamagePrimary = 21
SWEP.DamageSecondary = 10

SWEP.setlh = false
SWEP.setrh = true
SWEP.TwoHanded = false

SWEP.basebone = 76

SWEP.HoldPos = Vector(-2,-5,-5)
SWEP.HoldAng = Angle(-15,20,-10)

SWEP.AttackPos = Vector(0,0,0)
SWEP.AttackingPos = Vector(0,0,0)

SWEP.weaponPos = Vector(-3.5,0,0)
SWEP.weaponAng = Angle(90,180,0)

SWEP.HoldType = "knife"

--SWEP.InstantPainMul = 0.25

--models/weapons/gleb/c_knife_t.mdl
if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/wep_jack_hmcd_knife")
	SWEP.IconOverride = "vgui/wep_jack_hmcd_knife.png"
	SWEP.BounceWeaponIcon = false
end

local function applySkinRulesToModel(model, rules, previousIndices)
	if not IsValid(model) then return {} end
	previousIndices = previousIndices or {}
	for _, idx in ipairs(previousIndices) do
		model:SetSubMaterial(idx, "")
	end

	local materials = model:GetMaterials() or {}
	local applied = {}
	for matIndex, matName in ipairs(materials) do
		local lowerMat = string.lower(matName or "")
		for _, rule in ipairs(rules) do
			if string.find(lowerMat, rule[1], 1, true) then
				model:SetSubMaterial(matIndex - 1, rule[2])
				applied[#applied + 1] = matIndex - 1
				break
			end
		end
	end

	if #applied == 0 and istable(rules) and rules[1] and isstring(rules[1][2]) and rules[1][2] ~= "" then
		for matIndex = 1, #materials do
			model:SetSubMaterial(matIndex - 1, rules[1][2])
			applied[#applied + 1] = matIndex - 1
		end
	end

	return applied
end

function SWEP:ApplySkinNow()
	local skinId = self:GetNWString("hg_skin_id", "")
	self._lastSkinId = self._lastSkinId or ""
	self._skinModelIndices = self._skinModelIndices or {}
	self._baseIconPath = self._baseIconPath or self.IconOverride
	self._baseIconMat = self._baseIconMat or self.WepSelectIcon
	self._lastIconSkinId = self._lastIconSkinId or ""
	if skinId == self._lastSkinId and not self._forceSkinUpdate then return end
	self._forceSkinUpdate = nil
	self._lastSkinId = skinId

	local rules = nil
	local iconPath = nil
	if skinId ~= "" and hg and hg.skins and hg.skins.GetSkinInfo then
		local info = hg.skins.GetSkinInfo(skinId)
		if info and istable(info.material_rules) then
			rules = info.material_rules
		end
		if info and isstring(info.icon) and info.icon ~= "" then
			iconPath = info.icon
		end
	end

	local models = {}
	if self.GetWM then
		models[#models + 1] = self:GetWM()
	end
	if self.GetWeaponEntity then
		models[#models + 1] = self:GetWeaponEntity()
	end
	if IsValid(self.worldModel) then
		models[#models + 1] = self.worldModel
	end
	if IsValid(self.worldModel2) then
		models[#models + 1] = self.worldModel2
	end
	if IsValid(self.NPCworldModel) then
		models[#models + 1] = self.NPCworldModel
	end

	for _, mdl in ipairs(models) do
		if IsValid(mdl) then
			local entIndex = mdl:EntIndex()
			if rules then
				self._skinModelIndices[entIndex] = applySkinRulesToModel(mdl, rules, self._skinModelIndices[entIndex] or {})
			else
				local old = self._skinModelIndices[entIndex] or {}
				for _, idx in ipairs(old) do
					mdl:SetSubMaterial(idx, "")
				end
				self._skinModelIndices[entIndex] = {}
			end
		end
	end

	if CLIENT and (self._lastIconSkinId ~= skinId or self._forceIconUpdate) then
		self._forceIconUpdate = nil
		self._lastIconSkinId = skinId
		if isstring(iconPath) and iconPath ~= "" then
			local mat = Material(iconPath)
			if mat and not mat:IsError() then
				self.WepSelectIcon = mat
				self.IconOverride = iconPath
			else
				local matPng = Material(iconPath .. ".png")
				if matPng and not matPng:IsError() then
					self.WepSelectIcon = matPng
					self.IconOverride = iconPath .. ".png"
				else
					self.WepSelectIcon = self._baseIconMat
					self.IconOverride = self._baseIconPath
				end
			end
		else
			self.WepSelectIcon = self._baseIconMat
			self.IconOverride = self._baseIconPath
		end
	end
end

function SWEP:ThinkAdd()
	self:ApplySkinNow()
end

SWEP.BreakBoneMul = 0.5
SWEP.ImmobilizationMul = 0.45
SWEP.StaminaMul = 0.5
SWEP.HadBackBonus = true

SWEP.attack_ang = Angle(0,0,0)
function SWEP:Initialize()
    self.attackanim = 0
    self.sprintanim = 0
    self.animtime = 0
    self.animspeed = 1
    self.reverseanim = false
    self.Initialzed = true
    self:PlayAnim("idle",10,true)

    self:SetHold(self.HoldType)

    self:InitAdd()
end

SWEP.AttackTime = 0.3
SWEP.AnimTime1 = 1
SWEP.WaitTime1 = 0.57

SWEP.AnimTime2 = 1
SWEP.WaitTime2 = 0.4

SWEP.AnimList = {
    ["idle"] = "idle",
    ["deploy"] = "draw",
    ["attack"] = "stab_miss",
    ["attack2"] = "midslash1",
}

SWEP.BlockTier = 2
SWEP.MeleeMaterial = "metal"
SWEP.BlockImpactSound = "physics/metal/metal_solid_impact_bullet1.wav"

function SWEP:Reload()
    if SERVER then
        if self:GetOwner():KeyPressed(IN_ATTACK) then
            self:SetNetVar("mode", not self:GetNetVar("mode"))
            self:GetOwner():ChatPrint("Changed mode to "..(self:GetNetVar("mode") and "slash." or "stab."))
        end
    end
end

function SWEP:CanPrimaryAttack()
    if self:GetOwner():KeyDown(IN_RELOAD) then return end
    if not self:GetNetVar("mode") then
        return true
    else
        self.allowsec = true
        self:SecondaryAttack(true)
        self.allowsec = nil
        return false
    end
end

function SWEP:CustomBlockAnim(addPosLerp, addAngLerp)
    addPosLerp.z = addPosLerp.z + (self:GetBlocking() and -4 or 0)
    addPosLerp.x = addPosLerp.x + (self:GetBlocking() and 15 or 0)
    addPosLerp.y = addPosLerp.y + (self:GetBlocking() and -7 or 0)
    addAngLerp.r = addAngLerp.r + (self:GetBlocking() and 60 or 0)
    addAngLerp.y = addAngLerp.y + (self:GetBlocking() and 90 or 0)
	addAngLerp.x = addAngLerp.x + (self:GetBlocking() and -60 or 0)
    
    return true
end

function SWEP:CanSecondaryAttack()
    return self.allowsec and true or false
end

SWEP.AttackTimeLength = 0.15
SWEP.Attack2TimeLength = 0.1

SWEP.AttackRads = 35
SWEP.AttackRads2 = 45

SWEP.SwingAng = -90
SWEP.SwingAng2 = 0

SWEP.MultiDmg1 = false
SWEP.MultiDmg2 = true
