-- local Packages = game.ReplicatedStorage.Packages
-- local Knit = require(Packages.Knit)

--//

--[[
A -> Fired by PhoneController, to tell the app to open.

B -> closeSignal "Signal", fired by this app module to 
tell the phone system that the app has been closed.

Example : on a custom cross button, closeSignal:Fire() can
be called, which will tell the phoneSystem to close the app.
Now the phone system fires app1.Closed(), where exit animations
can be made.

C -> Fires when the PhoneSystem wants the app to close.
App Exit animations start in this function. This acts as a
middleman between switching apps, so that their work doesn't
overlap.

D -> When the exit animation has completed in this module,
completeSignal "Signal" can be fired, to tell the 
PhoneSystem that another app is ready to be opened.
]]

--//

local app1 = {}
app1.Name = "App1" -- case sensitive
app1.Icon = "" -- imageID

function app1.Opened(closeSignal) -- Point A
	print("app has been opened")
	
	task.wait(3)
	
	-- all main functionality here
	-- when app needs to close,
	
	closeSignal:Fire() -- Point B
end

function app1.Closed(completeSignal) -- Point C
	print("app is closing")
	
	-- close animations play here
	-- after animations end,
	
	completeSignal:Fire() -- Point D
end

return app1