if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_melee"
SWEP.PrintName = "Pocket Knife"
SWEP.Instructions = "A small knife which can be easily hidden in your pockets.\n\nLMB to attack.\nR + LMB to change attack mode.\nRMB to block."
SWEP.Category = "Weapons - Melee"
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.WorldModel = "models/weapons/w_knife_swch.mdl"
SWEP.WorldModelReal = "models/weapons/salat/reanim/c_s&wch0014.mdl"
SWEP.WorldModelExchange = false

SWEP.HoldPos = Vector(-4,0,-1)
SWEP.HoldAng = Angle(0,0,0)

SWEP.SuicidePos = Vector(-10, 5, -7)
SWEP.SuicideAng = Angle(-30, 0, 0)
SWEP.SuicideCutVec = Vector(-1, -5, 1)
SWEP.SuicideCutAng = Angle(10, 0, 0)
SWEP.SuicideTime = 0.5
SWEP.CanSuicide = true
SWEP.SuicideNoLH = true
SWEP.SuicidePunchAng = Angle(5, -15, 0)

SWEP.BreakBoneMul = 0.25

SWEP.AnimList = {
    ["idle"] = "idle",
    ["deploy"] = "draw",
    ["attack"] = "stab",
    ["attack2"] = "midslash1",
    ["duct_cut"] = "cut",
    ["inspect"] = "inspect"
}

if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/wep_jack_hmcd_pocketknife")
	SWEP.IconOverride = "vgui/wep_jack_hmcd_pocketknife.png"
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

SWEP.setlh = true
SWEP.setrh = true
SWEP.TwoHanded = false

SWEP.AttackHit = "weapons/knife/knife_hitwall1.wav"
SWEP.Attack2Hit = "snd_jack_hmcd_knifehit.wav"
--
SWEP.DeploySnd = "weapons/knife/knife_deploy1.wav"

SWEP.AttackPos = Vector(0,0,0)
SWEP.DamageType = DMG_SLASH
SWEP.DamagePrimary = 8
SWEP.DamageSecondary = 6

SWEP.PenetrationPrimary = 5
SWEP.PenetrationSecondary = 3
SWEP.BleedMultiplier = 1.5

SWEP.MaxPenLen = 3

SWEP.PainMultiplier = 0.5

SWEP.PenetrationSizePrimary = 1.5
SWEP.PenetrationSizeSecondary = 1

SWEP.StaminaPrimary = 9
SWEP.StaminaSecondary = 12

SWEP.AttackLen1 = 42
SWEP.AttackLen2 = 35

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
    local check = self:GetBlocking() and self:GetWM():GetSequenceName(self:GetWM():GetSequence()) != "cut"
    addPosLerp.z = addPosLerp.z + (check and 2 or 0)
    addPosLerp.x = addPosLerp.x + (check and 0 or 0)
    addPosLerp.y = addPosLerp.y + (check and 3 or 0)
    addAngLerp.r = addAngLerp.r + (check and -15 or 0)
    addAngLerp.y = addAngLerp.y + (check and 8 or 0)
    
    return true
end

function SWEP:CanSecondaryAttack()
    return self.allowsec and true or false
end

SWEP.AttackPos = Vector(0,0,0)
SWEP.AttackingPos = Vector(0,0,0)

SWEP.AttackTime = 0.2
SWEP.AnimTime1 = 0.7
SWEP.WaitTime1 = 0.5

SWEP.Attack2Time = 0.1
SWEP.AnimTime2 = 0.5
SWEP.WaitTime2 = 0.4

SWEP.AttackTimeLength = 0.15
SWEP.Attack2TimeLength = 0.1

SWEP.AttackRads = 2
SWEP.AttackRads2 = 55

SWEP.SwingAng = 90
SWEP.SwingAng2 = 0

SWEP.MultiDmg1 = false
SWEP.MultiDmg2 = true
