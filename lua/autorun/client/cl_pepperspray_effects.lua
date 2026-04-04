local blackOverlayAlpha = 0

local function GetPepperSprayStrength(ply)
    local now = CurTime()
    local blindStart = ply:GetNWFloat("PS_BlindStartTime", 0)
    local blindEnd = ply:GetNWFloat("PS_BlindEndTime", 0)
    local recovStart = ply:GetNWFloat("PS_RecoveryStart", 0)
    local lingeringTint = ply:GetNWFloat("PS_LingeringTint", 0)
    local organism = ply.organism

    local lingeringAlpha = 0
    if lingeringTint > 0 and recovStart <= 0 then
        lingeringAlpha = math.Clamp(lingeringTint / 100, 0, 1) * 240
    end

    local blindAlpha = 0
    if blindEnd > now then
        local blindDuration = math.max(blindEnd - blindStart, 0.001)
        local blindProgress = math.Clamp((now - blindStart) / blindDuration, 0, 1)
        blindAlpha = Lerp(blindProgress, math.max(lingeringAlpha, 80), 255)
    end

    local organismBlindAlpha = 0
    if istable(organism) and organism.blindness ~= nil then
        local blindValue = tonumber(organism.blindness) or 1
        if blindValue <= 0.25 then
            organismBlindAlpha = 230
        else
            organismBlindAlpha = math.Clamp(blindValue, 0.4, 1) * 255
        end
    end

    local recoverAlpha = 0
    if recovStart > 0 and now - recovStart < 5 then
        recoverAlpha = (1 - math.Clamp((now - recovStart) / 5, 0, 1)) * 180
    end

    local targetAlpha = math.max(lingeringAlpha, blindAlpha, organismBlindAlpha, recoverAlpha)
    return math.Clamp(targetAlpha / 255, 0, 1)
end

hook.Add("HUDPaint", "PepperSprayVisuals", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then
        blackOverlayAlpha = Lerp(FrameTime() * 10, blackOverlayAlpha, 0)
        return
    end

    local targetStrength = GetPepperSprayStrength(ply)
    local targetAlpha = targetStrength * 255
    blackOverlayAlpha = Lerp(FrameTime() * 10, blackOverlayAlpha, targetAlpha)

    if blackOverlayAlpha <= 1 then return end

    surface.SetDrawColor(0, 0, 0, blackOverlayAlpha)
    surface.DrawRect(0, 0, ScrW(), ScrH())

    local pulse = math.sin(CurTime() * 8) * 0.3 + 0.7
    surface.SetDrawColor(0, 0, 0, blackOverlayAlpha * 0.35 * pulse)
    surface.DrawRect(0, 0, ScrW(), ScrH())
end)

hook.Add("RenderScreenspaceEffects", "PepperSprayVisualsBlur", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    local strength = math.max(GetPepperSprayStrength(ply), blackOverlayAlpha / 255)

    if strength > 0.1 then
        DrawToyTown(2, strength * 15 * (ScrH() / 1080))
    end
    if strength > 0.5 then
        local blurAmt = (strength - 0.5) * 2
        DrawMotionBlur(0.1, blurAmt * 0.8, 0.01)
    end
end)
