local healthModel
local blinkModel
local whiteMat = Material("models/debug/debugwhite")
local statusCircleMat = Material("sef_icons/statuseffectcircle.png", "smooth")
local statusIconCache = {}

local IND_SIZE_BASE = 120
local IND_SIZE_MAX = 170
local BACKDROP_OFFSET_X = -20
local BACKDROP_OFFSET_Y = 37
local ICONS_SCREEN_EDGE_MARGIN = 20
local ICONS_SCREEN_MARGIN_Y = 18
local PULSE_DURATION = 8
local BLINK_SCALE = Vector(1.05, 1.05, 1.05)
local BLINK_DURATION = 5
local FRACTURE_BLINK_SPEED = 10
local POS_VISIBLE_X = 0
local POS_HIDDEN_X = -400

local currentX = nil
local pulseStartTime = 0
local limbStates = {}
local boneCache = {}
local lastLifeState = nil
local iconsVisibility = 0
local iconsAppearTime = 0
local iconsTargetVisible = false
local cachedAfflictionIcons = {}

local limbBones = {
    lleg = "ValveBiped.Bip01_L_Thigh",
    rleg = "ValveBiped.Bip01_R_Thigh",
    larm = "ValveBiped.Bip01_L_UpperArm",
    rarm = "ValveBiped.Bip01_R_UpperArm"
}

local amputationBones = {
    lleg = "ValveBiped.Bip01_L_Calf",
    rleg = "ValveBiped.Bip01_R_Calf",
    larm = "ValveBiped.Bip01_L_Forearm",
    rarm = "ValveBiped.Bip01_R_Forearm"
}

local function ScreenScaleFixed(size)
    return size * (ScrH() / 480)
end

local function SetBoneScaleRecursive(ent, boneName, scale)
    local boneID = ent:LookupBone(boneName)
    if not boneID then return end
    
    ent:ManipulateBoneScale(boneID, scale)
    
    local children = ent:GetChildBones(boneID)
    for _, childID in pairs(children) do
        ent:ManipulateBoneScale(childID, scale)
    end
end

local function ScaleBoneAndChildren(ent, boneID, scale)
    ent:ManipulateBoneScale(boneID, scale)
    local children = ent:GetChildBones(boneID)
    for _, child in ipairs(children) do
        ScaleBoneAndChildren(ent, child, scale)
    end
end

local function InitBlinkModel(ent)
    ent:SetupBones()
    for i = 0, ent:GetBoneCount() - 1 do
        ent:ManipulateBoneScale(i, Vector(0, 0, 0))
    end
end

local function ResetModels(ply)
    if IsValid(healthModel) then
        if healthModel.accessories then
            for _, v in pairs(healthModel.accessories) do
                if IsValid(v) then v:Remove() end
            end
        end
        healthModel:Remove()
    end
    if IsValid(blinkModel) then
        blinkModel:Remove()
    end
    healthModel = nil
    blinkModel = nil
    limbStates = {}
    pulseStartTime = 0
    iconsVisibility = 0
    iconsAppearTime = 0
    iconsTargetVisible = false
    cachedAfflictionIcons = {}
end

