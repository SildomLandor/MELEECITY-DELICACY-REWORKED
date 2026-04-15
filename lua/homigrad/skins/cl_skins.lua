hg.skins = hg.skins or {}
hg.skins.player_data = hg.skins.player_data or {unlocked = {}, equipped = {}}
hg.skins.definitions = hg.skins.definitions or {}
hg.skins.client_cache_file = hg.skins.client_cache_file or "meleecity_skins_client_cache.txt"

local function sanitizePlayerData(data)
    local out = {
        unlocked = {},
        equipped = {}
    }

    if not istable(data) then
        return out
    end

    if istable(data.unlocked) then
        for skinId, value in pairs(data.unlocked) do
            local validSkin = isstring(skinId) and value
            if validSkin and isfunction(hg.skins.GetSkinInfo) then
                validSkin = hg.skins.GetSkinInfo(skinId) ~= nil
            end
            if validSkin then
                out.unlocked[skinId] = true
            end
        end
    end

    if istable(data.equipped) then
        for weaponClass, skinId in pairs(data.equipped) do
            local validEquip = isstring(weaponClass) and isstring(skinId) and out.unlocked[skinId]
            if validEquip and isfunction(hg.skins.IsSkinCompatible) then
                validEquip = hg.skins.IsSkinCompatible(weaponClass, skinId)
            end
            if validEquip then
                out.equipped[weaponClass] = skinId
            end
        end
    end

    return out
end

local function saveClientCache()
    file.Write(hg.skins.client_cache_file, util.TableToJSON(hg.skins.player_data, true) or "{}")
end

local function loadClientCache()
    local raw = file.Read(hg.skins.client_cache_file, "DATA")
    if not isstring(raw) or raw == "" then return end
    local parsed = util.JSONToTable(raw)
    if not istable(parsed) then return end
    hg.skins.player_data = sanitizePlayerData(parsed)
end

function hg.skins.GetPlayerData()
    hg.skins.player_data = sanitizePlayerData(hg.skins.player_data)
    return hg.skins.player_data
end

function hg.skins.HasAnySkins()
    local data = hg.skins.GetPlayerData()
    for _ in pairs(data.unlocked) do
        return true
    end
    return false
end

function hg.skins.GetOwnedSkins()
    local data = hg.skins.GetPlayerData()
    local out = {}
    for skinId in pairs(data.unlocked) do
        local info = hg.skins.GetSkinInfo(skinId)
        if info then
            out[skinId] = info
        end
    end
    return out
end

function hg.skins.GetEquippedSkin(weaponClass)
    local data = hg.skins.GetPlayerData()
    return data.equipped[weaponClass]
end

function hg.skins.LoadSkins()
    if (hg.skins._nextRequest or 0) > CurTime() then return end
    hg.skins._nextRequest = CurTime() + 1
    net.Start("hg_skins_req")
    net.SendToServer()
end

function hg.skins.EquipSkin(weaponClass, skinId)
    if not isstring(weaponClass) or weaponClass == "" then return end
    if not isstring(skinId) or skinId == "" then return end
    net.Start("hg_skins_equip")
        net.WriteString(weaponClass)
        net.WriteString(skinId)
    net.SendToServer()
end

net.Receive("hg_skins_sync", function()
    local pdata = net.ReadTable()
    local defs = net.ReadTable()
    if istable(defs) then
        for skinId, info in pairs(defs) do
            hg.skins.definitions[skinId] = info
        end
    end
    hg.skins.player_data = sanitizePlayerData(pdata)
    saveClientCache()
    if IsValid(MainMenu) and MainMenu.UpdateSkinsPanelList then
        MainMenu:UpdateSkinsPanelList()
    end
    if IsValid(MainMenu) and IsValid(MainMenu.menuList) then
        MainMenu.menuList:InvalidateLayout(true)
    end
end)

loadClientCache()

hook.Add("InitPostEntity", "hg_skins_initial_load", function()
    timer.Simple(1, function()
        if not IsValid(LocalPlayer()) then return end
        hg.skins.LoadSkins()
    end)
end)
