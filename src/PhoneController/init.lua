--// Globals
local plr = game.Players.LocalPlayer
local plrUI = plr.PlayerGui
local ts = game:GetService("TweenService")
local uis = game:GetService("UserInputService")
local lighting = game.Lighting
--// Knit
local Packages = game.ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local Signal = require(Packages.Signal)

local PhoneController = Knit.CreateController {Name = "PhoneController"}
--// Script Values
local phoneOpen = false
local inTween = false
local inApp = false
local selectedApp = nil

local phoneUI = plrUI:WaitForChild("PhoneUI", math.huge) --ScreenGui
local phoneBody = phoneUI:WaitForChild("Body")
local phoneToggleButton = phoneBody:WaitForChild("Toggle")
local phoneHeader = phoneBody:WaitForChild("Screen").Top
local phoneMain = phoneBody:WaitForChild("Screen").Main
local clockText = phoneHeader.Clock
-- local batteryText = phoneHeader.Battery
local appSection = phoneMain:WaitForChild("Container").Apps
local homeButton = phoneBody:WaitForChild("TaskPad").Home
local appButtonClone = appSection.appButtonClone

-- local batteryBar = batteryText.Bar.Actual

local apps = {}

local openSettings = {
	twInfo = TweenInfo.new(.2,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),
	position = UDim2.new(0.987, 0,0.350, 0)
}
local closeSettings = {
	twInfo = TweenInfo.new(.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
	position = UDim2.new(0.987, 0,1, 0)
}
--// Support Functions
-- local function SetBattery(percentage)
-- 	batteryText.Text = tostring(percentage).."%"
-- 	batteryBar.Size = UDim2.new(percentage/100,0,1,0)
-- end
local function initApps()
	for _,appModule in ipairs(script.Apps:GetChildren()) do
		local newAppButton = appButtonClone:Clone()
		newAppButton.Name = require(appModule).Name
		--newAppButton.Icon.Image = require(appModule).Image
		newAppButton.Visible = true
		newAppButton.Parent = appSection
	end
end
local function changePhoneTime()
	local NewTime = lighting.ClockTime * 60
	local Hours = math.floor(NewTime / 60)
	local HoursConverted = Hours % 12

	if HoursConverted == 0 then
		HoursConverted = 12
	end

	clockText.Text = string.format('%d:%02d%s', HoursConverted, NewTime%60, Hours > 12 and 'am' or 'pm')
end
local function toggleScreen(bool)
	if inTween then return end
	
	local toggleInfo = bool and openSettings or closeSettings
	
	local toggleTween = ts:Create(phoneBody, 
		toggleInfo.twInfo,
		{Position = toggleInfo.position}
	)
	
	inTween = true
	
	toggleTween.Completed:Connect(function()
		phoneOpen = bool
		inTween = false
	end)
	
	toggleTween:Play()
end
--// Main Functions
function PhoneController:KnitInit()
    print("phone system is online")
	print(inApp)

	toggleScreen(false)
	initApps()
	
	game["Run Service"].Stepped:Connect(changePhoneTime)
	
	for _,v in ipairs(appSection:GetChildren()) do
		if v:IsA("ImageButton") then
			
			local appClosed = Signal.new() -- can be fired from the app module to tell the phone it has been closed.
			local appClosing = false
			local appCloseFinished = Signal.new()
			
			apps[v.Name] = {appClosed, appClosing, appCloseFinished}
	
			v.Activated:Connect(function()
				if not appClosing 
					and selectedApp == nil   
				then
					selectedApp = require(script.Apps:WaitForChild(v.Name))
					selectedApp.Opened(appClosed)
					inApp = true
				end
			end)
			appClosed:Connect(function()
				if not selectedApp then return end
				if selectedApp.Name == v.Name then
					appClosing = true
					selectedApp.Closed(appCloseFinished)
					selectedApp = nil	
				end
			end)
			appCloseFinished:Connect(function()
				print(v.Name,"has closed")
				appClosing = false
				inApp = false
			end)
			
		end
	end

end
--//Events

-- Button Support (PC)
uis.InputBegan:Connect(function(input, typing)
	if typing then return end
	
	if input.KeyCode == Enum.KeyCode.M then
		toggleScreen(not phoneOpen) 
	end
end)

-- Touch Support (Mobile)
phoneToggleButton.Activated:Connect(function()
	toggleScreen(not phoneOpen)
end)

homeButton.Activated:Connect(function()
	if selectedApp ~= nil then
		print("Home Button Pressed")
		selectedApp.Closed(apps[selectedApp.Name][3])
		selectedApp = nil	
		inApp = false
	end
end)
--//
return PhoneController