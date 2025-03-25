local ReplicatedStorage = game:GetService("ReplicatedStorage")
local respawnEvent = ReplicatedStorage:FindFirstChild("RespawnEvent")
local debounceEvent = ReplicatedStorage:FindFirstChild("DebounceEvent") 
local buttonTouched = ReplicatedStorage:FindFirstChild("ButtonTouched") 
local platformTouched = ReplicatedStorage:FindFirstChild("PlatformTouched") 
local receiveCache = ReplicatedStorage:FindFirstChild("UpdateCache")
local sendCache = ReplicatedStorage:FindFirstChild("SendCache")
local coinLoop = ReplicatedStorage:FindFirstChild("CoinLoop")
local coinValue = ReplicatedStorage:FindFirstChild("CoinValue")
local debounceToClient = ReplicatedStorage:FindFirstChild("DebounceToClient")
local debounceToServer = ReplicatedStorage:FindFirstChild("DebounceToServer")

local playerRespawns = {}
local debounce_sv = {}
local platforms_sv = {}
local respawn_sv = {}
local stage_sv = {}

local platform_name = "BigPlatformFinish"
local platform_door = "BigPlatformDoorOne"
local button_name = "RedButtonOne"
local coin_block_names = { "CoinBlock1", "CoinBlock2"}

--local killPart = game.ReplicatedStorage.Obby:FindFirstChild("KillPart")

local default_spawn = Vector3.new(21.88815689086914, 7.835575580596924, 30.61795425415039)

local cached_coins = {}
local cached_buttons = {}
local cached_platforms = {}

local debounce_platforms = {}
local debounce_buttons = {}

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

local leaderstats_ = {}

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

-- button touched
for parent,block in pairs(cached_buttons) do
	block.Touched:Connect(function(otherPart)

		local humanoid = otherPart.Parent:FindFirstChild("Humanoid")  -- check if the part that touched the platform has a humanoid
		if humanoid then -- if it has a humanoid
			local player = game.Players:GetPlayerFromCharacter(otherPart.Parent) -- get player from touching part
			local player_userId = tostring(player.UserId)

			if not debounce_buttons[player_userId] then
				debounce_buttons[player_userId] = {}
			end

			if not debounce_buttons[player_userId][block.Parent.Name] then
				debounce_buttons[player_userId][block.Parent.Name] = block.Name

				task.wait(0.1)
				buttonTouched:FireClient(player, otherPart, block.Parent:FindFirstChild(platform_door), debounce_buttons) 

				-- probably also need to send debounce_platforms to the client because from 
				-- ButtonTouched() function other functions will be called too because those functions will be called
				-- from a client function which was called from a server function so it will only work on one player
				-- but probably need to send debounce_platforms for reset handling
			end
		end
	end)
end

local table_death_counter = {}

receiveCache.OnServerEvent:Connect(function(player, debounce_cl, platform)
	debounce_buttons = debounce_cl
	player.leaderstats.Coins.Value += stages[platform]["Points"]
	player.leaderstats.Stage_Health.Value = stages[platform]["Health"]
end)

-- platform touched
for parent,block in pairs(cached_platforms) do
	block.Touched:Connect(function(otherPart) 
		local humanoid = otherPart.Parent:FindFirstChild("Humanoid")  -- check if the part that touched the platform has a humanoid
		if humanoid then -- if it has a humanoid
			local player = game.Players:GetPlayerFromCharacter(otherPart.Parent) -- get player from touching part
			local player_userId = tostring(player.UserId)

			if not debounce_platforms[player_userId] then
				debounce_platforms[player_userId] = {}
			end

			if not debounce_platforms[player_userId][block.Parent.Name] then
				debounce_platforms[player_userId][block.Parent.Name] = block.Name
				--PlatformTouched(otherPart, block)
				task.wait(0.1)

				print("the 2 way")
				print(table_death_counter[block.Parent.Name])
				print(table_death_counter)

				if table_death_counter[block.Parent.Name] ~= nil then
					for parent, value in pairs(table_death_counter) do
						if value < 3 then
							table_death_counter[block.Parent.Name] = nil
						end
					end
				end

				platformTouched:FireClient(player, otherPart, block, debounce_platforms)
			end
		end
	end)
end

-- need to fix getting the parent and the coin
-- once debounce is set for the coin send the debounce to the client

local can_be_touched = {}
local debounce_coins = {}

coinValue.OnServerEvent:Connect(function(player, can_touch_cl)
	can_be_touched = can_touch_cl

	for _, blocks_table in pairs(cached_coins) do
		for _, blocks in pairs(blocks_table) do
			blocks.Transparency = 0
		end
	end
end)