local function DrawHealthAccessories(healthModel, ply)
    local accessories = ply:GetNetVar("Accessories")
    if not accessories then 
        if healthModel.accessories then
            for k, v in pairs(healthModel.accessories) do
                if IsValid(v) then v:Remove() end
            end
            healthModel.accessories = nil
        end
        return 
    end
    
    healthModel.accessories = healthModel.accessories or {}
    local accList = istable(accessories) and accessories or {accessories}
    local currentAccs = {}
    
    for _, accName in pairs(accList) do
        currentAccs[accName] = true
        local accessData = hg.Accessories[accName]
        if not accessData then continue end
        if accessData.norender then continue end
        
        local model = healthModel.accessories[accName]
        local isFemale = false
        if hg.Appearance.FuckYouModels and hg.Appearance.FuckYouModels[2][healthModel:GetModel()] then
            isFemale = true
        end
        
        if not IsValid(model) then
            local modelPath = isFemale and accessData.femmodel or accessData.model
            if not modelPath then continue end
            
            model = ClientsideModel(modelPath, RENDERGROUP_OTHER)
            model:SetNoDraw(true)
            model:SetModelScale(accessData[isFemale and "fempos" or "malepos"][3])
            
            local skin = accessData.skin
            if isfunction(skin) then skin = skin(healthModel) end
            model:SetSkin(skin or 0)
            
            model:SetBodyGroups(accessData.bodygroups or "")
            
            if accessData.bonemerge then
                model:AddEffects(EF_BONEMERGE)
            end
            
            if accessData.bSetColor then
                local col = ply:GetPlayerColor() or Vector(1,1,1)
                model:SetColor(col:ToColor())
            end
            
            if accessData.SubMat then
                model:SetSubMaterial(0, accessData.SubMat)
            end
            
            healthModel.accessories[accName] = model
        end
        
        local boneName = accessData.bone
        local bone = healthModel:LookupBone(boneName)
        
        if bone then
            local matrix = healthModel:GetBoneMatrix(bone)
            if matrix then
                local bonePos, boneAng = matrix:GetTranslation(), matrix:GetAngles()
                local posData = accessData[isFemale and "fempos" or "malepos"]
                local localPos, localAng = posData[1], posData[2]
                
                local pos, ang = LocalToWorld(localPos, localAng, bonePos, boneAng)
                
                model:SetRenderOrigin(pos)
                model:SetRenderAngles(ang)
                
                if model:GetParent() ~= healthModel then
                    model:SetParent(healthModel, bone)
                end
                
                model:DrawModel()
            end
        end
    end
    
    for name, model in pairs(healthModel.accessories) do
        if not currentAccs[name] then
            if IsValid(model) then model:Remove() end
            healthModel.accessories[name] = nil
        end
    end
end

local function GetOrgValueNumber(value)
    if type(value) == "number" then return value end
    if type(value) == "table" then
        if type(value[1]) == "number" then return value[1] end
        if type(value.cur) == "number" then return value.cur end
        if type(value.value) == "number" then return value.value end
    end
    return 0
end

local function GetStatusIcon(iconName)
    local cached = statusIconCache[iconName]
    if cached ~= nil then
        return cached or nil
    end

    local mat = Material("sef_icons/" .. iconName .. ".png", "smooth")
    if mat:IsError() then
        statusIconCache[iconName] = false
        return nil
    end

    statusIconCache[iconName] = mat
    return mat
end

