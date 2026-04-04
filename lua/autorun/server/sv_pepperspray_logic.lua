local SPRAY_THRESHOLD = 1.2
local BLIND_MULTIPLIER = 14
local BLIND_CAP = 80
local PAIN_TICK_DELAY = 0.9
local PS_IRRITATION_PHRASES = {
    "MY EYES!! FUCK!!",
    "WHAT THE FUCK- MY EYES!",
    "IT BURNS!! IT FUCKING BURNS!!",
    "I CAN'T SEE SHIT!!",
    "MY FACE IS ON FIRE!!",
    "AAGH- GET IT OFF!! GET IT OFF MY FACE!!",
    "FUCK FUCK FUCK MY EYES!!",
    "IT'S IN MY EYES! OH GOD IT BURNS!",
    "I CAN'T BREATHE- MY EYES- FUCK!",
    "SOMEONE HELP ME I CAN'T SEE!",
    "OH GOD MAKE IT STOP BURNING!",
    "WATER! I NEED WATER! MY EYES!!",
}
local PS_BLIND_PHRASES = {
    "I can't see... I can't see anything...",
    "Everything is dark... My eyes won't open...",
    "It still burns... even with my eyes closed...",
    "Why can't I open my eyes... Fuck...",
    "Am I blind? Oh god am I blind??",
    "The burning won't stop. I can't see shit.",
    "I can't even force my eyes open...",
    "Just darkness... and fire on my face...",
    "Please... I need water... My eyes...",
    "I'm completely blind. Shit. Shit. SHIT.",
}
local PS_RECOVERY_PHRASES = {
    "I think... I can see something...",
    "It's getting a bit better...",
    "My eyes still burn like hell...",
    "I can barely make things out...",
    "Never again... Never fucking again...",
    "My face still feels like it's on fire...",
    "Vision's coming back... slowly...",
    "That was the worst thing I've ever felt.",
}
hook.Add("Org Think", "PepperSprayRegression", function(ply, org, dt)
    org.disorientation = org.disorientation or 0
    if not ply:IsPlayer() then return end
    local exposure = ply:GetNWFloat("PS_Exposure", 0)
    local lastHit  = ply:GetNWFloat("PS_LastHitTime", 0)
    local blindEnd = ply:GetNWFloat("PS_BlindEndTime", 0)
    if lastHit > 0 and CurTime() - lastHit > 0.3 then
        local newExposure = math.Approach(exposure, 0, dt * 0.35)
        ply:SetNWFloat("PS_Exposure", newExposure)
    end
    if exposure >= SPRAY_THRESHOLD and blindEnd < CurTime() then
        local blindDuration = math.min(exposure * BLIND_MULTIPLIER, BLIND_CAP)
        local endTime = CurTime() + blindDuration
        ply:SetNWFloat("PS_BlindEndTime", endTime)
        ply:SetNWFloat("PS_BlindStartTime", CurTime())
        org.blindness = 0.1
    end
    if blindEnd > 0 and CurTime() >= blindEnd then
        org.blindness = nil
        ply:SetNWFloat("PS_BlindEndTime", 0)
        ply:SetNWFloat("PS_BlindStartTime", 0)
        ply:SetNWFloat("PS_RecoveryStart", CurTime())
    end
    if blindEnd > 0 and CurTime() < blindEnd then
        org.blindness = 0.1
    end
    local recovStart = ply:GetNWFloat("PS_RecoveryStart", 0)
    if recovStart > 0 and CurTime() - recovStart >= 5 then
        ply:SetNWFloat("PS_RecoveryStart", 0)
    end
    local tint = ply:GetNWFloat("PS_LingeringTint", 0)
    local tintDecay = (blindEnd > 0 and CurTime() < blindEnd) and 0 or (dt * 1.5)
    if org.disorientation > 0 then
        org.disorientation = math.Approach(org.disorientation, 0, dt * 0.08)
        if org.disorientation < 0.1 then
            org.disorientation = 0
        end
    end
    if tint > 0 then
        ply:SetNWFloat("PS_LingeringTint", math.Approach(tint, 0, tintDecay))
    end
    local recovStart = ply:GetNWFloat("PS_RecoveryStart", 0)
    blindEnd = ply:GetNWFloat("PS_BlindEndTime", 0)
    exposure = ply:GetNWFloat("PS_Exposure", 0)
    local isPhase1 = (exposure > 0.3 or tint > 0) and (blindEnd <= 0 or CurTime() >= blindEnd) and (recovStart <= 0 or CurTime() - recovStart >= 5)
    local isPhase2 = blindEnd > 0 and CurTime() < blindEnd
    local isPhase3 = recovStart > 0 and CurTime() - recovStart < 5
    if isPhase1 or isPhase2 then
        ply.PS_NextPainTick = ply.PS_NextPainTick or 0
        if CurTime() >= ply.PS_NextPainTick then
            local painAdd = isPhase2 and 0.3 or 0.12
            org.painadd = (org.painadd or 0) + painAdd
            ply.PS_NextPainTick = CurTime() + PAIN_TICK_DELAY
        end
    end
    if isPhase1 or isPhase2 or isPhase3 then
        ply.PS_NextCough = ply.PS_NextCough or 0
        if CurTime() >= ply.PS_NextCough then
            if hg and hg.organism and hg.organism.module and hg.organism.module.random_events then
                hg.organism.module.random_events.TriggerRandomEvent(ply, "Cough")
            else
                ply:EmitSound("ambient/voices/cough" .. math.random(1,4) .. ".wav", 75, 100)
            end
            ply.PS_NextCough = CurTime() + math.Rand(2.0, 4.5)
        end
    end
end)
local function ResetPepperSpray(ply)
    if not IsValid(ply) then return end
    ply:SetNWFloat("PS_Exposure", 0)
    ply:SetNWFloat("PS_LastHitTime", 0)
    ply:SetNWFloat("PS_BlindEndTime", 0)
    ply:SetNWFloat("PS_BlindStartTime", 0)
    ply:SetNWFloat("PS_RecoveryStart", 0)
    ply:SetNWFloat("PS_LingeringTint", 0)
    ply.PS_NextPainTick = 0
    if ply.organism then
        ply.organism.blindness = nil
    end
end
hook.Add("PlayerDeath", "PepperSprayResetOnDeath", ResetPepperSpray)
hook.Add("PlayerSpawn", "PepperSprayResetOnSpawn", ResetPepperSpray)
