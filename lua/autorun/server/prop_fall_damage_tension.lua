-- prop_fall_damage.lua

if not SERVER then return end

-- ======================
-- ⚙️ НАСТРОЙКИ
-- ======================

CreateConVar("pfd_enable", "1", FCVAR_ARCHIVE)

-- задержки (для Tension)
CreateConVar("pfd_tension_delay", "0.18", FCVAR_ARCHIVE)
CreateConVar("pfd_non_tension_delay", "0", FCVAR_ARCHIVE)

-- модель урона
CreateConVar("pfd_safe_speed", "450", FCVAR_ARCHIVE)   -- безопасная зона
CreateConVar("pfd_ramp_end", "900", FCVAR_ARCHIVE)     -- предел прочности
CreateConVar("pfd_soft_damage", "120", FCVAR_ARCHIVE)  -- мягкий урон
CreateConVar("pfd_hard_pow", "1.3", FCVAR_ARCHIVE)     -- резкость
CreateConVar("pfd_hard_mul", "0.2", FCVAR_ARCHIVE)     -- множитель
CreateConVar("pfd_mass_div", "60", FCVAR_ARCHIVE)      -- влияние массы

-- ======================
-- 🔍 ПРОВЕРКИ
-- ======================

local function IsTensionActive()
    local cv = GetConVar("tension_sv_enabled")
    return cv and cv:GetBool()
end

local function IsValidProp(ent)
    return IsValid(ent) and ent:GetClass() == "prop_physics"
end

-- ======================
-- 💥 РАСЧЁТ УРОНА
-- ======================

local function CalculateFallDamage(speed, fallSpeed, mass, inWater)
    local safeSpeed = GetConVar("pfd_safe_speed"):GetFloat()
    local rampEnd = GetConVar("pfd_ramp_end"):GetFloat()

    -- игнор слабых ударов
    if speed <= safeSpeed then return 0 end

    local t = math.Clamp((speed - safeSpeed) / (rampEnd - safeSpeed), 0, 1)

    -- плавный рост
    local smooth = t ^ 2.2

    local baseDamage = smooth * GetConVar("pfd_soft_damage"):GetFloat()

    -- усиление если падал вниз
    if fallSpeed > 0 then
        baseDamage = baseDamage * (1 + math.Clamp(fallSpeed / 1000, 0, 1))
    end

    -- сильный урон после предела
    if speed > rampEnd then
        local excess = speed - rampEnd

        local hardDamage =
            (excess ^ GetConVar("pfd_hard_pow"):GetFloat()) *
            GetConVar("pfd_hard_mul"):GetFloat()

        baseDamage = baseDamage + hardDamage
    end

    local damage = baseDamage * (mass / GetConVar("pfd_mass_div"):GetFloat())

    -- вода ослабляет урон
    if inWater then
        damage = damage / 3
    end

    -- отсечка мусора
    if damage < 20 then return 0 end

    return damage
end

-- ======================
-- ⏱ ОТЛОЖЕННОЕ РАЗРУШЕНИЕ
-- ======================

local function QueueBreak(prop, dmginfo, delay)
    if not IsValid(prop) then return end
    if prop._pfd_breakQueued then return end

    prop._pfd_breakQueued = true

    timer.Simple(delay, function()
        if not IsValid(prop) then return end
        prop._pfd_breakQueued = nil

        prop:TakeDamageInfo(dmginfo)
    end)
end

-- ======================
-- 🧠 ОСНОВНАЯ ЛОГИКА
-- ======================

hook.Add("OnEntityCreated", "PFD_Init", function(ent)
    timer.Simple(0, function()
        if not IsValidProp(ent) then return end

        ent:AddCallback("PhysicsCollide", function(prop, data)
            if not GetConVar("pfd_enable"):GetBool() then return end
            if not IsValidProp(prop) then return end
            if not data or not data.Speed then return end

            local phys = prop:GetPhysicsObject()
            if not IsValid(phys) then return end

            local velocity = data.OurOldVelocity or prop:GetVelocity()
            local fallSpeed = -velocity.z
            if fallSpeed < 0 then fallSpeed = 0 end

            local speed = data.Speed
            local mass = phys:GetMass()
            local inWater = prop:WaterLevel() > 0

            local damage = CalculateFallDamage(speed, fallSpeed, mass, inWater)
            if damage <= 0 then return end

            local dmginfo = DamageInfo()
            dmginfo:SetDamage(damage)
            dmginfo:SetDamageType(DMG_CRUSH)
            dmginfo:SetAttacker(game.GetWorld())
            dmginfo:SetInflictor(prop)
            dmginfo:SetDamagePosition(data.HitPos)

            local delay = 0

            if IsTensionActive() then
                delay = GetConVar("pfd_tension_delay"):GetFloat()
            else
                delay = GetConVar("pfd_non_tension_delay"):GetFloat()
            end

            -- даём Tension проиграть звук перед разрушением
            if delay > 0 then
                QueueBreak(prop, dmginfo, delay)
            else
                prop:TakeDamageInfo(dmginfo)
            end
        end)
    end)
end)