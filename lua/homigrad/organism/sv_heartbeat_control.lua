if SERVER then
   
    CreateConVar("hg_heartbeat_admin_default", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY})
    
    
    local defaultState = GetConVar("hg_heartbeat_admin_default"):GetBool()
    SetGlobalBool("HG_Heartbeat_Active", defaultState)
    
    
    local function IsAdminOrHost(ply)
        if not IsValid(ply) then return true end 
        return ply:IsAdmin() or ply:IsSuperAdmin() or game.SinglePlayer()
    end
    
   
    concommand.Add("hg_heartbeat_admin", function(ply, cmd, args)
        if IsValid(ply) and not IsAdminOrHost(ply) then
            return 
        end
        
        if #args == 0 then return end
        
        local newState
        local arg = args[1]:lower()
        if arg == "1" or arg == "on" or arg == "enable" then
            newState = true
        elseif arg == "0" or arg == "off" or arg == "disable" then
            newState = false
        elseif arg == "toggle" then
            newState = not GetGlobalBool("HG_Heartbeat_Active")
        else
            return
        end
        
        SetGlobalBool("HG_Heartbeat_Active", newState)
        
    end)
end