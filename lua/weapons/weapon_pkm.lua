SWEP.Base = "homigrad_base"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.PrintName = "PKM"
SWEP.Author = "Degtyarev plant"
SWEP.Instructions = "Machine gun chambered in 7.62x54 mm\n\nRate of fire 650 rounds per minute"
SWEP.Category = "Weapons - Machineguns"
SWEP.Primary.ClipSize = 100
SWEP.Primary.DefaultClip = 100
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "7.62x54 mm"
SWEP.Primary.Cone = 0
SWEP.Primary.Damage = 70
SWEP.Primary.Spread = 0
SWEP.Primary.Force = 70
SWEP.Primary.Sound = {"weapons/newsndw/pkmnew_fp.wav", 75, 100, 110}
SWEP.Primary.SoundEmpty = {"zcitysnd/sound/weapons/ak47/handling/ak47_empty.wav", 75, 100, 105, CHAN_WEAPON, 2}
SWEP.Primary.Wait = 0.09
SWEP.ReloadTime = 7.5
SWEP.ReloadSoundes = {
	"none",
	"none",
	"pwb2/weapons/pkm/pkm_coverup.wav",
	"none",
	"none",
	"pwb2/weapons/pkm/pkm_boxout.wav",
	"none",
	"pwb2/weapons/pkm/pkm_boxin.wav",
	"none",
	"none",
	"pwb2/weapons/pkm/pkm_coverdown.wav",
	"none",
	"none",
	"none",
	"none"
}

local function UpdateVisualBullets(mdl,count)
	for i = 1, 8 do
		local boneid = 112 - i
		mdl:ManipulateBoneScale(boneid,i <= count and Vector(1,1,1) or Vector(0,0,0))
	end
end

function SWEP:PostFireBullet(bullet)
	UpdateVisualBullets(self:GetWM(),self:Clip1())
	local owner = self:GetOwner()
	if ( SERVER or self:IsLocal2() ) and owner:OnGround() then
		if IsValid(owner) and owner:IsPlayer() then
			owner:SetVelocity(owner:GetVelocity() - owner:GetVelocity()/0.45)
		end
	end
end

SWEP.CanSuicide = false

SWEP.PPSMuzzleEffect = "muzzleflash_MINIMI" -- shared in sh_effects.lua

SWEP.DeploySnd = {"homigrad/weapons/draw_hmg.mp3", 55, 100, 110}
SWEP.HolsterSnd = {"homigrad/weapons/hmg_holster.mp3", 55, 100, 110}
SWEP.Slot = 2
SWEP.SlotPos = 10
SWEP.ViewModel = ""
SWEP.WorldModel = "models/weapons/w_mach_m249para.mdl"
SWEP.WorldModelFake = "models/weapons/c_mach_pkm.mdl"

SWEP.FakeAttachment = "1"
SWEP.FakePos = Vector(-5, 2.85, 6.7)
SWEP.FakeAng = Angle(0, 0, 0)
SWEP.AttachmentPos = Vector(1,0,0)
SWEP.AttachmentAng = Angle(0,0,90)



SWEP.FakeVPShouldUseHand = true
SWEP.AnimList = {
	["idle"] = "draw",
	["reload"] = "reload",
	["reload_empty"] = "reload",
}

SWEP.GunCamPos = Vector(6,-17,-4)
SWEP.GunCamAng = Angle(190,0,-90)

SWEP.FakeViewBobBone = "ValveBiped.Bip01_R_Hand"
SWEP.FakeViewBobBaseBone = "ValveBiped.Bip01_R_UpperArm"
SWEP.ViewPunchDiv = 40

SWEP.FakeReloadSounds = {
	[0.15] = "weapons/m249/m249_shoulder.wav",
	[0.25] = "weapons/pkm/coverup.wav",
	[0.35] = "weapons/pkm/bullet.wav",
	[0.52] = "weapons/pkm/boxout.wav",
	[0.69] = "weapons/pkm/boxin.wav",
	--[0.37] = "weapons/m4a1/m4a1_magrelease.wav",
	[0.75] = "weapons/pkm/chain.wav",
	[0.83] = "weapons/pkm/coverdown.wav",
	[0.87] = "weapons/pkm/coversmack.wav",
	[0.97] = "weapons/pkm/bolt.wav",
}

SWEP.NoIdleLoop = true
SWEP.FakeEmptyReloadSounds = {
	[0.15] = "weapons/m249/m249_shoulder.wav",
	[0.25] = "weapons/pkm/coverup.wav",
	[0.35] = "weapons/pkm/bullet.wav",
	[0.52] = "weapons/pkm/boxout.wav",
	[0.69] = "weapons/pkm/boxin.wav",
	--[0.37] = "weapons/m4a1/m4a1_magrelease.wav",
	[0.75] = "weapons/pkm/chain.wav",
	[0.83] = "weapons/pkm/coverdown.wav",
	[0.87] = "weapons/pkm/coversmack.wav",
	[0.97] = "weapons/pkm/bolt.wav",
}
--SWEP.MagModel = "models/weapons/zcity/w_glockmag.mdl"
SWEP.FakeReloadEvents = {
	[0.5] = function( self )
		if CLIENT then
			UpdateVisualBullets(self:GetWM(),20)
		end
	end,
}


SWEP.ScrappersSlot = "Primary"
SWEP.weight = 4.5

SWEP.ShockMultiplier = 2

SWEP.CustomShell = "762x54"
SWEP.CustomSecShell = "m60len"
SWEP.EjectPos = Vector(2,13,-3)
SWEP.EjectAng = Angle(0,90,0)

