local ReplicatedStorage = game:GetService("ReplicatedStorage")
local sendCache = ReplicatedStorage:FindFirstChild("SendCache")
local buttonTouched = ReplicatedStorage:FindFirstChild("ButtonTouched")
local remoteFunction = ReplicatedStorage:FindFirstChild("RemoteFunction")
local remoteEvent = ReplicatedStorage:FindFirstChild("RemoteEvent")

local platform_name = "BigPlatformFinish"  -- could use a module script for this in the future
local platform_door = "BigPlatformDoorOne"  -- could use a module script for this in the future
local button_name = "RedButtonOne" -- could use a module script for this in the future
local coin_block_names = { "CoinBlock1", "CoinBlock2"}  -- could use a module script for this in the future

--local killPart = game.ReplicatedStorage.Obby:FindFirstChild("KillPart")

--local cached_coins = {}
--local cached_buttons = {}
--local cached_platforms = {}

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

print("server caches")
print(cached_buttons)

-- button touched
for Parent, block in pairs(cached_buttons.Buttons) do -- need to fix since cached_button works completely different now

	block.Touched:Connect(function(otherPart)
		local humanoid = otherPart.Parent:FindFirstChild("Humanoid")  -- check if the part that touched the platform has a humanoid
		if humanoid then -- if it has a humanoid
			local player = game.Players:GetPlayerFromCharacter(otherPart.Parent) -- get player from touching part
			local player_userId = tostring(player.UserId)

			if not button_touched[player_userId] then 
				button_touched[player_userId] = {}
			end

			if not button_touched[player_userId][Parent.Name] then
				button_touched[player_userId][Parent.Name] = true

				print(button_touched, "button")

				task.wait(0.1)

				-- logic was re-evaluated in the server, button_touched only has strings, first table is with the 
				-- sole string name of the player_userId, the inner table has stage to which the button pressed belongs
				-- and the value of true. This table with inner table is sent to client, client loops through
				-- gets the data and then gets the actual instances from the name by looping through shared game.Workspace.Obby
				
				buttonTouched:FireClient(player, button_touched) 
				-- here it gets sent to client and client accesses data from it but client does not send it back later on
				-- need to improve code on the client so he actually sends the table back, because if the client doesnt
				-- then its not possible to touch the button ever again, 	
				-- if not button_touched[player_userId][block.Parent.Name] then needs to be reset
			end
		end
	end)
end

-- Coin Collected/Touched 
for _, inner_table in pairs(cached_coins) do -- need to fix since cached_button works completely different now
	for _, coins in ipairs(inner_table) do

		coins.Touched:Connect(function(otherPart)
			local humanoid = otherPart.Parent:FindFirstChild("Humanoid")
			local player = game.Players:GetPlayerFromCharacter(otherPart.Parent)
			local can_be_touched = ServerInvoked()

			print(can_be_touched, "coin collected")

			--[[if player and humanoid and can_be_touched ~= nil then

				if not touched_coins[blocks.Name] then -- ai
					touched_coins[blocks.Name] = blocks.Parent.Name

					blocks.Transparency = 1
				end
			end--]]
		end)
	end
end

-- might need this example in future for reference
function ServerInvoked()
	local boolean = nil
	remoteFunction.OnServerInvoke = function(_, can_be_touched)
		boolean = can_be_touched
	end
	return boolean
end

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