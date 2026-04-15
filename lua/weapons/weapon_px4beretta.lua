SWEP.Base = "homigrad_base"
SWEP.Spawnable = true
SWEP.AdminOnly = false
SWEP.PrintName = "Beretta PX4"
SWEP.Author = "Fabbrica d'Armi Pietro Beretta Gardone"
SWEP.Instructions = "The Beretta Px4 Storm is a semi-automatic pistol intended for personal defense and law enforcement use. It is available in full size, Compact, and Subcompact versions. Chambered in 9x19 mm."
SWEP.Category = "Weapons - Pistols"
SWEP.Slot = 2
SWEP.SlotPos = 10
SWEP.ViewModel = ""
SWEP.WorldModel = "models/weapons/w_pist_usp.mdl"
SWEP.WorldModelFake = "models/weapons/zcity/salat/c_px4.mdl" --https://steamcommunity.com/sharedfiles/filedetails/?id=3544105055
//PrintBones(Entity(1):GetActiveWeapon():GetWM())
--uncomment for funny
SWEP.FakePos = Vector(-11.5, 4.1, 5.6)
SWEP.FakeAng = Angle(0, 0, 0)
SWEP.AttachmentPos = Vector(0,0,0)
SWEP.AttachmentAng = Angle(0,0,0)
SWEP.FakeAttachment = "1"
SWEP.FakeEjectBrassATT = "2"

SWEP.FakeReloadSounds = {
	[0.2] = "zcitysnd/sound/weapons/m9/handling/m9_magout.wav",

	[0.65] = "zcitysnd/sound/weapons/m9/handling/m9_magin.wav",
	[0.8] = "zcitysnd/sound/weapons/m9/handling/m9_maghit.wav",

}

SWEP.FakeEmptyReloadSounds = {
	[0.2] = "zcitysnd/sound/weapons/m9/handling/m9_magout.wav",

	[0.8] = "zcitysnd/sound/weapons/m9/handling/m9_magin.wav",
	[0.87] = "zcitysnd/sound/weapons/m9/handling/m9_maghit.wav",
	[1.07] = "zcitysnd/sound/weapons/m9/handling/m9_boltrelease.wav",
}
SWEP.MagModel = "models/joshzemlinsky/weapons/sof3_beretta_px4_mag.mdl"

SWEP.lmagpos = Vector(0,0,0)
SWEP.lmagang = Angle(0,0,0)
SWEP.lmagpos2 = Vector(-2,0,0)
SWEP.lmagang2 = Angle(0,0,-90)

SWEP.FakeMagDropBone = 2
local vector_full = Vector(1,1,1)

SWEP.FakeReloadEvents = {
	[0.15] = function( self, timeMul ) 
		if CLIENT then
			self:GetOwner():PullLHTowards("ValveBiped.Bip01_L_Thigh", 2.5 * timeMul)
			self:GetWM():ManipulateBoneScale(2, vector_full)
		end 
	end,
	[0.37] = function( self ) 
		if CLIENT and self:Clip1() < 1 then
			hg.CreateMag( self, Vector(-15,5,-15) )
			self:GetWM():ManipulateBoneScale(2, vector_origin)
		end 
	end,
	[0.55] = function( self ) 
		if CLIENT and self:Clip1() < 1 then
			self:GetWM():ManipulateBoneScale(2, vector_full)
		end 
	end,
}

SWEP.AnimList = {
	["idle"] = "idle",
	["reload"] = "reload",
	["reload_empty"] = "reload_empty",
}

SWEP.FakeVPShouldUseHand = false

SWEP.FakeViewBobBone = "ValveBiped.Bip01_R_Hand"
SWEP.FakeViewBobBaseBone = "ValveBiped.Bip01_R_Forearm"
SWEP.ViewPunchDiv = 50

SWEP.WepSelectIcon2 = Material("vgui/wep_jack_hmcd_smallpistol")
SWEP.IconOverride = "vgui/wep_jack_hmcd_smallpistol"

