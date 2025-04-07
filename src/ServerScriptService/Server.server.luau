local ReplicatedStorage = game:GetService("ReplicatedStorage")
local sendCache = ReplicatedStorage:FindFirstChild("SendCache")
local buttonTouched = ReplicatedStorage:FindFirstChild("ButtonTouched")

local platform_name = "BigPlatformFinish"
local platform_door = "BigPlatformDoorOne"
local button_name = "RedButtonOne"
local coin_block_names = { "CoinBlock1", "CoinBlock2"}

--local killPart = game.ReplicatedStorage.Obby:FindFirstChild("KillPart")

local cached_coins = {}
local cached_buttons = {}
local cached_platforms = {}

local debounce_platforms = {}

local stages = {
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

for _, model in ipairs(game.Workspace.Obby:GetChildren()) do -- looping through models in folder
	for _, part in ipairs(model:GetChildren()) do -- looping through parts of a model

		-- cache buttons for each stage
		-- need fix this
		if part.Name == button_name then
			if not cached_buttons[part.Parent] then
				cached_buttons[part.Parent] = part
			end
		end

		-- cache platform finish points 
		-- need fix this
		if part.name == platform_name then
			if not cached_platforms[part.Parent] then
				cached_platforms[part.Parent] = part -- part.Parent part
			end
		end

		-- cache coins for stages

		for i = 1, #coin_block_names do
			if part.Name == coin_block_names[i] then
				if not cached_coins[part.Parent] then -- might need to use part.Parent.Name
					cached_coins[part.Parent] = {}
				end

				table.insert(cached_coins[part.Parent], part)
			end
		end
	end
end

print("server caches")
print(cached_coins)
print(cached_buttons)
print(cached_platforms)

local button_touched = {}

-- button touched
for _, block in pairs(cached_buttons) do
	block.Touched:Connect(function(otherPart)

		local humanoid = otherPart.Parent:FindFirstChild("Humanoid")  -- check if the part that touched the platform has a humanoid
		if humanoid then -- if it has a humanoid
			local player = game.Players:GetPlayerFromCharacter(otherPart.Parent) -- get player from touching part
			local player_userId = tostring(player.UserId)

			if not button_touched[player_userId] then 
				button_touched[player_userId] = {}
			end

			-- table that has all the strings for finding a shared instance in client/server
			-- [[ ["491595967"] =  ▼  {
				-- ["Stage1"] = true
			 --]] } 
			-- table example

			if not button_touched[player_userId][block.Parent.Name] then
				button_touched[player_userId][block.Parent.Name] = true

				print(button_touched, "button")

				task.wait(0.1)

				-- logic was re-evaluated in the server, button_touched only has strings, first table is with the 
				-- sole string name of the player_userId, the inner table has stage to which the button pressed belongs
				-- and the value of true. This table with inner table is sent to client, client loops through
				-- gets the data and then gets the actual instances from the name by looping through shared game.Workspace.Obby
				
				buttonTouched:FireClient(player, button_touched) 
			end
		end
	end)
end

-- Coin Collected/Touched
for _, blocks in pairs(cached_coins) do
	blocks.Touched:Connect(function(otherPart)
		local humanoid = otherPart.Parent:FindFirstChild("Humanoid")
		local player = game.Players:GetPlayerFromCharacter(otherPart.Parent)

		if player and humanoid and can_be_touched ~= nil then

			if not touched_coins[blocks.Name] then -- ai
				touched_coins[blocks.Name] = blocks.Parent.Name

				blocks.Transparency = 1
			end
		end
	end)
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