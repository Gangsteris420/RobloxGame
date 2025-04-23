local ReplicatedStorage = game.ReplicatedStorage
local characterJoined = ReplicatedStorage:FindFirstChild("SendCache")
local buttonTouched = ReplicatedStorage:FindFirstChild("ButtonTouched")
local remoteFunction = ReplicatedStorage:FindFirstChild("RemoteFunction")
local remoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvent")
local stageComplete = ReplicatedStorage:FindFirstChild("StageComplete")

-- need to rework this part completely (how information is being passed to each client and server and from each other)
-- then bugs can also be worked out because now how the information is being passed
-- is very random and mostly confusing

-- the reason they are not in the ReplicatedStorage folder is because they can only be created in game. but they have no code inside them
-- their main purpose is to let client/server, server/client communicate with each other
-- hope it makes sense

local stages = {
	["Stage1"] = {
		["Points"] = 2, -- points to complete
		["Time"] = 5, -- seconds to finish
		["Health"] = 3 -- lives per stage
	},

	["Stage2"] = {
		["Points"] = 2,
		["Time"] = 5,
		["Health"] = 3
	},
}


-- example on how a certain instance can be found using a saved part String name from a dictionary that is sent from server to client.
-- 1. a dictionary received from server is being looped over
-- 2. requires some nested looping to acquire the model(s)
-- 3. once the model(s) are acquired then they are being looped over
-- 4. model is being looped over and parts are being received, then a String part name from the dictionary is being checked with String part name from the model's part
-- if they are equal, the actual part/model (its instance) can be found.

-- Honestly, I would just send an instance from server to client but it either doesn't work ir isn't that simple overall

--[[receivedDebounce.OnClientEvent:Connect(function(c_coins)

	for parent_coin, parent in pairs(c_coins) do
		for _, coin in pairs(parent) do
			for _, model in ipairs(game.Workspace.Obby:GetChildren()) do
				if parent_coin == model.Name then
					table.insert(cached_coins, model:FindFirstChild(coin))
					-- part found
				end
			end
		end
	end
end)--]]

local can_be_touched = nil

--[[characterJoined.OnClientEvent:Connect(function(coins)
	task.wait(1)

	local InstancedStages = {}
	for _, stage in pairs(coins) do
		if not InstancedStages[stage.Name] then
			InstancedStages[stage.Name] = true
			stage.Parent = game.Players.LocalPlayer.ClonedInstances
		end
	end
end)--]]

-- here is what is being received from the server once a button is touched in server
-- probably a better way of doing this is sending a player rather than instance of touchedPart
-- as well as sending the clonedBlock.Name and clonedBlock.Parent.Name and this way finding and instance
-- or something similarly

function CountTableLength(self) -- learning on how to use self bit by bit :/
	local count = 0
	for _, _ in pairs(self) do
		count = count + 1
	end
	return count
end

buttonTouched.OnClientEvent:Connect(function(ButtonsTouched)
	-- need to add checks to make sure that ButtonsTouched was not altered with
	local stage_str, platform_str = next(ButtonsTouched)
	local stage = game.Workspace.Obby:FindFirstChild(stage_str)
	local platform = stage:FindFirstChild(platform_str)
	local button = stage:FindFirstChild("RedButtonOne")
	local humanoid = game.Players.LocalPlayer.Character:WaitForChild("Humanoid")
	local stage_time = stages[platform.Parent.name]["Time"]

	-- probably need to do client - server - client remote function
	if can_be_touched == nil then
		can_be_touched = true -- for collecting coins/starting loop, maybe something else could be done
		
		--
		-- need to figure a good way of sending can_be_touched to server, or to figure out 
		-- how to disable coin collecting in server before this exact loop works (maybe ask AI for any ideas)
		--

		platform.Transparency = 1
		platform.CanCollide = false
		button.CanTouch = false -- so in server side the player couldnt keep interacting with the button endlessly

		-- this loop being in client side could be a potential issue
		for i = 1, stage_time, 1 do
			task.wait(1)
			print(i)

			-- platform ending conditions
			if i == stage_time or humanoid.Health == 0 then

			-- the fix for this code would probably be getting the time distance between the start time and the end time
			-- basically the start time and the end time has to have passed the specified time in stages[platform.Parent.name]["Time"]
			-- because a hacker cant fake a time passed

				stageComplete:FireServer(stage_str, platform_str)
				-- could have potential weaknesses, not guaranteed full working

				can_be_touched = nil
				platform.Transparency = 0
				platform.CanCollide = true
				button.CanTouch = true
				ButtonsTouched = {}

				-- need to implement logic for reseting transparancy of collected coins 
				-- but before need to implement coin collecting that only works when this loop works

				break
			end
		end
	end
end)

