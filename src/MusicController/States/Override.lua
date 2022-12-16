local Override = {}
Override.__index = Override

Override.Name = "Override"

local ts = game:GetService("TweenService")
local twinfo = TweenInfo.new(2, Enum.EasingStyle.Cubic)

function Override.new(Controller)
    local self = setmetatable({}, Override)
    self.Controller = Controller
    self.myTrove = self.Controller.myTrove:Extend()
    self.SoundInstance = nil

    return self
end

function Override:Start()
    print("Playing Override...")

    local currentZone = self.Controller.CurrentZone
    local overrideData = self.Controller.OverrideZones[currentZone.Name]
    local timeDelay = overrideData[1]
    local duration = overrideData[2]
    local id = overrideData[3]
    local zone = overrideData[4]
    -- { timeDelay, finalDuration, id, zone }

    local newSound = Instance.new("Sound")
    newSound.Name = self.Controller.CurrentZone.Name
    newSound.SoundId = id
    newSound.Parent = self.Controller.GlobalMixer
    newSound.SoundGroup = self.Controller.GlobalMixer
    newSound.Volume = 0
    newSound.Looped = false
    newSound:Play()

    local startTween = ts:Create(newSound, twinfo, { Volume = 1 })
    startTween:Play()

    task.wait(duration or newSound.TimeLength)

    self.Controller.Override = false

    if self.Controller.CurrentZone then
        self.Controller:ChangeState(self.Controller.States.NextSong)
    end
end

function Override:End()
    if self.SoundInstance then
        local prevSound = self.SoundInstance
        local endTween = ts:Create(prevSound, twinfo, { Volume = 0 })
        endTween:Play()
        endTween.Completed:Connect(function()
            prevSound:Destroy()
        end)
    end
end

return Override
