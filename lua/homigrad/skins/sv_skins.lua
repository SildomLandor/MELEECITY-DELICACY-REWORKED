hg.skins = hg.skins or {}
hg.skins.player_data = hg.skins.player_data or {}
hg.skins.local_cache_data = hg.skins.local_cache_data or {}
hg.skins.local_cache_file = hg.skins.local_cache_file or "meleecity_skins_cache.txt"
hg.skins.SqlActive = hg.skins.SqlActive or false

util.AddNetworkString("hg_skins_req")
util.AddNetworkString("hg_skins_sync")
util.AddNetworkString("hg_skins_equip")

local function getSteamID64(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return nil end
    local steamID64 = ply:SteamID64()
    if not isstring(steamID64) or steamID64 == "" then return nil end
    return steamID64
end

local function readTableSafe(raw)
    if not isstring(raw) or raw == "" then return {} end
    local parsed = util.JSONToTable(raw)
    if not istable(parsed) then return {} end
    return parsed
end

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
            if isstring(skinId) and value and hg.skins.GetSkinInfo(skinId) then
                out.unlocked[skinId] = true
            end
        end
    end

    if istable(data.equipped) then
        for weaponClass, skinId in pairs(data.equipped) do
            if isstring(weaponClass) and isstring(skinId) and hg.skins.IsSkinCompatible(weaponClass, skinId) and out.unlocked[skinId] then
                out.equipped[weaponClass] = skinId
            end
        end
    end

    return out
end

local function mergePlayerData(primary, secondary)
    local a = sanitizePlayerData(primary)
    local b = sanitizePlayerData(secondary)
    local out = sanitizePlayerData(a)

    for skinId in pairs(b.unlocked) do
        out.unlocked[skinId] = true
    end

    for weaponClass, skinId in pairs(a.equipped) do
        if out.unlocked[skinId] then
            out.equipped[weaponClass] = skinId
        end
    end

    for weaponClass, skinId in pairs(b.equipped) do
        if out.unlocked[skinId] then
            out.equipped[weaponClass] = skinId
        end
    end

    return out
end

local function saveLocalCache()
    file.Write(hg.skins.local_cache_file, util.TableToJSON(hg.skins.local_cache_data, true) or "{}")
end

local function loadLocalCache()
    local parsed = readTableSafe(file.Read(hg.skins.local_cache_file, "DATA"))
    hg.skins.local_cache_data = {}
    for steamID64, data in pairs(parsed) do
        if isstring(steamID64) then
            hg.skins.local_cache_data[steamID64] = sanitizePlayerData(data)
        end
    end
end

loadLocalCache()

local function getEquippedSkinForWeapon(ply, weaponClass)
    local steamID64 = getSteamID64(ply)
    if not steamID64 then return nil end
    hg.skins.player_data[steamID64] = hg.skins.player_data[steamID64] or {unlocked = {}, equipped = {}}
    return hg.skins.player_data[steamID64].equipped[weaponClass]
end

local function getSkinWeaponClasses(info)
    local out = {}
    if not istable(info) then return out end
    if isstring(info.weapon_class) and info.weapon_class ~= "" then
        out[#out + 1] = info.weapon_class
    end
    if istable(info.weapon_classes) then
        for _, class in ipairs(info.weapon_classes) do
            if isstring(class) and class ~= "" then
                out[#out + 1] = class
            end
        end
    end
    return out
end

local function weaponClassHasAnySkins(weaponClass)
    for _, skinInfo in pairs(hg.skins.GetSkinDefinitions()) do
        if istable(skinInfo) then
            for _, class in ipairs(getSkinWeaponClasses(skinInfo)) do
                if class == weaponClass then
                    return true
                end
            end
        end
    end
    return false
end

local function applySkinToWeapon(ply, wep)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not IsValid(wep) then return end
    local class = wep:GetClass()
    if not isstring(class) or class == "" then return end
    if not weaponClassHasAnySkins(class) then return end
    local ownerSteamID64 = getSteamID64(ply)
    if not ownerSteamID64 then return end

    if wep:GetNWBool("hg_skin_initialized", false) then
        local lockedOwner = wep:GetNWString("hg_skin_owner", "")
        if lockedOwner ~= "" and lockedOwner ~= ownerSteamID64 then
            return
        end

        local currentSkin = wep:GetNWString("hg_skin_id", "")
        if currentSkin ~= "" then
            return
        end
    end

    local skinId = getEquippedSkinForWeapon(ply, class) or ""
    if not isstring(skinId) then skinId = "" end
    if skinId ~= "" and not hg.skins.IsSkinCompatible(class, skinId) then
        skinId = ""
    end
    wep:SetNWString("hg_skin_id", skinId)
    wep:SetNWString("hg_skin_owner", ownerSteamID64)
    wep:SetNWBool("hg_skin_initialized", true)
end

local function applySkinsToPlayerWeapons(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    for _, wep in ipairs(ply:GetWeapons()) do
        applySkinToWeapon(ply, wep)
    end
end

local function sendSync(ply)
    local steamID64 = getSteamID64(ply)
    if not steamID64 then return end
    hg.skins.player_data[steamID64] = hg.skins.player_data[steamID64] or {unlocked = {}, equipped = {}}
    net.Start("hg_skins_sync")
        net.WriteTable(hg.skins.player_data[steamID64])
        net.WriteTable(hg.skins.GetSkinDefinitions())
    net.Send(ply)
end

function hg.skins.GetPlayerData(ply)
    local steamID64 = getSteamID64(ply)
    if not steamID64 then return {unlocked = {}, equipped = {}} end
    hg.skins.player_data[steamID64] = hg.skins.player_data[steamID64] or {unlocked = {}, equipped = {}}
    return hg.skins.player_data[steamID64]
end

function hg.skins.SaveToLocal(ply, data)
    local steamID64 = getSteamID64(ply)
    if not steamID64 then return end
    hg.skins.local_cache_data[steamID64] = sanitizePlayerData(data or hg.skins.GetPlayerData(ply))
    saveLocalCache()
end

function hg.skins.SaveToSQL(ply, data)
    if not hg.skins.SqlActive then return end
    local steamID64 = getSteamID64(ply)
    if not steamID64 then return end
    local pdata = sanitizePlayerData(data or hg.skins.GetPlayerData(ply))
    local updateQuery = mysql:Update("hg_skins")
        updateQuery:Update("steam_name", ply:Name())
        updateQuery:Update("skins_data", util.TableToJSON(pdata))
        updateQuery:Where("steamid", steamID64)
    updateQuery:Execute()
end

function hg.skins.SavePlayerSkins()
    for _, ply in player.Iterator() do
        local data = hg.skins.GetPlayerData(ply)
        hg.skins.SaveToLocal(ply, data)
        if hg.skins.SqlActive then
            hg.skins.SaveToSQL(ply, data)
        end
    end
end

function hg.skins.EquipSkin(ply, weaponClass, skinId)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    if not isstring(weaponClass) or weaponClass == "" then return false end
    local data = hg.skins.GetPlayerData(ply)

    if skinId == "" then
        data.equipped[weaponClass] = nil
    else
        if not isstring(skinId) or skinId == "" then return false end
        if not data.unlocked[skinId] then return false end
        if not hg.skins.IsSkinCompatible(weaponClass, skinId) then return false end
        data.equipped[weaponClass] = skinId
    end

    hg.skins.SaveToLocal(ply, data)
    if hg.skins.SqlActive then
        hg.skins.SaveToSQL(ply, data)
    end
    applySkinsToPlayerWeapons(ply)
    sendSync(ply)
    return true
end

function hg.skins.UnlockSkin(ply, skinId, autoEquip)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    if not isstring(skinId) or skinId == "" then return false end
    local info = hg.skins.GetSkinInfo(skinId)
    if not info then return false end

    local data = hg.skins.GetPlayerData(ply)
    local changed = not data.unlocked[skinId]
    data.unlocked[skinId] = true

    if autoEquip then
        for _, class in ipairs(getSkinWeaponClasses(info)) do
            if not data.equipped[class] then
                data.equipped[class] = skinId
                changed = true
            end
        end
    end

    if changed then
        hg.skins.SaveToLocal(ply, data)
        if hg.skins.SqlActive then
            hg.skins.SaveToSQL(ply, data)
        end
    end

    applySkinsToPlayerWeapons(ply)
    sendSync(ply)
    return changed
end

local function equipSkinGroup(ply, skinId, equip)
    local info = hg.skins.GetSkinInfo(skinId)
    if not info then return false end
    local data = hg.skins.GetPlayerData(ply)
    local changed = false

    if equip then
        if not data.unlocked[skinId] then return false end
        for _, class in ipairs(getSkinWeaponClasses(info)) do
            if hg.skins.IsSkinCompatible(class, skinId) then
                if data.equipped[class] ~= skinId then
                    data.equipped[class] = skinId
                    changed = true
                end
            end
        end
    else
        for _, class in ipairs(getSkinWeaponClasses(info)) do
            if data.equipped[class] == skinId then
                data.equipped[class] = nil
                changed = true
            end
        end
    end

    if changed then
        hg.skins.SaveToLocal(ply, data)
        if hg.skins.SqlActive then
            hg.skins.SaveToSQL(ply, data)
        end
    end
    applySkinsToPlayerWeapons(ply)
    sendSync(ply)
    return changed
end

local function backfillSkinsFromAchievements(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    if not hg or not hg.achievements then return false end
    if not hg.achievements.GetPlayerAchievement or not hg.achievements.GetAchievementInfo then return false end

    local changed = false
    for skinId, skinInfo in pairs(hg.skins.GetSkinDefinitions()) do
        if not istable(skinInfo) then continue end
        if not isstring(skinInfo.achievement_key) or skinInfo.achievement_key == "" then continue end

        local achInfo = hg.achievements.GetAchievementInfo(skinInfo.achievement_key)
        if not istable(achInfo) then continue end

        local ach = hg.achievements.GetPlayerAchievement(ply, skinInfo.achievement_key)
        local val = (istable(ach) and ach.value) or 0
        if not isnumber(val) then val = 0 end

        if val >= (achInfo.needed_value or 1) then
            if hg.skins.UnlockSkin(ply, skinId, true) then
                changed = true
            end
        end
    end

    return changed
end

local function updatePlayer(ply)
    local steamID64 = getSteamID64(ply)
    if not steamID64 then return end

    local localData = sanitizePlayerData(hg.skins.local_cache_data[steamID64] or {})
    hg.skins.local_cache_data[steamID64] = localData

    if not hg.skins.SqlActive then
        hg.skins.player_data[steamID64] = table.Copy(localData)
        timer.Simple(0, function()
            if not IsValid(ply) then return end
            backfillSkinsFromAchievements(ply)
            applySkinsToPlayerWeapons(ply)
            sendSync(ply)
        end)
        return
    end

    local query = mysql:Select("hg_skins")
        query:Select("skins_data")
        query:Where("steamid", steamID64)
        query:Callback(function(result)
            if not IsValid(ply) then return end
            local merged
            if istable(result) and #result > 0 and result[1].skins_data then
                local sqlData = sanitizePlayerData(readTableSafe(result[1].skins_data))
                merged = mergePlayerData(sqlData, localData)
                local updateQuery = mysql:Update("hg_skins")
                    updateQuery:Update("steam_name", ply:Name())
                    updateQuery:Update("skins_data", util.TableToJSON(merged))
                    updateQuery:Where("steamid", steamID64)
                updateQuery:Execute()
            else
                merged = table.Copy(localData)
                local insertQuery = mysql:Insert("hg_skins")
                    insertQuery:Insert("steamid", steamID64)
                    insertQuery:Insert("steam_name", ply:Name())
                    insertQuery:Insert("skins_data", util.TableToJSON(merged))
                insertQuery:Execute()
            end

            hg.skins.player_data[steamID64] = merged
            hg.skins.local_cache_data[steamID64] = table.Copy(merged)
            saveLocalCache()
            backfillSkinsFromAchievements(ply)
            applySkinsToPlayerWeapons(ply)
            sendSync(ply)
        end)
    query:Execute()
end

hook.Add("DatabaseConnected", "hg_skins_db_connected", function()
    local query = mysql:Create("hg_skins")
        query:Create("steamid", "VARCHAR(20) NOT NULL")
        query:Create("steam_name", "VARCHAR(32) NOT NULL")
        query:Create("skins_data", "TEXT NOT NULL")
        query:PrimaryKey("steamid")
    query:Execute()

    hg.skins.SqlActive = true

    for _, ply in ipairs(player.GetAll()) do
        updatePlayer(ply)
    end
end)

hook.Add("PlayerInitialSpawn", "hg_skins_player_init", function(ply)
    updatePlayer(ply)
end)

hook.Add("PlayerDisconnected", "hg_skins_player_disconnected", function(ply)
    local data = hg.skins.GetPlayerData(ply)
    hg.skins.SaveToLocal(ply, data)
    if hg.skins.SqlActive then
        hg.skins.SaveToSQL(ply, data)
    end
end)

hook.Add("ShutDown", "hg_skins_shutdown_save", function()
    hg.skins.SavePlayerSkins()
end)

hook.Add("PlayerSpawn", "hg_skins_spawn_apply", function(ply)
    timer.Simple(0, function()
        if not IsValid(ply) then return end
        applySkinsToPlayerWeapons(ply)
    end)
end)

hook.Add("WeaponEquip", "hg_skins_weapon_equip", function(wep, ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    timer.Simple(0, function()
        if not IsValid(wep) or not IsValid(ply) then return end
        applySkinToWeapon(ply, wep)
    end)
end)

hook.Add("PlayerSwitchWeapon", "hg_skins_switch_weapon", function(ply, oldWep, newWep)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if IsValid(newWep) then
        applySkinToWeapon(ply, newWep)
    end
end)

net.Receive("hg_skins_req", function(_, ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if (ply.hg_skins_req_cd or 0) > CurTime() then return end
    ply.hg_skins_req_cd = CurTime() + 1
    backfillSkinsFromAchievements(ply)
    sendSync(ply)
end)

net.Receive("hg_skins_equip", function(_, ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if (ply.hg_skins_equip_cd or 0) > CurTime() then return end
    ply.hg_skins_equip_cd = CurTime() + 0.2

    local weaponClass = net.ReadString()
    local skinId = net.ReadString()

    if not isstring(weaponClass) or #weaponClass > 64 then return end
    if not isstring(skinId) or #skinId > 64 then return end

    if weaponClass == "__group__" then
        local removeMode = string.StartWith(skinId, "none:")
        if removeMode then
            skinId = string.sub(skinId, 6)
        end
        if not isstring(skinId) or skinId == "" then return end
        equipSkinGroup(ply, skinId, not removeMode)
        return
    end

    if skinId == "none" then
        skinId = ""
    end

    hg.skins.EquipSkin(ply, weaponClass, skinId)
end)
