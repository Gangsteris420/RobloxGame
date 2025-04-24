local ReplicatedStorage = game:GetService("ReplicatedStorage")
local sendCache = ReplicatedStorage:FindFirstChild("SendCache")
local buttonTouched = ReplicatedStorage:FindFirstChild("ButtonTouched")
local remoteFunction = ReplicatedStorage:FindFirstChild("RemoteFunction")
local remoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvent")
local stageComplete = ReplicatedStorage:FindFirstChild("StageComplete")

local platform = "BigPlatform"
local platform_name = "BigPlatformFinish"  -- could use a module script for this in the future
local platform_door = "BigPlatformDoorOne"  -- could use a module script for this in the future
local button_name = "RedButtonOne" -- could use a module script for this in the future
local coin_block_names = { "CoinBlock1", "CoinBlock2"}  -- could use a module script for this in the future
local player_button_Data = {}

--local killPart = game.ReplicatedStorage.Obby:FindFirstChild("KillPart")

local stages = { -- could use a module script for this in the future
	["Stage1"] = {
		["Points"] = 2,
		["Time"] = 10, -- seconds
		["Health"] = 3
	},

	["Stage2"] = {
		["Points"] = 2,
		["Time"] = 5,
		["Health"] = 3
	},
}

-- bug here occurs 0.000001% of times but probably it occurs because models dont get loaded.
-- need to add that check so loop waited for the models to load, or maybe it doesnt detect the Obby folder itself WITH the models
-- need to investigate more.

local cached_buttons = {
	Buttons = {},
	Platforms = {},
	Coins = {}
}

for caching_tables, _ in pairs(cached_buttons) do
	setmetatable(cached_buttons[caching_tables], {
		__newindex = function(self, key, value)
			if caching_tables ~= "Coins" then
				rawset(self, key, value) -- might have to do key.Name instead, but everything might work like this too for platforms/buttons
			else
			-- code for storing coins for each stage using Stage1/Stage2 as a key string for a table and then storing actual instances inside
				if not self[key.Name] then
					rawset(self, key.Name, {})
				end
				table.insert(self[key.Name], value)
			end
		end
	})
end

for _, part in ipairs(game.Workspace.Obby:GetDescendants()) do -- looping through all the instances in folder and caching them
	-- cache buttons for each stage
	if part.Name == button_name then
		cached_buttons.Buttons[part.Parent] = part
	-- cache platform finish points 
	elseif part.name == platform_name then
		cached_buttons.Platforms[part.Parent] = part
	end

	-- cache coins for stages
	for i = 1, #coin_block_names do
		if part.Name == coin_block_names[i] then
			cached_buttons.Coins[part.Parent] = part
		end
	end
end

function CountTableLength(self) -- learning on how to use self bit by bit :/ and oop
	local count = 0
	for _, _ in pairs(self) do
		count = count + 1
	end
	return count
end

function insertToTable(uuid, parent)
	if not player_button_Data[uuid].ButtonsTouched[parent.Name] then
		player_button_Data[uuid].ButtonsTouched[parent.Name] = platform_door -- might need to change this to a string from parameter if function will have other uses
		return true
	end
	return false
end

-- button touched
for parent, block in pairs(cached_buttons.Buttons) do -- need to fix since cached_button works completely different now
	block.Touched:Connect(function(otherPart)
		if otherPart.Parent:FindFirstChild("Humanoid") then -- if character interacted has a humanoid
			local player = game.Players:GetPlayerFromCharacter(otherPart.Parent) -- get player from touching part
			local player_userId = tostring(player.UserId)
			local success = insertToTable(player_userId, parent)

			if success then
				task.wait(0.1)
				buttonTouched:FireClient(player, player_button_Data[player_userId].ButtonsTouched)
			end
		end
	end)
end

function EventToString(eventName)
	return tostring(eventName)
end

-- player_button_Data[uuid].ButtonsTouched = {}
-- Stage complete event triggered from client
stageComplete.OnServerEvent:Connect(function(player)
	local uuid = tostring(player.UserId)
	local event = EventToString(stageComplete)
	local tbl_length = CountTableLength(player_button_Data[uuid].ButtonsTouched)
	local event_triggered = require(ReplicatedStorage.ModuleScript)

	if tbl_length == 0 then
		print("nanana", tbl_length, player_button_Data[uuid].ButtonsTouched)
	else
		print("yesyesyes", tbl_length, player_button_Data[uuid].ButtonsTouched)
	end

	event_triggered.OnEvent(event, uuid)

	-- the fix for this code would probably be getting the time distance between the start time and the end time from the client
	-- basically the start time and the end time has to have passed the specified time in stages[platform.Parent.name]["Time"]
	-- because a hacker cant fake a time passed

end)

-- Coin Collected/Touched (client | 92)
for _, inner_table in pairs(cached_buttons.Coins) do -- need to fix since cached_button works completely different now
	for _, coins in ipairs(inner_table) do


		-- I GUESS what kinf of logic i could use is when a coin is interacted either first check whether
		-- player_button_Data[uuid].ButtonsTouched is not nil, which would indicate that only when it has something in it would work
		-- and then validate whether coin that was interacted has the same stage and platform as the player_data[uuid].ButtonsTouched table
		-- AND ofcourse i need to also check debounce, whether coin is collected so it wouldnt be possible to collect it non stop

		--coins.Touched:Connect(function(otherPart)
			--local humanoid = otherPart.Parent:FindFirstChild("Humanoid")
			--local player = game.Players:GetPlayerFromCharacter(otherPart.Parent)
			--local can_be_touched = ServerInvoked()

			--print(can_be_touched, "coin collected")

			--[[if player and humanoid and can_be_touched ~= nil then

				if not touched_coins[blocks.Name] then -- ai
					touched_coins[blocks.Name] = blocks.Parent.Name

					blocks.Transparency = 1
				end
			end--]]
		--end)
	end
end



-- might need this example in future for reference
--[[function ServerInvoked()
	local boolean = nil
	remoteFunction.OnServerInvoke = function(_, can_be_touched)
		boolean = can_be_touched
	end
	return boolean
end--]]

game.Players.PlayerAdded:Connect(function(player)
	local PlayerStats = Instance.new("Folder")
	PlayerStats.Name = "leaderstats"
	PlayerStats.Parent = player

	local Clicks = Instance.new("IntValue")
	Clicks.Name = "Clicks"
	Clicks.Value = 0
	Clicks.Parent = PlayerStats

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = 0
	coins.Parent = PlayerStats

	local stage = Instance.new("IntValue")
	stage.Name = "Stage_Health"
	stage.Value = 0
	stage.Parent = PlayerStats

	-- ai suggested this idea, not a bad one
	-- but this probably might not be useful in the future because
	-- it creates every time a player joins, so what happens if he leaves and joins?
	-- does upon his leaving this wipe? also need to consider because for stages or (a stage player left standing on) a certain position must be saved
	-- in order to teleport the player back for the stages he has achieved, sql database most likely required

	player_button_Data[tostring(player.UserId)] = {
        ButtonsTouched = {},
        CoinsTouched = {},
        PlatformsTouched = {}
    }

	--[[player.CharacterAdded:Connect(function(character) 
		--local rootPart = character:WaitForChild("HumanoidRootPart", 5)
		local cloning = {}

		for parent_coin, parent in pairs(cached_coins) do
			for _, coin in pairs(parent) do
				local clone = parent_coin:Clone()
				clone.Parent = game.ReplicatedStorage
				table.insert(cloning, clone)
			end
		end--]]

		--sendCache:FireClient(player, cloning --[[cached_coins--]])
	--end)
end)