SWEP.CustomShell = "9x19"
SWEP.EjectAng = Angle(-45,0,90)
SWEP.punchmul = 1.5
SWEP.punchspeed = 3
SWEP.weight = 1

SWEP.ScrappersSlot = "Secondary"

SWEP.weaponInvCategory = 2
SWEP.ShellEject = "EjectBrass_9mm"
SWEP.Primary.ClipSize = 10
SWEP.Primary.DefaultClip = 10
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "9x19 mm Parabellum"
SWEP.Primary.Cone = 0
SWEP.Primary.Damage = 23
SWEP.Primary.Sound = {"zcitysnd/sound/weapons/firearms/hndg_beretta92fs/beretta92_fire1.wav", 75, 90, 100}
SWEP.SupressedSound = {"zcitysnd/sound/weapons/m45/m45_suppressed_fp.wav", 65, 90, 100}
SWEP.Primary.SoundEmpty = {"zcitysnd/sound/weapons/makarov/handling/makarov_empty.wav", 75, 100, 105, CHAN_WEAPON, 2}
SWEP.Primary.Force = 23
SWEP.Primary.Wait = PISTOLS_WAIT
SWEP.ReloadTime = 2
SWEP.ReloadSoundes = {
	"none",
	"weapons/tfa_ins2/usp_tactical/magout.wav",
	"weapons/tfa_ins2/browninghp/magin.wav",
	"pwb/weapons/fnp45/sliderelease.wav",
	"none",
	"none"
}
SWEP.DeploySnd = {"homigrad/weapons/draw_pistol.mp3", 55, 100, 110}
SWEP.HolsterSnd = {"homigrad/weapons/holster_pistol.mp3", 55, 100, 110}
SWEP.HoldType = "revolver"
SWEP.ZoomPos = Vector(-3, 0.5739, 4.4989)
SWEP.SprayRand = {Angle(-0.03, -0.03, 0), Angle(-0.05, 0.03, 0)}
SWEP.Ergonomics = 1.3
SWEP.Penetration = 7
SWEP.WorldPos = Vector(-0.1, -0.7, -0.5)
SWEP.WorldAng = Angle(0, 0, 0)

SWEP.LocalMuzzlePos = Vector(10.018,0.603,3.736)
SWEP.LocalMuzzleAng = Angle(0.2,0.0,0)
SWEP.WeaponEyeAngles = Angle(0,0,0)

SWEP.handsAng = Angle(-1, 10, 0)
SWEP.UseCustomWorldModel = true
SWEP.attPos = Vector(0, 0, 0)
SWEP.attAng = Angle(-0.125, -0.1, 0)
SWEP.lengthSub = 5
SWEP.DistSound = "m9/m9_dist.wav"
SWEP.holsteredBone = "ValveBiped.Bip01_R_Thigh"
SWEP.holsteredPos = Vector(0, -2, -1)
SWEP.holsteredAng = Angle(0, 20, 30)
SWEP.shouldntDrawHolstered = true
SWEP.availableAttachments = {
	barrel = {
		[1] = {"supressor6", Vector(0,0,0), {}},
		[2] = {"supressor4", Vector(0,0.1,0), {}},
		["mount"] = Vector(-0.1,0.33,0.03),
	},
}

SWEP.stupidgun = true