SWEP.WepSelectIcon2 = Material("pwb2/vgui/weapons/pkm.png")
SWEP.IconOverride = "pwb2/vgui/weapons/pkm.png"

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
	return applied
end

function SWEP:ApplySkinNow()
	local skinId = self:GetNWString("hg_skin_id", "")
	self._lastSkinId = self._lastSkinId or ""
	self._skinModelIndices = self._skinModelIndices or {}
	self._baseIconPath = self._baseIconPath or self.IconOverride
	self._baseIconMat = self._baseIconMat or self.WepSelectIcon2
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
	models[#models + 1] = self:GetWeaponEntity()
	if self.GetWM then
		models[#models + 1] = self:GetWM()
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
				self.WepSelectIcon2 = mat
				self.IconOverride = iconPath
			else
				local matPng = Material(iconPath .. ".png")
				if matPng and not matPng:IsError() then
					self.WepSelectIcon2 = matPng
					self.IconOverride = iconPath .. ".png"
				else
					self.WepSelectIcon2 = self._baseIconMat
					self.IconOverride = self._baseIconPath
				end
			end
		else
			self.WepSelectIcon2 = self._baseIconMat
			self.IconOverride = self._baseIconPath
		end
	end
end

function SWEP:ThinkAdd()
	self:ApplySkinNow()
end

SWEP.weaponInvCategory = 1
SWEP.HoldType = "rpg"
SWEP.ZoomPos = Vector(-3, 0.0898, 6.2479)
SWEP.RHandPos = Vector(4, -2, 0)
SWEP.LHandPos = Vector(7, -2, -2)
SWEP.ShellEject = "EjectBrass_762Nato"
SWEP.Spray = {}
for i = 1, 100 do
	SWEP.Spray[i] = Angle(-0.05 - math.cos(i) * 0.04, math.cos(i * i) * 0.05, 0) * 2
end

SWEP.LocalMuzzlePos = Vector(37.836,0.214,3.351)
SWEP.LocalMuzzleAng = Angle(-0.2,-0.05,0)
SWEP.WeaponEyeAngles = Angle(0,0,0)

SWEP.Ergonomics = 0.6
SWEP.OpenBolt = true
SWEP.Penetration = 20
SWEP.WorldPos = Vector(-1, -0.5, 0)
SWEP.WorldAng = Angle(0, 0, 0)
SWEP.UseCustomWorldModel = true
SWEP.attPos = Vector(0, 0, 0)
SWEP.attAng = Angle(-0.05, -0.2, 0)
SWEP.AimHands = Vector(0, 1, -3.5)
SWEP.lengthSub = 15
SWEP.DistSound = "m249/m249_dist.wav"
SWEP.bipodAvailable = true
SWEP.bipodsub = 15

SWEP.RestPosition = Vector(22, -1, 4)

SWEP.RecoilMul = 0.3

SWEP.availableAttachments = {
	sight = {
		["mountType"] = {"picatinny", "dovetail"},
		["mount"] = Vector(-29.5, 2.8, -0.2),
	},
	mount = {
		["picatinny"] = {
			"mount1",
			Vector(-29.5, 1, -0.2),
			{},
			["mountType"] = "picatinny",
		},
		["dovetail"] = {
			"empty",
			Vector(0, 0, 0),
			{},
			["mountType"] = "dovetail",
		},
	}
}

--local to head
SWEP.RHPos = Vector(4,-7,4)
SWEP.RHAng = Angle(0,-12,90)
--local to rh
SWEP.LHPos = Vector(9,-4,-5)
SWEP.LHAng = Angle(-10,10,-120)

local ang1 = Angle(30, -15, 0)
local ang2 = Angle(0, 10, 0)

function SWEP:AnimHoldPost()
	--self:BoneSet("l_finger0", vector_origin, ang1)
	--self:BoneSet("l_finger02", vector_origin, ang2)
end

-- RELOAD ANIM AKM
SWEP.ReloadAnimLH = {
	Vector(0,0,0),
	Vector(5,-2,7),
	Vector(7,-2,4),
	Vector(-5,-5,1),
	Vector(-5,-5,1),
	Vector(-15,-5,1),
	Vector(-5,-2,15),
	Vector(-5,-5,1),
	Vector(7,-2,4),
	Vector(5,-2,7),
	Vector(0,0,0),
}

SWEP.ReloadAnimRH = {
	Vector(0,0,0),
	Vector(0,0,0),
}

SWEP.ReloadAnimLHAng = {
	Angle(0,0,0),
	Angle(0,0,0),
	Angle(0,0,0),
	Angle(45,0,-90),
	Angle(45,0,-90),
	Angle(0,0,0),
	Angle(0,0,0),
	Angle(0,0,0),
}

SWEP.ReloadAnimRHAng = {
	Angle(0,0,0),
}

SWEP.ReloadAnimWepAng = {
	Angle(0,0,0),
	Angle(10,0,0),
	Angle(10,0,0),
	Angle(0,15,0),
	Angle(15,15,0),
	Angle(-15,-15,0),
	Angle(-15,-5,0),
	Angle(0,0,0),
}

-- Inspect Assault

SWEP.InspectAnimWepAng = {
	Angle(0,0,0),
	Angle(4,4,15),
	Angle(10,15,25),
	Angle(10,15,25),
	Angle(10,15,25),
	Angle(-6,-15,-15),
	Angle(1,15,-45),
	Angle(15,25,-55),
	Angle(15,25,-55),
	Angle(15,25,-55),
	Angle(0,0,0),
	Angle(0,0,0)
}
