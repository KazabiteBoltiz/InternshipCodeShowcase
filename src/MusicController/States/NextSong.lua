local NewSong = {}
NewSong.__index = NewSong

NewSong.Name = "NewSong"

local ts = game:GetService("TweenService")
local twinfo = TweenInfo.new(3, Enum.EasingStyle.Cubic)

function NewSong.new(Controller)
    local self = setmetatable({}, NewSong)
    self.Controller = Controller
    self.myTrove = self.Controller.myTrove:Extend()

    self.SoundInstance = nil

    return self
end

function NewSong:Start()
    self.Controller.CurrentSong += 1

    local zoneWhenStarted = self.Controller.CurrentZone
    local interupted = false

    local songList = self.Controller.CurrentList
    local nextSong = self.Controller.CurrentSong

    local finalVolume = 1

    local newSong = nil --// Instance
    if songList[nextSong] then
        newSong = songList[nextSong]:Clone()
    else
        self.Controller.CurrentSong = 1
        newSong = songList[1]:Clone()
    end

    self.SoundInstance = newSong

    newSong.Parent = self.Controller.GlobalMixer
    newSong.Looped = false
    newSong.SoundGroup = self.Controller.GlobalMixer
    newSong.Volume = 0

    local zoneCheck
    zoneCheck = self.Controller.ZoneChanged:Connect(function(zone)
        if zone ~= zoneWhenStarted then
            interupted = true
            zoneCheck:Disconnect()
        end
    end)

    local stateCheck
    stateCheck = self.Controller.StateChanged:Connect(function(stateName)
        if stateName == "Override" then
            interupted = true
            stateCheck:Disconnect()
        end
    end)

    while not newSong.IsLoaded do
        task.wait()
    end

    newSong:Play()
    local startTween = ts:Create(newSong, twinfo, { Volume = finalVolume })
    startTween:Play()

    task.wait(newSong.TimeLength)

    if newSong then
        local endTween = ts:Create(newSong, twinfo, { Volume = 0 })
        endTween:Play()
        endTween.Completed:Connect(function()
            if newSong then
                newSong:Destroy()
            end
        end)
    end

    if not interupted then
        self.Controller:ChangeState(self.Controller.States.NextSong)
    end
end

function NewSong:End()
    local newSong = self.SoundInstance
    if newSong then
        local endTween = ts:Create(newSong, twinfo, { Volume = 0 })
        endTween:Play()
        endTween.Completed:Connect(function()
            if newSong then
                newSong:Destroy()
            end
        end)
    end
end

return NewSong