local function applySkinRulesToModel(model, rules, previousIndices)
	if not IsValid(model) then return {} end
	previousIndices = previousIndices or {}
	for _, idx in ipairs(previousIndices) do
		model:SetSubMaterial(idx, "")
	end

	local materials = model:GetMaterials() or {}
	local applied = {}
	local matched = {}
	for matIndex, matName in ipairs(materials) do
		local lowerMat = string.lower(matName or "")
		for _, rule in ipairs(rules) do
			if string.find(lowerMat, rule[1], 1, true) then
				model:SetSubMaterial(matIndex - 1, rule[2])
				applied[#applied + 1] = matIndex - 1
				matched[matIndex - 1] = true
				break
			end
		end
	end

	if istable(rules) and rules[1] and isstring(rules[1][2]) and rules[1][2] ~= "" then
		local fallbackMat = rules[1][2]
		for matIndex = 1, #materials do
			local subIdx = matIndex - 1
			if not matched[subIdx] then
				model:SetSubMaterial(subIdx, fallbackMat)
				applied[#applied + 1] = subIdx
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

SWEP.RHandPos = Vector(3, -1, 0)
SWEP.LHandPos = false

--local to head
SWEP.RHPos = Vector(10,-4.5,3)
SWEP.RHAng = Angle(0,-5,90)
--local to rh
SWEP.LHPos = Vector(-1.2,-1.4,-2.8)
SWEP.LHAng = Angle(5,9,-100)

local finger1 = Angle(-25,10,25)
local finger2 = Angle(0,25,0)
local finger3 = Angle(31,1,-25)
local finger4 = Angle(-10,-5,-5)
local finger5 = Angle(0,-65,-15)
local finger6 = Angle(15,-5,-15)

function SWEP:AnimHoldPost()
	--self:BoneSet("r_finger0", vector_zero, finger6)
	--self:BoneSet("l_finger0", vector_zero, finger1)
    --self:BoneSet("l_finger02", vector_zero, finger2)
	--self:BoneSet("l_finger1", vector_zero, finger3)
	--self:BoneSet("r_finger1", vector_zero, finger4)
	--self:BoneSet("r_finger11", vector_zero, finger5)
end
SWEP.ShootAnimMul = 4


function SWEP:DrawPost()
	local wep = self:GetWM()
	if CLIENT and IsValid(wep) then
		self.shooanim = LerpFT(0.4,self.shooanim or 0,(self:Clip1() > 0 or self.reload) and 0 or 1)
		wep:ManipulateBonePosition(0,Vector(-1.4*self.shooanim ,0 ,0 ),false)
	end
end

--RELOAD ANIMS PISTOL

SWEP.ReloadAnimLH = {
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(-3,-1,-5),
	Vector(-12,1,-22),
	Vector(-12,1,-22),
	Vector(-12,1,-22),
	Vector(-12,1,-22),
	Vector(-2,-1,-3),
	"fastreload",
	Vector(0,0,0),
	"reloadend",
	"reloadend",
}
SWEP.ReloadAnimLHAng = {
	Angle(0,0,0),
	Angle(0,0,0),
	Angle(30,-10,0),
	Angle(60,-20,0),
	Angle(70,-40,0),
	Angle(90,-30,0),
	Angle(40,-20,0),
	Angle(0,0,0),
	Angle(0,0,0),
	Angle(0,0,0),
	Angle(0,0,0),
}

SWEP.ReloadAnimRH = {
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(0,0,0),
	Vector(-2,0,0),
	Vector(-1,0,0),
	Vector(0,0,0)
}
SWEP.ReloadAnimRHAng = {
	Angle(0,0,0),
	Angle(0,0,0),
	Angle(0,0,0),
	Angle(0,0,0),
	Angle(0,0,0),
	Angle(0,0,0),
	Angle(0,0,0),
	Angle(0,0,0),
	Angle(0,0,0),
	Angle(0,0,0),
	Angle(15,2,20),
	Angle(15,2,20),
	Angle(0,0,0)
}
SWEP.ReloadAnimWepAng = {
	Angle(0,0,0),
	Angle(5,15,15),
	Angle(-5,21,14),
	Angle(-5,21,14),
	Angle(5,20,13),
	Angle(5,22,13),
	Angle(1,22,13),
	Angle(1,21,13),
	Angle(2,22,12),
	Angle(-5,21,16),
	Angle(-5,22,14),
	Angle(-4,23,13),
	Angle(7,22,8),
	Angle(7,12,3),
	Angle(2,6,1),
	Angle(0,0,0)
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