local function CollectAfflictionIcons(ply, org)
    local icons = {}
    local seen = {}
    local function add(iconName, severity)
        severity = math.Clamp(severity or 0.5, 0.05, 1)
        if seen[iconName] then
            seen[iconName].severity = math.max(seen[iconName].severity, severity)
            return
        end
        local mat = GetStatusIcon(iconName)
        if not mat then return end
        local entry = {mat = mat, severity = severity}
        seen[iconName] = entry
        icons[#icons + 1] = entry
    end

    if not org then
        return icons
    end

    local wounds = ply.wounds or ply:GetNetVar("wounds")
    local arterialwounds = ply.arterialwounds or ply:GetNetVar("arterialwounds")
    local woundsCount = istable(wounds) and #wounds or 0
    local arterialCount = istable(arterialwounds) and #arterialwounds or 0

    if woundsCount > 0 then
        add("open-wound", math.min(1, woundsCount / 6))
    end

    if arterialCount > 0 then
        add("deepwound", math.min(1, 0.7 + arterialCount * 0.2))
    end

    local bleed = GetOrgValueNumber(org.bleed)
    if bleed > 0 then
        add("bleed", math.min(1, bleed / 8))
    end

    local hasBrokenLimb = (org.lleg and org.lleg >= 1) or (org.rleg and org.rleg >= 1) or (org.larm and org.larm >= 1) or (org.rarm and org.rarm >= 1)
    local hasDislocation = org.llegdislocation or org.rlegdislocation or org.larmdislocation or org.rarmdislocation or org.jawdislocation
    local hasAmputation = org.llegamputated or org.rlegamputated or org.larmamputated or org.rarmamputated or org.headamputated
    if hasBrokenLimb or hasDislocation or hasAmputation then
        local sev = hasAmputation and 1 or (hasDislocation and 0.65 or 0.5)
        add("vuln", sev)
    end

    local concussion = GetOrgValueNumber(org.concussion)
    if concussion > 0 then
        add("concussion", math.min(1, concussion))
    end

    if org.blindness then
        add("blind", 0.7)
    end

    local assimilated = GetOrgValueNumber(org.assimilated)
    if assimilated > 0 then
        add("wither", math.min(1, assimilated))
    end

    if org.incapacitated then
        add("incap", 1)
    end

    if org.berserkActive2 then
        add("bloodlust", 0.45)
    end

    if org.noradrenalineActive then
        add("haste", 0.45)
    end

    local despair = GetOrgValueNumber(org.despair)
    if despair > 0.25 then
        add("anagenthasdied", math.min(1, despair))
    end

    if org.critical then
        add("warning", 1)
    end

    if (not org.canmove) or GetOrgValueNumber(org.immobilization) > 0 then
        add("hindered", 0.65)
    end

    if GetOrgValueNumber(org.pain) > 60 or GetOrgValueNumber(org.shock) > 0.5 then
        add("stunned", math.min(1, math.max(GetOrgValueNumber(org.pain) / 120, GetOrgValueNumber(org.shock))))
    end

    if GetOrgValueNumber(org.CO) > 0.1 then
        add("poison-gas", math.min(1, GetOrgValueNumber(org.CO) / 4))
    end

    local o2 = GetOrgValueNumber(org.o2)
    if o2 > 0 and o2 < 20 then
        add("exhaust", math.min(1, (20 - o2) / 20))
    end

    local temperature = GetOrgValueNumber(org.temperature)
    if temperature > 39 then
        add("discharge", math.min(1, (temperature - 39) / 2))
    elseif temperature > 0 and temperature < 34.5 then
        add("frozen", math.min(1, (34.5 - temperature) / 3))
    end

    return icons
end

local function DrawAfflictionIcons(iconEntries, centerX, bottomY, visibility, appearTime, timeNow)
    if not iconEntries or #iconEntries == 0 or visibility <= 0.01 then return end

    local iconSize = math.max(math.floor(ScreenScaleFixed(26)), 18)
    local bgSize = math.max(math.floor(iconSize * 1.35), iconSize + 8)
    local spacing = math.max(math.floor(ScreenScaleFixed(2)), 1)
    local iconInset = math.floor((bgSize - iconSize) * 0.5)
    local horizontalSpace = ScrW() - ScreenScaleFixed(ICONS_SCREEN_EDGE_MARGIN) * 2
    local maxPerRow = math.max(1, math.floor((horizontalSpace + spacing) / (bgSize + spacing)))
    local rows = math.ceil(#iconEntries / maxPerRow)
    local appearFrac = math.Clamp((timeNow - (appearTime or timeNow)) / 0.35, 0, 1)
    local shakeMul = (1 - appearFrac) * visibility
    local baseAlpha = math.floor(255 * visibility)

    for row = 1, rows do
        local rowStart = (row - 1) * maxPerRow + 1
        local rowCount = math.min(maxPerRow, #iconEntries - rowStart + 1)
        local rowWidth = rowCount * bgSize + (rowCount - 1) * spacing
        local x = centerX - rowWidth * 0.5
        local y = bottomY - row * bgSize - (row - 1) * spacing

        if y < 0 then
            break
        end

        for col = 1, rowCount do
            local idx = rowStart + col - 1
            local entry = iconEntries[idx]
            local severity = entry.severity or 0.5
            local pulse = 1 + math.sin(timeNow * (4 + severity * 9) + idx * 1.4) * (0.05 + severity * 0.08) * visibility
            local shakeAmp = ScreenScaleFixed(2 + severity * 2) * shakeMul
            local shakeX = math.sin(timeNow * (95 + idx * 7)) * shakeAmp
            local shakeY = math.cos(timeNow * (110 + idx * 9)) * shakeAmp
            local drawX = x + (col - 1) * (bgSize + spacing)
            local drawY = y
            local centerDrawX = drawX + bgSize * 0.5 + shakeX
            local centerDrawY = drawY + bgSize * 0.5 + shakeY
            local bgDrawSize = bgSize * pulse
            local iconDrawSize = iconSize * pulse
            local bgAlpha = math.floor((160 + severity * 95) * visibility)

            surface.SetMaterial(statusCircleMat)
            surface.SetDrawColor(8, 8, 8, bgAlpha)
            surface.DrawTexturedRect(centerDrawX - bgDrawSize * 0.5, centerDrawY - bgDrawSize * 0.5, bgDrawSize, bgDrawSize)

            surface.SetMaterial(entry.mat)
            surface.SetDrawColor(255, 255, 255, baseAlpha)
            surface.DrawTexturedRect(centerDrawX - iconDrawSize * 0.5, centerDrawY - iconDrawSize * 0.5, iconDrawSize, iconDrawSize)
        end
    end
end

hook.Add("HUDPaint", "HG_HealthIndicator", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local alive = ply:Alive()
    if lastLifeState ~= alive then
        ResetModels(ply)
        lastLifeState = alive
    end
    
    if not alive then return end
    if gui.IsGameUIVisible() then return end
    
    if not IsValid(healthModel) then
        healthModel = ClientsideModel(ply:GetModel(), RENDERGROUP_OTHER)
        healthModel:SetNoDraw(true)
        healthModel:SetIK(false)
        local seq = healthModel:LookupSequence("idle_suitcase")
        if seq then
            healthModel:SetSequence(seq)
            healthModel:SetCycle(0)
        end
    end
    
    if not IsValid(blinkModel) then
        blinkModel = ClientsideModel(ply:GetModel(), RENDERGROUP_OTHER)
        blinkModel:SetNoDraw(true)
        blinkModel:SetIK(false)
        local seq = blinkModel:LookupSequence("idle_suitcase")
        if seq then
            blinkModel:SetSequence(seq)
            blinkModel:SetCycle(0)
        end
        InitBlinkModel(blinkModel)
    end

    if healthModel:GetModel() ~= ply:GetModel() then
        healthModel:SetModel(ply:GetModel())
        blinkModel:SetModel(ply:GetModel())
        
        local seq = healthModel:LookupSequence("idle_suitcase")
        if seq then
            healthModel:SetSequence(seq)
            healthModel:SetCycle(0)
        end
        local seq2 = blinkModel:LookupSequence("idle_suitcase")
        if seq2 then
            blinkModel:SetSequence(seq2)
            blinkModel:SetCycle(0)
        end

        InitBlinkModel(blinkModel)
        limbStates = {}
        
        if healthModel.accessories then
            for _, v in pairs(healthModel.accessories) do
                if IsValid(v) then v:Remove() end
            end
            healthModel.accessories = nil
        end
    end

    local consciousness = 1
    local otrub = false
    local org = ply.organism
    
    if org then
        if org.consciousness then consciousness = org.consciousness end
        if org.otrub then otrub = org.otrub end
    end
    
    local time = CurTime()
    local hasActiveLimbAffliction = false
    local admiring = ply:GetNWBool("mcd_admiring", false) and not ply.mcd_admire_local_cancel
    if org then
        for limb, boneName in pairs(limbBones) do
            local isAmputated = org[limb.."amputated"]
            local isBroken = (org[limb] and org[limb] >= 1)
            local isDislocated = org[limb.."dislocation"]
            if isAmputated or isBroken or isDislocated then
                hasActiveLimbAffliction = true
            end
            
            if not limbStates[limb] then
                limbStates[limb] = { 
                    amputated = false, 
                    blinking = false, 
                    blinkEnd = 0,
                    fractured = false
                }
            end
            
            local state = limbStates[limb]
            local ampBoneName = amputationBones[limb] or boneName
            
            if state.amputated and not isAmputated then
                state.amputated = false
                state.blinking = false
                local boneID = healthModel:LookupBone(ampBoneName)
                if boneID then ScaleBoneAndChildren(healthModel, boneID, Vector(1, 1, 1)) end
                local blinkBoneID = blinkModel:LookupBone(ampBoneName)
                if blinkBoneID then ScaleBoneAndChildren(blinkModel, blinkBoneID, Vector(0, 0, 0)) end
            end
            
            if state.fractured and not (isBroken or isDislocated) then
                state.fractured = false
                if not state.amputated then
                    local blinkBoneID = blinkModel:LookupBone(boneName)
                    if blinkBoneID then ScaleBoneAndChildren(blinkModel, blinkBoneID, Vector(0, 0, 0)) end
                    
                    local boneID = healthModel:LookupBone(boneName)
                    if boneID then ScaleBoneAndChildren(healthModel, boneID, Vector(1, 1, 1)) end
                end
            end

            if isAmputated then
                if state.fractured then
                     state.fractured = false
                     local blinkBoneID = blinkModel:LookupBone(boneName)
                     if blinkBoneID then ScaleBoneAndChildren(blinkModel, blinkBoneID, Vector(0, 0, 0)) end
                     
                     local boneID = healthModel:LookupBone(boneName)
                     if boneID then ScaleBoneAndChildren(healthModel, boneID, Vector(1, 1, 1)) end
                end

                if not state.amputated then
                    state.amputated = true
                    state.blinking = true
                    state.blinkEnd = time + BLINK_DURATION
                    pulseStartTime = time
                    
                    local boneID = healthModel:LookupBone(ampBoneName)
                    if boneID then ScaleBoneAndChildren(healthModel, boneID, Vector(0, 0, 0)) end
                    
                    local blinkBoneID = blinkModel:LookupBone(ampBoneName)
                    if blinkBoneID then ScaleBoneAndChildren(blinkModel, blinkBoneID, BLINK_SCALE) end
                end
                
                if state.blinking and time > state.blinkEnd then
                    state.blinking = false
                    local blinkBoneID = blinkModel:LookupBone(ampBoneName)
                    if blinkBoneID then ScaleBoneAndChildren(blinkModel, blinkBoneID, Vector(0, 0, 0)) end
                end
                
            elseif (isBroken or isDislocated) then
                if not state.fractured then
                    state.fractured = true
                    pulseStartTime = time
                    local blinkBoneID = blinkModel:LookupBone(boneName)
                    if blinkBoneID then ScaleBoneAndChildren(blinkModel, blinkBoneID, BLINK_SCALE) end
                    
                    local boneID = healthModel:LookupBone(boneName)
                    if boneID then ScaleBoneAndChildren(healthModel, boneID, Vector(0, 0, 0)) end
                end
            end
        end
    end
    
    local shouldShowIndicator = admiring and not otrub
    local targetX = shouldShowIndicator and POS_VISIBLE_X or POS_HIDDEN_X
    local targetXScaled = ScreenScaleFixed(targetX)
    
    if not currentX then currentX = ScreenScaleFixed(POS_HIDDEN_X) end
    currentX = Lerp(FrameTime() * 2, currentX, targetXScaled)

    local size = IND_SIZE_BASE
    
    local w, h = ScreenScaleFixed(size), ScreenScaleFixed(size)
    local y = ScrH() - h - ScreenScaleFixed(20)
    
    local camPos = Vector(95, 0, 65) 
    local lookAng = Angle(11, 180, 0)
    
    local renderX = currentX
    
    local SILHOUETTE_OFFSET_X = -15
    local SILHOUETTE_OFFSET_Y = 15
    
    local viewX = renderX + ScreenScaleFixed(SILHOUETTE_OFFSET_X)
    local viewY = y + ScreenScaleFixed(SILHOUETTE_OFFSET_Y)
    
    local modelOffset = Vector(0, 0, 0)
    
    local backdropX = currentX + ScreenScaleFixed(BACKDROP_OFFSET_X)
    local backdropY = y + ScreenScaleFixed(BACKDROP_OFFSET_Y)
    local backdropW = w * 0.92
    local backdropH = h * 0.92
    
    draw.RoundedBox(6, backdropX, backdropY, backdropW, backdropH, Color(0, 0, 0, 90))
    surface.SetDrawColor(120, 120, 120, 170)
    surface.DrawOutlinedRect(backdropX, backdropY, backdropW, backdropH, 1)
    
    if shouldShowIndicator then
        cachedAfflictionIcons = CollectAfflictionIcons(ply, org)
        if not iconsTargetVisible then
            iconsAppearTime = time
        end
    end

    iconsVisibility = Lerp(FrameTime() * 10, iconsVisibility, shouldShowIndicator and 1 or 0)
    iconsTargetVisible = shouldShowIndicator

    if iconsVisibility > 0.01 and #cachedAfflictionIcons > 0 then
        local iconsX = ScrW() * 0.5
        local iconsBottom = ScrH() - ScreenScaleFixed(ICONS_SCREEN_MARGIN_Y)
        DrawAfflictionIcons(cachedAfflictionIcons, iconsX, iconsBottom, iconsVisibility, iconsAppearTime, time)
    elseif not shouldShowIndicator and iconsVisibility <= 0.01 then
        cachedAfflictionIcons = {}
    end
    
    local camRenderX = viewX
    if camRenderX < 0 then
        local dist = camPos.x
        local fov = 50
        local visibleHeight = 2 * dist * math.tan(math.rad(fov) / 2)
        local unitsPerPixel = visibleHeight / h
        
        local pixelShift = camRenderX 
        local unitShift = pixelShift * unitsPerPixel 
        
        modelOffset = Vector(0, unitShift, 0)
        camRenderX = 0
    end
    
    cam.Start3D(camPos, lookAng, 50, camRenderX, viewY, w, h)
        render.SuppressEngineLighting(true)
        render.MaterialOverride(whiteMat)
        
        local col = math.Clamp(consciousness, 0, 1)
        render.SetColorModulation(col, col, col)
        
        healthModel:SetPos(modelOffset)
        healthModel:SetAngles(Angle(0, 0, 0))
        
        for i = 0, ply:GetNumBodyGroups() - 1 do
            healthModel:SetBodygroup(i, ply:GetBodygroup(i))
        end
        healthModel:SetSkin(ply:GetSkin())
        
        healthModel:SetupBones()
        healthModel:DrawModel()
        
        DrawHealthAccessories(healthModel, ply)
        
        local hasAmputationBlink = false
        local hasFractureBlink = false
        
        for _, state in pairs(limbStates) do
            if state.blinking then hasAmputationBlink = true end
            if state.fractured then hasFractureBlink = true end
        end
        
        if hasAmputationBlink then
            local val = (math.sin(time * 10) + 1) / 2
            render.SetColorModulation(val, 0, 0)
            
            if hasFractureBlink then
                for l, s in pairs(limbStates) do
                    if s.fractured then
                        local bID = blinkModel:LookupBone(limbBones[l])
                        if bID then ScaleBoneAndChildren(blinkModel, bID, Vector(0,0,0)) end
                    end
                end
            end
            
            blinkModel:SetPos(modelOffset)
            blinkModel:SetAngles(Angle(0, 0, 0))
            blinkModel:SetupBones()
            blinkModel:DrawModel()
            
            if hasFractureBlink then
                for l, s in pairs(limbStates) do
                    if s.fractured then
                        local bID = blinkModel:LookupBone(limbBones[l])
                        if bID then ScaleBoneAndChildren(blinkModel, bID, BLINK_SCALE) end
                    end
                end
            end
        end
        
        if hasFractureBlink then
            local val = (math.sin(time * FRACTURE_BLINK_SPEED) + 1) / 2
            render.SetColorModulation(val, 0, 0)
            
            if hasAmputationBlink then
                for l, s in pairs(limbStates) do
                    if s.blinking then
                        local ampBoneName = amputationBones[l] or limbBones[l]
                        local bID = blinkModel:LookupBone(ampBoneName)
                        if bID then ScaleBoneAndChildren(blinkModel, bID, Vector(0,0,0)) end
                    end
                end
            end
            
            blinkModel:SetPos(modelOffset)
            blinkModel:SetAngles(Angle(0, 0, 0))
            blinkModel:SetupBones()
            blinkModel:DrawModel()
            
            if hasAmputationBlink then
                for l, s in pairs(limbStates) do
                    if s.blinking then
                        local ampBoneName = amputationBones[l] or limbBones[l]
                        local bID = blinkModel:LookupBone(ampBoneName)
                        if bID then ScaleBoneAndChildren(blinkModel, bID, BLINK_SCALE) end
                    end
                end
            end
        end
        
        render.MaterialOverride(nil)
        render.SetColorModulation(1, 1, 1)
        render.SuppressEngineLighting(false)
    cam.End3D()
end)

hook.Add("OnRemove", "HG_CleanupHealthIndicator", function()
    if IsValid(healthModel) then healthModel:Remove() end
    if IsValid(blinkModel) then blinkModel:Remove() end
end)
