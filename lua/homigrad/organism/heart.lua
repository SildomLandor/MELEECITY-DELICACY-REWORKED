if CLIENT then
    local Heartbeat = {}
    Heartbeat.Enabled = CreateClientConVar("hg_heartbeat_enabled", "1", true, false)
    Heartbeat.Width = ScrW()
    Heartbeat.Height = ScrH()
    
    Heartbeat.LastHeartStopState = false
    Heartbeat.HeartStopSoundPlayed = false
    Heartbeat.LastHighPulseState = false
    Heartbeat.HighPulseSound = nil
    Heartbeat.HighPulseVolume = 0
    Heartbeat.TargetHighPulseVolume = 0
    
    surface.CreateFont("Heartbeat_Small", {
        font = "Bender",
        size = 11,
        weight = 400
    })
    
    surface.CreateFont("Heartbeat_Medium", {
        font = "Bender",
        size = 14,
        weight = 600
    })
    
    surface.CreateFont("Heartbeat_Large", {
        font = "Bender",
        size = 16,
        weight = 800
    })
    
    surface.CreateFont("Heartbeat_Status", {
        font = "Bender",
        size = 14,
        weight = 900
    })
    
    Heartbeat.ECGData = {}
    Heartbeat.DataPoints = 300
    Heartbeat.DataIndex = 1
    Heartbeat.LastUpdateTime = 0
    Heartbeat.UpdateInterval = 0.05
    Heartbeat.LastPulse = 70
    Heartbeat.CardiacArrestTimer = 0
    Heartbeat.ArrhythmiaTimer = 0
    Heartbeat.WaveTime = 0
    
    for i = 1, Heartbeat.DataPoints do
        Heartbeat.ECGData[i] = 0
    end
    
    
    function Heartbeat:CheckPlayerState()
        local ply = LocalPlayer()
        if not IsValid(ply) then 
            self.IsActive = false
            return false
        end
        
        if not ply:Alive() then
            if self.IsActive then
                self:OnPlayerDied()
            end
            self.IsActive = false
            self.WasDead = true
            return false
        end
        
        if self.WasDead and ply:Alive() then
            self.WasDead = false
            if not self.IsActive then
                self:OnPlayerRespawned()
            end
            self.IsActive = true
        end
        
        return true
    end
    
    
    function Heartbeat:OnPlayerDied()
        if self.HighPulseSound and self.HighPulseSound:IsValid() then
            self.HighPulseSound:Stop()
            self.HighPulseSound = nil
        end
        
        self:StopHeartStopSound()
        
        for i = 1, self.DataPoints do
            self.ECGData[i] = 0
        end
        
        self.CardiacArrestTimer = 0
        self.ArrhythmiaTimer = 0
        self.WaveTime = 0
    end
    
    
    function Heartbeat:OnPlayerRespawned()
        self.LastHeartStopState = false
        self.HeartStopSoundPlayed = false
        self.LastHighPulseState = false
        self.HighPulseVolume = 0
        self.TargetHighPulseVolume = 0
        self.LastUpdateTime = 0
        self.LastPulse = 70
    end
    
    
    function Heartbeat:GetPlayerOrganism()
        local ply = LocalPlayer()
        if not IsValid(ply) then return nil end
        if not ply:Alive() then return nil end
        
        if ply.organism then return ply.organism end
        if ply.new_organism then return ply.new_organism end
        
        return nil
    end
    
    
    function Heartbeat:GetMedicalMetrics(org)
        if not org then
            return {
                pulse = 70,
                heartDamage = 0,
                heartStop = false,
                unconscious = false,
                critical = false
            }
        end
        
        return {
            pulse = org.pulse or 70,
            heartDamage = org.heart or 0,
            heartStop = org.heartstop or false,
            unconscious = org.otrub or false,
            critical = org.critical or false
        }
    end
    
    
    function Heartbeat:DetermineMedicalState(metrics)
        local state = {
            isCardiacArrest = false,
            isArrhythmia = false,
            isTachycardia = false,
            isBradycardia = false,
            isUnconscious = false,
            severity = 0
        }
        
        state.isCardiacArrest = metrics.heartStop or metrics.pulse <= 0
        state.isArrhythmia = metrics.heartDamage > 0.3
        state.isTachycardia = metrics.pulse > 120
        state.isBradycardia = metrics.pulse < 50 and metrics.pulse > 0
        state.isUnconscious = metrics.unconscious
        
        local severity = 0
        if state.isCardiacArrest then severity = severity + 0.3 end
        if metrics.critical then severity = severity + 0.2 end
        
        state.severity = math.min(severity, 1)
        
        return state
    end
    
    
    function Heartbeat:PlayHeartStopSound()
        sound.Play("ambient/alarms/apc_alarm_loop1.wav", LocalPlayer():GetPos(), 75, 100, 1)
    end
    
    
    function Heartbeat:StopHeartStopSound()
        LocalPlayer():StopSound("ambient/alarms/apc_alarm_loop1.wav")
    end
    
    
    function Heartbeat:UpdateHighPulseSound(metrics, state)
        local isHighPulse = metrics.pulse > 120 and not state.isCardiacArrest
        local pulseFactor = math.max(0, (metrics.pulse - 120) / 80)
        
        if isHighPulse then
            self.TargetHighPulseVolume = 0.3 + pulseFactor * 0.5
        else
            self.TargetHighPulseVolume = 0
        end
        
        self.HighPulseVolume = Lerp(FrameTime() * 3, self.HighPulseVolume, self.TargetHighPulseVolume)
        
        if self.HighPulseVolume > 0.01 then
            if not self.HighPulseSound or not self.HighPulseSound:IsValid() then
                self.HighPulseSound = CreateSound(LocalPlayer(), "sound/pyls.wav")
                if self.HighPulseSound then
                    self.HighPulseSound:PlayEx(0, 100)
                end
            end
            
            if self.HighPulseSound then
                self.HighPulseSound:ChangeVolume(self.HighPulseVolume, 0.1)
                
                local pitch = 100 + pulseFactor * 20
                self.HighPulseSound:ChangePitch(pitch, 0.1)
            end
        elseif self.HighPulseSound and self.HighPulseSound:IsValid() then
            if self.HighPulseVolume <= 0.01 then
                self.HighPulseSound:Stop()
                self.HighPulseSound = nil
            end
        end
    end
    
    
    function Heartbeat:GenerateECGWave(phase, metrics, state)
        local wave = 0
        
        if state.isCardiacArrest then
            return 0
        end
        
        local pWave, qrsComplex, tWave = 0, 0, 0
        
        if phase > 0.05 and phase < 0.12 then
            local pPhase = (phase - 0.05) / 0.07
            pWave = math.sin(pPhase * math.pi) * 0.15
        end
        
        if phase > 0.15 and phase < 0.18 then
            local qPhase = (phase - 0.15) / 0.03
            qrsComplex = -math.sin(qPhase * math.pi) * 0.2
        end
        if phase > 0.18 and phase < 0.22 then
            local rPhase = (phase - 0.18) / 0.04
            qrsComplex = qrsComplex + math.sin(rPhase * math.pi) * 1.2
        end
        if phase > 0.22 and phase < 0.26 then
            local sPhase = (phase - 0.22) / 0.04
            qrsComplex = qrsComplex - math.sin(sPhase * math.pi) * 0.4
        end
        
        if phase > 0.35 and phase < 0.5 then
            local tPhase = (phase - 0.35) / 0.15
            tWave = math.sin(tPhase * math.pi) * 0.35
        end
        
        wave = pWave + qrsComplex + tWave
        
        local baseline = math.sin(phase * 2 * math.pi) * 0.05
        wave = wave + baseline
        
        if state.isArrhythmia then
            local arrhythmiaStrength = metrics.heartDamage * 0.5
            local arrhythmiaFreq = 15 + math.sin(CurTime() * 2) * 5
            local arrhythmiaWave = math.sin(phase * arrhythmiaFreq) * 0.3 * arrhythmiaStrength
            
            if math.random(100) < metrics.heartDamage * 20 then
                arrhythmiaWave = arrhythmiaWave + math.sin(phase * 100) * 0.5 * arrhythmiaStrength
            end
            
            wave = wave + arrhythmiaWave
        end
        
        if state.isTachycardia then
            wave = wave * 0.9
            wave = wave + math.sin(phase * 35) * 0.15
        end
        
        if state.isBradycardia then
            wave = wave * 1.1
            wave = wave + math.sin(phase * 8) * 0.1
        end
        
        if state.isUnconscious then
            wave = wave * 0.6
            wave = wave + math.sin(phase * 6) * 0.1
        end
        
        wave = wave + (math.random() - 0.5) * 0.05
        
        return wave
    end
    
    
    function Heartbeat:Update()
        if not self.Enabled:GetBool() then return end
        if not self:CheckPlayerState() then return end
        if not self.IsActive then return end
        
        if not GetGlobalBool("HG_Heartbeat_Active", true) then return end
        
        local org = self:GetPlayerOrganism()
        local metrics = self:GetMedicalMetrics(org)
        local state = self:DetermineMedicalState(metrics)
        
        if not state.isUnconscious then return end
        
        local currentTime = CurTime()
        if currentTime - self.LastUpdateTime < self.UpdateInterval then return end
        self.LastUpdateTime = currentTime
        
        local heartStop = state.isCardiacArrest
        
        if heartStop and not self.LastHeartStopState then
            self:PlayHeartStopSound()
            self.HeartStopSoundPlayed = true
        elseif not heartStop and self.LastHeartStopState then
            self:StopHeartStopSound()
            self.HeartStopSoundPlayed = false
        end
        
        self.LastHeartStopState = heartStop
        
        self:UpdateHighPulseSound(metrics, state)
        
        if state.isCardiacArrest then
            self.CardiacArrestTimer = self.CardiacArrestTimer + FrameTime()
        else
            self.CardiacArrestTimer = math.max(self.CardiacArrestTimer - FrameTime() * 0.5, 0)
        end
        
        if state.isArrhythmia then
            self.ArrhythmiaTimer = self.ArrhythmiaTimer + FrameTime()
        else
            self.ArrhythmiaTimer = math.max(self.ArrhythmiaTimer - FrameTime() * 0.3, 0)
        end
        
        if metrics.pulse > 0 and not state.isCardiacArrest then
            local timeScale = metrics.pulse / 60
            self.WaveTime = self.WaveTime + (FrameTime() * timeScale)
        end
        
        local phase = self.WaveTime % 1
        
        local waveValue = self:GenerateECGWave(phase, metrics, state)
        
        self.ECGData[self.DataIndex] = waveValue
        self.DataIndex = self.DataIndex + 1
        if self.DataIndex > self.DataPoints then
            self.DataIndex = 1
        end
        
        self.LastPulse = metrics.pulse
    end
    
    
    function Heartbeat:Draw()
        if not self.Enabled:GetBool() then return end
        if not self:CheckPlayerState() then return end
        if not self.IsActive then return end
        
        if not GetGlobalBool("HG_Heartbeat_Active", true) then return end
        
        local org = self:GetPlayerOrganism()
        local metrics = self:GetMedicalMetrics(org)
        local state = self:DetermineMedicalState(metrics)
        
        if not state.isUnconscious then return end
        
        local x = 35
        local y = 25
        
        local frameColor = Color(200, 0, 0, 255)
        local bpmColor = Color(255, 50, 50, 255)
        
        if state.isCardiacArrest then
            frameColor = Color(255, 0, 0, 255)
            bpmColor = Color(255, 0, 0, 255)
        elseif metrics.critical then
            frameColor = Color(255, 50, 0, 255)
            bpmColor = Color(255, 50, 0, 255)
        elseif state.isUnconscious then
            frameColor = Color(200, 150, 0, 255)
            bpmColor = Color(200, 150, 0, 255)
        elseif state.isArrhythmia then
            frameColor = Color(255, 100, 0, 255)
            bpmColor = Color(255, 100, 0, 255)
        elseif state.isTachycardia then
            frameColor = Color(255, 200, 0, 255)
            bpmColor = Color(255, 200, 0, 255)
        elseif state.isBradycardia then
            frameColor = Color(255, 100, 0, 255)
            bpmColor = Color(255, 100, 0, 255)
        end
        
        surface.SetDrawColor(0, 0, 0, 0)
        
        surface.SetDrawColor(0, 0, 0, 0)
        surface.DrawOutlinedRect(x, y, self.Width, self.Height)
        surface.DrawOutlinedRect(x + 1, y + 1, self.Width - 2, self.Height - 2)
        
        surface.SetDrawColor(0, 0, 0, 0)
        local gridSize = 20
        
        for i = 0, math.floor(self.Width / gridSize) do
            surface.DrawLine(x + i * gridSize, y, x + i * gridSize, y + self.Height)
        end
        
        for i = 0, math.floor(self.Height / gridSize) do
            surface.DrawLine(x, y + i * gridSize, x + self.Width, y + i * gridSize)
        end
        
        local lineColor = Color(255, 255, 255, 255)
        
        if state.isCardiacArrest then
            lineColor = Color(255, 0, 0, 255)
        elseif metrics.critical then
            local pulse = math.sin(CurTime() * 5) * 0.5 + 0.5
            lineColor = Color(255, 50 * pulse, 0, 255)
        elseif state.isArrhythmia then
            local pulse = math.sin(CurTime() * 7) * 0.5 + 0.5
            lineColor = Color(255, 100 * pulse, 0, 255)
        end
        
        local points = {}
        for i = 0, self.DataPoints - 1 do
            local idx = (self.DataIndex + i - 1) % self.DataPoints + 1
            local x_pos = 2 + i * (self.Width / self.DataPoints)
            local y_pos = y + 580 - self.ECGData[idx] * (self.Height * 0.15)
            table.insert(points, {x = x_pos, y = y_pos})
        end
        
        if #points >= 2 then
            surface.SetDrawColor(lineColor.r, lineColor.g, lineColor.b, 255)
            for i = 1, #points - 1 do
                surface.DrawLine(points[i].x, points[i].y, points[i + 1].x, points[i + 1].y)
            end
            
            surface.SetDrawColor(lineColor.r, lineColor.g, lineColor.b, 80)
            for i = 1, #points - 1 do
                surface.DrawLine(points[i].x, points[i].y + 1, points[i + 1].x, points[i + 1].y + 1)
            end
        end
        
        draw.SimpleText("", "Heartbeat_Large", x + 12, y + 12, bpmColor)
    end
    
    
    hook.Add("Think", "HeartbeatMonitor_Update", function()
        Heartbeat:Update()
    end)
    
    
    hook.Add("HUDPaint", "HeartbeatMonitor_Draw", function()
        Heartbeat:Draw()
    end)
    
    
    hook.Add("PlayerDeath", "HeartbeatMonitor_PlayerDeath", function(victim, inflictor, attacker)
        if victim == LocalPlayer() then
            Heartbeat:OnPlayerDied()
            Heartbeat.IsActive = false
            Heartbeat.WasDead = true
        end
    end)
    
    
    hook.Add("PlayerSpawn", "HeartbeatMonitor_PlayerSpawn", function(ply)
        if ply == LocalPlayer() then
            Heartbeat.WasDead = false
            if Heartbeat.Enabled:GetBool() then
                Heartbeat:OnPlayerRespawned()
                Heartbeat.IsActive = true
            end
        end
    end)
end