hg.skins = hg.skins or {}
hg.skins.definitions = hg.skins.definitions or {}

function hg.skins.RegisterSkin(id, data)
    if not isstring(id) or id == "" then return end
    if not istable(data) then return end
    if not isstring(data.name) or data.name == "" then return end
    local hasSingleClass = isstring(data.weapon_class) and data.weapon_class ~= ""
    local hasManyClasses = istable(data.weapon_classes) and #data.weapon_classes > 0
    if not hasSingleClass and not hasManyClasses then return end
    hg.skins.definitions[id] = data
end

function hg.skins.GetSkinInfo(id)
    if not isstring(id) then return nil end
    return hg.skins.definitions[id]
end

function hg.skins.GetSkinDefinitions()
    return hg.skins.definitions
end

function hg.skins.IsSkinCompatible(weaponClass, skinId)
    if not isstring(weaponClass) or weaponClass == "" then return false end
    local info = hg.skins.GetSkinInfo(skinId)
    if not info then return false end
    if isstring(info.weapon_class) and info.weapon_class ~= "" then
        return info.weapon_class == weaponClass
    end
    if istable(info.weapon_classes) then
        for _, class in ipairs(info.weapon_classes) do
            if class == weaponClass then
                return true
            end
        end
    end
    return false
end

hg.skins.RegisterSkin("shinku_ryu", {
    name = "Shinku Ryū",
    icon = "skinicons/remington1riyu.png",
    weapon_class = "weapon_remington870",
    achievement_key = "remington_expertise",
    material_rules = {
        {"870_wood", "magamed/guns/remington1/870_wood"},
        {"shotgun", "magamed/guns/remington1/shotgun"},
        {"870", "magamed/guns/remington1/870"}
    }
})

hg.skins.RegisterSkin("indigo", {
    name = "Indigo",
    icon = "skinicons/indigo.png",
    weapon_classes = {
        "weapon_glock17",
        "weapon_glock18c",
        "weapon_glock26"
    },
    achievement_key = "glock_expertise",
    material_rules = {
        {"glock", "magamed/guns/glock1/glock"}
    }
})

hg.skins.RegisterSkin("bloodhound", {
    name = "Tiger",
    icon = "skinicons/bloodhound.png",
    weapon_class = "weapon_sogknife",
    achievement_key = "bloodhound",
    material_rules = {
        {"sog_black", "magamed/melee/sog1/sog"},
        {"sog", "magamed/melee/sog1/sog"}
    }
})

hg.skins.RegisterSkin("legacy", {
    name = "Legacy",
    icon = "skinicons/legacy.png",
    weapon_class = "weapon_pocketknife",
    achievement_key = "legacy",
    material_rules = {
        {"knife", "magamed/melee/pocketknife1/texture"},
        {"swch", "magamed/melee/pocketknife1/texture"},
        {"s&wch", "magamed/melee/pocketknife1/texture"}
    }
})

hg.skins.RegisterSkin("midas_touch", {
    name = "Midas Touch",
    icon = "skinicons/midastouch.png",
    weapon_class = "weapon_pkm",
    achievement_key = "midas_touch",
    material_rules = {
        {"pkm_d", "magamed/guns/pkm/pkm_d"},
        {"mag_d", "magamed/guns/pkm/mag_d"},
        {"pkm", "magamed/guns/pkm/pkm_d"},
        {"mag", "magamed/guns/pkm/mag_d"}
    }
})

hg.skins.RegisterSkin("iconic", {
    name = "Iconic",
    icon = "skinicons/iconic.png",
    weapon_classes = {
        "weapon_ar15",
        "weapon_m4a1"
    },
    achievement_key = "ar_expertise",
    material_rules = {
        {"m16a2", "magamed/guns/m16/stalol/m16a2_basecolor_desatur"},
        {"stalol", "magamed/guns/m16/stalol/m16a2_basecolor_desatur"},
        {"receiver", "magamed/guns/m16/stalol/m16a2_basecolor_desatur"},
        {"m16_buffertube", "magamed/guns/m16/m16_buffertube"},
        {"m16_stock_carbine", "magamed/guns/m16/m16_stock_carbine"},
        {"m16_stock_endplate", "magamed/guns/m16/m16_stock_endplate"},
        {"m16_ris_handguard_short", "magamed/guns/m16/m16_ris_handguard_short"},
        {"m16_ris_rail", "magamed/guns/m16/m16_ris_rail"}
    }
})

hg.skins.RegisterSkin("nickel", {
    name = "nickel",
    icon = "skinicons/nickel.png",
    weapon_class = "weapon_px4beretta",
    achievement_key = "savior",
    material_rules = {
        {"map1", "magamed/guns/px4/map1_updated"},
        {"px4", "magamed/guns/px4/map1_updated"},
        {"beretta", "magamed/guns/px4/map1_updated"}
    }
})

hg.skins.RegisterSkin("aegis", {
    name = "aegis",
    icon = "skinicons/aegis.png",
    weapon_class = "weapon_m9beretta",
    achievement_key = "m9_expertise",
    material_rules = {
        {"m9", "magamed/guns/m9/weapon_m9_dm"},
        {"beretta", "magamed/guns/m9/weapon_m9_dm"}
    }
})

hg.skins.RegisterSkin("birch_bark", {
    name = "birch bark",
    icon = "vgui/wep_jack_hmcd_rifle",
    weapon_class = "weapon_kar98",
    achievement_key = "kar98k_expertise",
    material_rules = {
        {"kar98", "magamed/guns/kar98k/weapon_kar98k_dm"},
        {"k98", "magamed/guns/kar98k/weapon_kar98k_dm"},
        {"wood", "magamed/guns/kar98k/weapon_kar98k_dm_wood"}
    }
})
