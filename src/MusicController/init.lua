--[[

	Region Based Music System by KazabiteBoltiz.

	Needs Folder in workspace (line 24) which contains regions (parts): (shown below)
	
	workspace
	-> musicRegions (Folder)
	   -> zone1 (Part/Union)
	   	  -> SongList (Folder)
			 -> Song (Sound)
			 -> Song (Sound)
			 -> Song (Sound)
			 -> ...
	   -> zone2
	   	  -> Song (Sound)
			 -> Song (Sound)
			 -> Song (Sound)
			 -> ...

	Note: Ideally zone Parts should not intersect, but the code will function normally if they do.
		Names of the zones are to be different. No 2 regions should be named the same
		On Server, Override of the music must be specific to a zone (explained in Server > Services > MusicService)

]]

local plr = game.Players.LocalPlayer
local UI = plr.PlayerScripts.Client.UI

local Modules = game.ReplicatedStorage.Modules

local Packages = game.ReplicatedStorage.Packages
local Knit = require(Packages.knit)
local Signal = require(Packages.signal)
local Trove = require(Packages.trove)

local MusicController = Knit.CreateController({ Name = "MusicController" })

local ZonePlus = require(Modules.Zone)
local Fusion = require(Modules.Fusion)
local Compat = Fusion.Compat

local MusicSystemUI = require(UI.MusicSystem)

--//

local Zones = {}
local zonePartsFolder = workspace:WaitForChild("musicRegions")

--//

local SettingsUI = MusicSystemUI.SettingsUI()
SettingsUI.Parent = plr.PlayerGui

function MusicController:KnitInit()
    self.CurrentZone = nil
    self.CurrentList = nil
    self.CurrentSong = 0
    self.Override = false
    self.OverrideZones = {}

    self.GlobalVolume = 0.4
    self.Muted = false

    self.GlobalMixer = Instance.new("SoundGroup")
    self.GlobalMixer.Volume = self.GlobalVolume
    self.GlobalMixer.Parent = workspace

    self.ZoneChanged = Signal.new()
    self.StateChanged = Signal.new()
    self.myTrove = Trove.new()

    self.States = {
        NewZone = require(script.States.NewZone),
        NextSong = require(script.States.NextSong),
        Override = require(script.States.Override),
    }
end

function MusicController:KnitStart()
    local MusicService = Knit.GetService("MusicService")

    MusicService.OverrideMusic:Connect(function(timeSent, duration, id, zone)
        --// Calculating Lag
        local timeDelay = (workspace:GetServerTimeNow() - timeSent) / 100
        local finalDuration = duration - timeDelay

        self.OverrideZones[zone.Name] = { timeDelay, finalDuration, id, zone }

        if self.CurrentZone == zone then
            self:ChangeState(self.States.Override)
            self.Override = true
        end

        task.spawn(function()
            task.wait(finalDuration)
            self.OverrideZones[zone.Name] = nil
        end)
    end)

    for _, zonePart in ipairs(zonePartsFolder:GetChildren()) do
        local newZone = ZonePlus.new(zonePart)
        table.insert(Zones, newZone)
    end

    for _, zone in ipairs(Zones) do
        zone.localPlayerEntered:Connect(function()
            if self.CurrentZone == zone.zoneParts[1] then
                return
            end

            self.CurrentZone = zone.zoneParts[1]
            self.ZoneChanged:Fire(zone)

            if not self.OverrideZones[self.CurrentZone] then
                self:ChangeState(self.States.NewZone)
                self.Override = false
            else
                self:ChangeState(self.States.Override)
                self.Override = true
            end
        end)
    end

    SettingsUI.Body.Muted.Activated:Connect(function()
        self:SetMute(not self.Muted)
    end)

    SettingsUI.Body.Volume.FocusLost:Connect(function(enterPressed)
        if not enterPressed then
            return
        end
        self:SetVolume(tonumber(SettingsUI.Body.Volume.FocusLost))
    end)

    SettingsUI.Body.Volume.FocusLost:Connect(function(enterPressed)
        if not enterPressed then
            return
        end
        local finalVolume = tonumber(SettingsUI.Body.Volume.Text)
        if finalVolume then
            self.GlobalVolume = math.clamp(finalVolume * 100, 0, 100) / 100
        end
        SettingsUI.Body.Volume.Text = ""
    end)
end

function MusicController:ChangeState(newState)
    self.StateChanged:Fire(newState.Name)

    if self.CurrentState then
        self.CurrentState:End()
    end
    self.myTrove:Clean()
    self.CurrentState = newState.new(self)
    self.CurrentState:Start()
end

function MusicController:SetVolume(vol: number)
    if vol then
        self.GlobalVolume = math.clamp(vol * 100, 0, 100) / 100
    end
    SettingsUI.Body.Volume.Text = ""
end

function MusicController:SetMute(bool: boolean)
    self.Muted = bool
    self.GlobalMixer.Volume = self.Muted and 0 or self.GlobalVolume
end

return MusicController
