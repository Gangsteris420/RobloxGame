local ReplicatedStorage = game.ReplicatedStorage
local characterJoined = ReplicatedStorage:FindFirstChild("SendCache")
local buttonTouched = ReplicatedStorage:FindFirstChild("ButtonTouched")
local remoteFunction = ReplicatedStorage:FindFirstChild("RemoteFunction")
local remoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvent")
local stageStarted = ReplicatedStorage:FindFirstChild("StageStarted")
local stageEnd = ReplicatedStorage:FindFirstChild("ResetStage")

-- need to rework this part completely (how information is being passed to each client and server and from each other)
-- then bugs can also be worked out because now how the information is being passed
-- is very random and mostly confusing

-- the reason they are not in the ReplicatedStorage folder is because they can only be created in game. but they have no code inside them
-- their main purpose is to let client/server, server/client communicate with each other
-- hope it makes sense


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

buttonTouched.OnClientEvent:Connect(function(ButtonsTouched, stage_Name)
	-- it looks a bit dumb me sending a table only for 2 values but it is key element of keeping track of
	-- whether the stage was started on the server side for a individual player

	local stage_from_str = game.Workspace.Obby:FindFirstChild(stage_Name)
	local platform = stage_from_str:FindFirstChild(ButtonsTouched[stage_from_str.Name].StagePart)
	local button = stage_from_str:FindFirstChild("RedButtonOne") -- this could be changed in the future if each stage had a custom button instance and its name
	local stage_key_time = ButtonsTouched[stage_from_str.Name].StageTime

	--local stage_time = require(game.ReplicatedStorage.StageData).ReturnData(stage.Name, "Time")
	-- this should only be accessible to the server
	
	if can_be_touched == nil then
		can_be_touched = true -- for collecting coins/starting loop, maybe something else could be done
		
		--
		-- need to figure a good way of sending can_be_touched to server, or to figure out 
		-- how to disable coin collecting in server before this exact loop works (maybe ask AI for any ideas)
		--

		platform.Transparency = 1
		platform.CanCollide = false
		button.CanTouch = false

		-- this loop being in client side could be a potential issue
		-- probably need the whole loop in the server side, just dont really see a non-exploitable way
		stageStarted:FireServer()
		task.wait(stage_key_time)

		platform.Transparency = 0
		platform.CanCollide = true
		button.CanTouch = true
		can_be_touched = nil
	end
end)

