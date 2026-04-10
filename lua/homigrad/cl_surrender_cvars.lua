CreateClientConVar("surrender_text",   "1", true, false, "Show surrender/kneel chat messages (1=on, 0=off)")
CreateClientConVar("surrender_voicel", "1", true, false, "Play scared voice line when surrendering (1=on, 0=off)")

local function SurrText()   return GetConVar("surrender_text"):GetBool()   end
local function SurrVoicel() return GetConVar("surrender_voicel"):GetBool() end

-- surrender_min_time is server-side, dont touch anything, vagy meg baszlak