coinLoop.OnServerEvent:Connect(function(player, can_be_touched)
	for parent, blocks_table in pairs(cached_coins) do
		for _, blocks in pairs(blocks_table) do

			blocks.Touched:Connect(function(otherPart)
				local humanoid = otherPart.Parent:FindFirstChild("Humanoid")
				local player = game.Players:GetPlayerFromCharacter(otherPart.Parent)
				local player_userId = tostring(player.UserId)

				if player and humanoid and can_be_touched[player_userId] ~= nil then

					--if not debounce_coins[player_userId] then -- ai
					print(debounce_coins)

					-- idk if its the proper way but so far works
					if debounce_coins[player_userId] ~= nil and debounce_coins[player_userId][blocks.Name] ~= nil then
						debounce_coins[player_userId][blocks.Name] = nil
					end

					if not debounce_coins[player_userId] then
						debounce_coins[player_userId] = {}
					end

					if not debounce_coins[player_userId][blocks.Name] then -- ai
						debounce_coins[player_userId][blocks.Name] = blocks.Parent.Name

						debounceToClient:FireClient(player, debounce_coins)
						blocks.Transparency = 1
					end
				end
			end)
		end
	end

end)

debounceToServer.onServerEvent:Connect(function(received_dbc)
	debounce_coins = received_dbc
end)

respawnEvent.OnServerEvent:Connect(function(player, respawnPosition, platforms_cl, counter_cl)
	playerRespawns = respawnPosition
	debounce_platforms = platforms_cl
	stage_sv = counter_cl

	print("respawnEvent.OnServerEvent")
	print(playerRespawns)
	print(debounce_platforms)
	print(stage_sv)
end)

local cnt = 0

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

	--	sendCache:FireClient(player, cached_coins, cached_platforms)

	player.CharacterAdded:Connect(function(character) 
		local rootPart = character:WaitForChild("HumanoidRootPart", 5)
		local player_userId = tostring(player.UserId)

		task.wait(0.1)
		sendCache:FireClient(player, cached_coins, cached_platforms)

		if rootPart and playerRespawns[player_userId] then

			print("server")

			-- count the stages of a player (length of stage_sv)
			local last_stage = 0
			for _, _ in pairs(stage_sv[player_userId]) do
				last_stage += 1
			end

			-- code to get the last stage and then do something with it.
			local i = 0
			for parent, value in pairs(stage_sv[player_userId]) do -- parent needed
				i = i + 1

				if i == last_stage then
					stage_sv[player_userId][parent] = stage_sv[player_userId][parent] + 1
				end
			end

			print("😡😡😡")
			print(stage_sv)
			-- final phase
			for parent, health in pairs(stage_sv[player_userId]) do -- parent needed

				if health == 3 then
					print("tuff shit")
					print(parent)
					playerRespawns[player_userId][parent] = nil
					debounce_platforms[player_userId][parent] = nil
					stage_sv[player_userId][parent] = nil

					--table_death_counter[parent] = nil

					-- works this way but i want to do so every time 1 got removed
					--if player.leaderstats.Coins.Value > 0 then
					--player.leaderstats.Coins.Value -= stages[tostring(parent)]["Points"]
					--end
				end
			end

			-- count the locations of a player (length of playerRespawns)
			local last_spawn = 0
			for _, _ in pairs(playerRespawns[player_userId]) do
				last_spawn += 1
			end

			local increment = 0

			for parent, _ in pairs(playerRespawns[player_userId]) do
				increment += 1

				if increment == last_spawn then
					character:MoveTo(playerRespawns[player_userId][parent])

					if player.leaderstats.Stage_Health.Value > 0 then
						player.leaderstats.Stage_Health.Value -= 1
					end

					if player.leaderstats.Stage_Health.Value == 0 then
						player.leaderstats.Stage_Health.Value = stages[parent]["Health"]
					end

					if stages[parent]["Points"] == cnt then
						cnt = 0
					else
						player.leaderstats.Coins.Value -= 1
						cnt += 1
					end
				end
			end

			if last_spawn == 0 then
				character:MoveTo(Vector3.new(21.88815689086914, 7.835575580596924, 30.61795425415039))

				player.leaderstats.Stage_Health.Value = 0
			end

			print("before server to client | server")
			print(debounce_platforms)
			print(playerRespawns)
			print(stage_sv)

			task.wait(1)
			debounceEvent:FireClient(player, debounce_platforms, playerRespawns, stage_sv)
		end
	end)
end)