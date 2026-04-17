
hg.achievements = hg.achievements or {}
hg.achievements.achievements_data = hg.achievements.achievements_data or {}
hg.achievements.achievements_data.player_achievements = hg.achievements.achievements_data.player_achievements or {}
hg.achievements.achievements_data.created_achevements = {}
hg.achievements.local_cache_file = hg.achievements.local_cache_file or "meleecity_achievements_cache.txt"
hg.achievements.local_cache_data = hg.achievements.local_cache_data or {}
hg.achievements.SqlActive = hg.achievements.SqlActive or false

local function getSteamID64(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return nil end
    local steamID64 = ply:SteamID64()
    if not isstring(steamID64) or steamID64 == "" then return nil end
    return steamID64
end

local function readTableSafe(str)
    if not isstring(str) or str == "" then return {} end
    local parsed = util.JSONToTable(str)
    if not istable(parsed) then return {} end
    return parsed
end

local function sanitizeAchievementTable(tbl)
    local clean = {}
    if not istable(tbl) then return clean end
    for key, value in pairs(tbl) do
        if isstring(key) and istable(value) and isnumber(value.value) and value.value == value.value and value.value ~= math.huge and value.value ~= -math.huge then
            clean[key] = {value = value.value}
        end
    end
    return clean
end

local function mergeAchievementTables(primary, secondary)
    local merged = sanitizeAchievementTable(primary)
    local second = sanitizeAchievementTable(secondary)
    for key, value in pairs(second) do
        if not merged[key] then
            merged[key] = {value = value.value}
        else
            merged[key].value = math.max(merged[key].value or 0, value.value or 0)
        end
    end
    return merged
end

local function loadLocalCache()
    local raw = file.Read(hg.achievements.local_cache_file, "DATA")
    local parsed = readTableSafe(raw)
    hg.achievements.local_cache_data = {}
    for steamID64, ach in pairs(parsed) do
        if isstring(steamID64) then
            hg.achievements.local_cache_data[steamID64] = sanitizeAchievementTable(ach)
        end
    end
end

local function saveLocalCache()
    file.Write(hg.achievements.local_cache_file, util.TableToJSON(hg.achievements.local_cache_data, true) or "{}")
end

loadLocalCache()

local function updatePlayer(ply)
    local steamID64 = getSteamID64(ply)
    if not steamID64 then return end
    local name = ply:Name()
    local localData = sanitizeAchievementTable(hg.achievements.local_cache_data[steamID64] or {})
    hg.achievements.local_cache_data[steamID64] = localData

    if not hg.achievements.SqlActive then
        hg.achievements.achievements_data.player_achievements[steamID64] = table.Copy(localData)
        return
    end

	local query = mysql:Select("hg_achievements")
		query:Select("achievements")
		query:Where("steamid", steamID64)
		query:Callback(function(result)
			if (IsValid(ply) and istable(result) and #result > 0 and result[1].achievements) then
                local sqlData = sanitizeAchievementTable(readTableSafe(result[1].achievements))
                local merged = mergeAchievementTables(sqlData, localData)
				local updateQuery = mysql:Update("hg_achievements")
					updateQuery:Update("steam_name", name)
                    updateQuery:Update("achievements", util.TableToJSON(merged))
					updateQuery:Where("steamid", steamID64)
				updateQuery:Execute()

                hg.achievements.achievements_data.player_achievements[steamID64] = merged
                hg.achievements.local_cache_data[steamID64] = table.Copy(merged)
                saveLocalCache()
			else
                local merged = table.Copy(localData)
				local insertQuery = mysql:Insert("hg_achievements")
					insertQuery:Insert("steamid", steamID64)
					insertQuery:Insert("steam_name", name)
					insertQuery:Insert("achievements", util.TableToJSON(merged))
				insertQuery:Execute()

				hg.achievements.achievements_data.player_achievements[steamID64] = merged
                hg.achievements.local_cache_data[steamID64] = table.Copy(merged)
                saveLocalCache()
			end
		end)
	query:Execute()
end

hook.Add("DatabaseConnected", "AchievementsCreateData", function()
	local query

	query = mysql:Create("hg_achievements")
		query:Create("steamid", "VARCHAR(20) NOT NULL")
		query:Create("steam_name", "VARCHAR(32) NOT NULL")
        query:Create("achievements", "TEXT NOT NULL")
		query:PrimaryKey("steamid")
	query:Execute()

    hg.achievements.SqlActive = true

    print("Achievements SQL database connected.")

    for i, ply in ipairs(player.GetAll()) do
        updatePlayer(ply)
    end
end)

hook.Add( "PlayerInitialSpawn","hg_Exp_OnInitSpawn", updatePlayer)
hook.Add("PlayerDisconnected", "savevalues", function(ply)
    hg.achievements.SaveToLocal(ply)
    if not hg.achievements.SqlActive then return end
    hg.achievements.SaveToSQL(ply)
end)

hook.Add("ShutDown", "hg_achievements_save_all", function()
    hg.achievements.SavePlayerAchievements()
end)

function hg.achievements.SaveToSQL(ply, data)
    if not hg.achievements.SqlActive then return end

    local steamID64 = getSteamID64(ply)
    if not steamID64 then return end
    local name = ply:Name()
    local cleanData = sanitizeAchievementTable(data or hg.achievements.GetPlayerAchievements(ply) or {})
    local updateQuery = mysql:Update("hg_achievements")
        updateQuery:Update("achievements", util.TableToJSON(cleanData))
        updateQuery:Update("steam_name", name)
        updateQuery:Where("steamid", steamID64)
    updateQuery:Execute()
end

function hg.achievements.SaveToLocal(ply, data)
    local steamID64 = getSteamID64(ply)
    if not steamID64 then return end
    hg.achievements.local_cache_data[steamID64] = sanitizeAchievementTable(data or hg.achievements.GetPlayerAchievements(ply) or {})
    saveLocalCache()
end

function hg.achievements.SavePlayerAchievements()
    for k, ply in player.Iterator() do
        hg.achievements.SaveToLocal(ply)
        if hg.achievements.SqlActive then
            hg.achievements.SaveToSQL(ply)
        end
    end
end

local replacement_img = "homigrad/vgui/models/star.png"

function hg.achievements.CreateAchievementType(key, needed_value, start_value, description, name, img, showpercent)
    img = img or replacement_img
    hg.achievements.achievements_data.created_achevements[key] = {
        start_value = start_value,
        needed_value = needed_value,
        description = description,
        name = name,
        img = img,
        key = key,
        showpercent = showpercent,
    }
end


function hg.achievements.GetAchievements()
    return hg.achievements.achievements_data.created_achevements
end


function hg.achievements.GetAchievementInfo(key)
    return hg.achievements.achievements_data.created_achevements[key]
end


function hg.achievements.GetPlayerAchievements(ply)
    local steamID = getSteamID64(ply)
    if not steamID then return {} end
    hg.achievements.achievements_data.player_achievements[steamID] = hg.achievements.achievements_data.player_achievements[steamID] or {}
    return hg.achievements.achievements_data.player_achievements[steamID]
end


function hg.achievements.GetPlayerAchievement(ply, key)
    local steamID = getSteamID64(ply)
    if not steamID then return {} end
    hg.achievements.achievements_data.player_achievements[steamID] = hg.achievements.achievements_data.player_achievements[steamID] or {}
    return hg.achievements.achievements_data.player_achievements[steamID][key] or {}
end


local function isAchievementCompleted(ply, key, val)
    local ach = hg.achievements.achievements_data.created_achevements[key]
    if not ach then return false end
    local prev = hg.achievements.GetPlayerAchievement(ply, key).value or 0
    return prev < ach.needed_value and val >= ach.needed_value
end

util.AddNetworkString("hg_NewAchievement")
util.AddNetworkString("hg_AchievementState")

local function sendAchievementState(ply, key, val)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    net.Start("hg_AchievementState")
        net.WriteString(key)
        net.WriteFloat(val)
    net.Send(ply)
end

function hg.achievements.SetPlayerAchievement(ply, key, val)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    if not isstring(key) or key == "" then return false end
    if not isnumber(val) then return false end
    if val ~= val or val == math.huge or val == -math.huge then return false end

    local ach = hg.achievements.GetAchievementInfo(key)
    if not istable(ach) then return false end

    local steamID = getSteamID64(ply)
    if not steamID then return false end
    local startValue = isnumber(ach.start_value) and ach.start_value or 0
    local neededValue = isnumber(ach.needed_value) and ach.needed_value or 0
    local safeVal = math.Clamp(val, math.min(0, startValue), neededValue)

    print("Triggered achievement for player " .. ply:Name() .. " ; " .. ply:SteamID() .. ": " .. key .. ", value " .. tostring(safeVal))
    hg.achievements.achievements_data.player_achievements[steamID] = hg.achievements.achievements_data.player_achievements[steamID] or {}
    local playerAchievements = hg.achievements.achievements_data.player_achievements[steamID]
    playerAchievements[key] = playerAchievements[key] or {}

    if isAchievementCompleted(ply, key, safeVal) then
        net.Start("hg_NewAchievement")
            net.WriteString(ach.name)
            net.WriteString(ach.img)
        net.Send(ply)
        if key == "remington_expertise" and hg.skins and hg.skins.UnlockSkin then
            hg.skins.UnlockSkin(ply, "shinku_ryu", true)
        elseif key == "glock_expertise" and hg.skins and hg.skins.UnlockSkin then
            hg.skins.UnlockSkin(ply, "indigo", true)
        elseif key == "bloodhound" and hg.skins and hg.skins.UnlockSkin then
            hg.skins.UnlockSkin(ply, "bloodhound", true)
        elseif key == "legacy" and hg.skins and hg.skins.UnlockSkin then
            hg.skins.UnlockSkin(ply, "legacy", true)
        elseif key == "midas_touch" and hg.skins and hg.skins.UnlockSkin then
            hg.skins.UnlockSkin(ply, "midas_touch", true)
        elseif key == "ar_expertise" and hg.skins and hg.skins.UnlockSkin then
            hg.skins.UnlockSkin(ply, "iconic", true)
        elseif key == "savior" and hg.skins and hg.skins.UnlockSkin then
            hg.skins.UnlockSkin(ply, "nickel", true)
        elseif key == "m9_expertise" and hg.skins and hg.skins.UnlockSkin then
            hg.skins.UnlockSkin(ply, "aegis", true)
        elseif key == "kar98k_expertise" and hg.skins and hg.skins.UnlockSkin then
            hg.skins.UnlockSkin(ply, "birch_bark", true)
        end
    end

    playerAchievements[key].value = safeVal
    sendAchievementState(ply, key, safeVal)
    hg.achievements.SaveToLocal(ply, playerAchievements)
    if hg.achievements.SqlActive then
        hg.achievements.SaveToSQL(ply, playerAchievements)
    end
    return true
end

function hg.achievements.AddPlayerAchievement(ply, key, val)
    local ach = hg.achievements.GetPlayerAchievement(ply, key)
    local ach_info = hg.achievements.GetAchievementInfo(key)
    if not ach_info then return end
    if not isnumber(val) then return end

    hg.achievements.SetPlayerAchievement(ply, key, math.Approach(ach.value or ach_info.start_value, ach_info.needed_value, val))
end

util.AddNetworkString("req_ach")

net.Receive("req_ach", function(len, ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if (ply.ach_cooldown or 0) > CurTime() then return end
    ply.ach_cooldown = CurTime() + 2
    net.Start("req_ach")
        net.WriteTable(hg.achievements.GetAchievements())
        net.WriteTable(hg.achievements.GetPlayerAchievements(ply))
    net.Send(ply)
end)

hg.achievements.CreateAchievementType(
    "remington_expertise",
    100,
    0,
    "Get 100 kills with the Remington 870.",
    "Remington Expertise",
    nil,
    true
)

hg.achievements.CreateAchievementType(
    "glock_expertise",
    100,
    0,
    "Get 100 kills with Glock 17, Glock 18C, or Glock 26.",
    "Glock Expertise",
    nil,
    true
)

hg.achievements.CreateAchievementType(
    "bloodhound",
    100,
    0,
    "Get 100 kills with the SOG knife.",
    "Bloodhound",
    nil,
    true
)

hg.achievements.CreateAchievementType(
    "legacy",
    100,
    0,
    "Get 100 kills with the Pocket Knife.",
    "Legacy",
    nil,
    true
)

hg.achievements.CreateAchievementType(
    "midas_touch",
    1000,
    0,
    "Get 1000 kills with the PKM.",
    "midas touch",
    nil,
    true
)

hg.achievements.CreateAchievementType(
    "ar_expertise",
    50,
    0,
    "Get 50 kills with the AR-15 or M4A1.",
    "AR Expertise",
    nil,
    true
)

hg.achievements.CreateAchievementType(
    "savior",
    100,
    0,
    "Get 100 kills with the Beretta PX4.",
    "Savior",
    nil,
    true
)

hg.achievements.CreateAchievementType(
    "m9_expertise",
    100,
    0,
    "Get 100 kills with the Beretta M9.",
    "m9 expertise",
    nil,
    true
)

hg.achievements.CreateAchievementType(
    "kar98k_expertise",
    100,
    0,
    "Get 100 kills with the Karabiner 98k.",
    "kar98k expertise",
    nil,
    true
)

hook.Add("PlayerDeath", "hg_achievement_remington_expertise", function(victim, inflictor, attacker)
    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    if attacker == victim then return end

    local class = ""
    local activeWep = attacker:GetActiveWeapon()
    if IsValid(activeWep) then
        class = activeWep:GetClass() or ""
    end

    if class ~= "weapon_remington870" and IsValid(inflictor) then
        class = inflictor:GetClass() or class
    end

    if class ~= "weapon_remington870" then return end
    hg.achievements.AddPlayerAchievement(attacker, "remington_expertise", 1)
end)

hook.Add("PlayerDeath", "hg_achievement_glock_expertise", function(victim, inflictor, attacker)
    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    if attacker == victim then return end

    local function isGlockWeapon(wep)
        if not IsValid(wep) then return false end
        local class = wep:GetClass() or ""
        if class == "weapon_glock17" or class == "weapon_glock18c" or class == "weapon_glock26" then
            return true
        end
        if isstring(wep.Base) and wep.Base == "weapon_glock17" then
            return true
        end
        local t = weapons.GetStored(class)
        if istable(t) and isstring(t.Base) and t.Base == "weapon_glock17" then
            return true
        end
        return false
    end

    local activeWep = attacker:GetActiveWeapon()
    if isGlockWeapon(activeWep) or isGlockWeapon(inflictor) then
        hg.achievements.AddPlayerAchievement(attacker, "glock_expertise", 1)
    end
end)

hook.Add("PlayerDeath", "hg_achievement_bloodhound", function(victim, inflictor, attacker)
    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    if attacker == victim then return end

    local class = ""
    local activeWep = attacker:GetActiveWeapon()
    if IsValid(activeWep) then
        class = activeWep:GetClass() or ""
    end

    if class ~= "weapon_sogknife" and IsValid(inflictor) then
        class = inflictor:GetClass() or class
    end

    if class ~= "weapon_sogknife" then return end
    hg.achievements.AddPlayerAchievement(attacker, "bloodhound", 1)
end)

hook.Add("PlayerDeath", "hg_achievement_legacy", function(victim, inflictor, attacker)
    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    if attacker == victim then return end

    local class = ""
    local activeWep = attacker:GetActiveWeapon()
    if IsValid(activeWep) then
        class = activeWep:GetClass() or ""
    end

    if class ~= "weapon_pocketknife" and IsValid(inflictor) then
        class = inflictor:GetClass() or class
    end

    if class ~= "weapon_pocketknife" then return end
    hg.achievements.AddPlayerAchievement(attacker, "legacy", 1)
end)

hook.Add("PlayerDeath", "hg_achievement_midas_touch", function(victim, inflictor, attacker)
    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    if attacker == victim then return end

    local class = ""
    local activeWep = attacker:GetActiveWeapon()
    if IsValid(activeWep) then
        class = activeWep:GetClass() or ""
    end

    if class ~= "weapon_pkm" and IsValid(inflictor) then
        class = inflictor:GetClass() or class
    end

    if class ~= "weapon_pkm" then return end
    hg.achievements.AddPlayerAchievement(attacker, "midas_touch", 1)
end)

hook.Add("PlayerDeath", "hg_achievement_ar_expertise", function(victim, inflictor, attacker)
    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    if attacker == victim then return end

    local function isARWeapon(wep)
        if not IsValid(wep) then return false end
        local class = wep:GetClass() or ""
        if class == "weapon_ar15" or class == "weapon_m4a1" then
            return true
        end
        if isstring(wep.Base) and wep.Base == "weapon_ar15" then
            return true
        end
        local t = weapons.GetStored(class)
        if istable(t) and isstring(t.Base) and t.Base == "weapon_ar15" then
            return true
        end
        return false
    end

    local activeWep = attacker:GetActiveWeapon()
    if isARWeapon(activeWep) or isARWeapon(inflictor) then
        hg.achievements.AddPlayerAchievement(attacker, "ar_expertise", 1)
    end
end)

hook.Add("PlayerDeath", "hg_achievement_savior", function(victim, inflictor, attacker)
    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    if attacker == victim then return end

    local class = ""
    local activeWep = attacker:GetActiveWeapon()
    if IsValid(activeWep) then
        class = activeWep:GetClass() or ""
    end

    if class ~= "weapon_px4beretta" and IsValid(inflictor) then
        class = inflictor:GetClass() or class
    end

    if class ~= "weapon_px4beretta" then return end
    hg.achievements.AddPlayerAchievement(attacker, "savior", 1)
end)

hook.Add("PlayerDeath", "hg_achievement_m9_expertise", function(victim, inflictor, attacker)
    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    if attacker == victim then return end

    local class = ""
    local activeWep = attacker:GetActiveWeapon()
    if IsValid(activeWep) then
        class = activeWep:GetClass() or ""
    end

    if class ~= "weapon_m9beretta" and IsValid(inflictor) then
        class = inflictor:GetClass() or class
    end

    if class ~= "weapon_m9beretta" then return end
    hg.achievements.AddPlayerAchievement(attacker, "m9_expertise", 1)
end)

hook.Add("PlayerDeath", "hg_achievement_kar98k_expertise", function(victim, inflictor, attacker)
    if not IsValid(attacker) or not attacker:IsPlayer() then return end
    if attacker == victim then return end

    local class = ""
    local activeWep = attacker:GetActiveWeapon()
    if IsValid(activeWep) then
        class = activeWep:GetClass() or ""
    end

    if class ~= "weapon_kar98" and IsValid(inflictor) then
        class = inflictor:GetClass() or class
    end

    if class ~= "weapon_kar98" then return end
    hg.achievements.AddPlayerAchievement(attacker, "kar98k_expertise", 1)
end)

local function findPlayerByToken(token)
    if not isstring(token) or token == "" then return nil end
    token = string.Trim(token)
    if token == "" then return nil end

    for _, ply in ipairs(player.GetAll()) do
        if ply:SteamID64() == token or ply:SteamID() == token then
            return ply
        end
    end

    local lowerToken = string.lower(token)
    local found = nil
    for _, ply in ipairs(player.GetAll()) do
        local n = string.lower(ply:Name() or "")
        if string.find(n, lowerToken, 1, true) then
            if found then
                return nil
            end
            found = ply
        end
    end

    return found
end

concommand.Add("hg_grant_achievement", function(ply, _, args)
    if IsValid(ply) and not ply:IsSuperAdmin() then return end

    local targetToken = args[1]
    local achKey = args[2]
    local valueArg = args[3]

    if not isstring(targetToken) or targetToken == "" then return end
    if not isstring(achKey) or achKey == "" then return end

    if IsValid(ply) and (targetToken == "me" or targetToken == "^") then
        targetToken = ply:SteamID64()
    end

    local target = findPlayerByToken(targetToken)
    if not IsValid(target) or not target:IsPlayer() then return end

    local normalizedKey = string.lower(string.Trim(achKey)):gsub("[%s%-]+", "_")
    local achInfo = hg.achievements.GetAchievementInfo(achKey)
    if not istable(achInfo) then
        achInfo = hg.achievements.GetAchievementInfo(normalizedKey)
        if istable(achInfo) then
            achKey = normalizedKey
        end
    end
    if not istable(achInfo) then return end

    local value = tonumber(valueArg)
    if not isnumber(value) then
        value = achInfo.needed_value or 1
    end

    hg.achievements.SetPlayerAchievement(target, achKey, value)
end)
