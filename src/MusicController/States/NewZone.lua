local NewZone = {}
NewZone.__index = NewZone

NewZone.Name = "NewZone"

function NewZone.new(Controller)
    local self = setmetatable({}, NewZone)
    self.Controller = Controller
    self.myTrove = self.Controller.myTrove:Extend()

    return self
end

function NewZone:Start()
    local zonePart = self.Controller.CurrentZone

    print("Current Zone", zonePart)

    self.Controller.CurrentList = self.Controller.CurrentZone:WaitForChild("SongList"):GetChildren()
    self.Controller.CurrentSong = 0

    if not self.Controller.Override then
        self.Controller:ChangeState(self.Controller.States.NextSong)
    end
end

function NewZone:End() end

return NewZone
