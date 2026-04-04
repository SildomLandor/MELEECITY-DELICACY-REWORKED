if CLIENT then
    hook.Add("InitPostEntity", "PepperSpray_PatchConsciousness", function()
        if not hg or not hg.CalculateConsciousnessMul then return end
        local math_Clamp = math.Clamp
        hg.CalculateConsciousnessMul = function()
            local consciousness = 1
            local org = LocalPlayer().organism
            if org and org.consciousness then
                consciousness = consciousness * org.consciousness
                consciousness = consciousness * math_Clamp((org.blood or 5000) / 4000, 0.5, 1)
                consciousness = consciousness * math_Clamp((org.o2 and org.o2[1] or 100) / 20, 0.5, 1)
                consciousness = consciousness * (1 - (org.disorientation or 0) / 10)
            end
            return math_Clamp(((consciousness - 1) * 3 + 1), 0.4, 1)
        end
        print("[Pepperspray] Patched hg.CalculateConsciousnessMul (disorientation nil-safe)")
    end)
end
if SERVER then
    hook.Add("Think", "PepperSpray_InitDisorientation", function()
        for _, ply in ipairs(player.GetAll()) do
            if ply.organism and ply.organism.disorientation == nil then
                ply.organism.disorientation = 0
            end
        end
    end)
end

