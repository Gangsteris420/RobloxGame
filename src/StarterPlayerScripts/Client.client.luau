local replicated_storage = game.ReplicatedStorage
local killPart = game.Workspace.Obby:WaitForChild("KillPart")

-- need to rework this part completely
local buttonEvent = replicated_storage:FindFirstChild("ButtonTouched")
local platformEvent = replicated_storage:FindFirstChild("PlatformTouched")
local updateCache = replicated_storage:FindFirstChild("UpdateCache")
--local receivedDebounce = replicated_storage:FindFirstChild("SendCache")
local debounceEvent = replicated_storage:FindFirstChild("DebounceEvent")
local respawnEvent = replicated_storage:FindFirstChild("RespawnEvent")
local coinLoop = replicated_storage:FindFirstChild("CoinLoop")
local coinValue = replicated_storage:FindFirstChild("CoinValue")
local debounceToClient = replicated_storage:FindFirstChild("DebounceToClient")
--local debounceToServer = replicated_storage:FindFirstChild("DebounceToServer")

-- need to rework this part completely (how information is being passed to each client and server and from each other)
-- then bugs can also be worked out because now how the information is being passed
-- is very random and mostly confusing

local stages = {
	["Stage1"] = {
		["Points"] = 2, -- points to complete
		["Time"] = 10, -- seconds to finish
		["Health"] = 3 -- lives per stage
	},

	["Stage2"] = {
		["Points"] = 2,
		["Time"] = 5,
		["Health"] = 3
	},
}

local cached_coins = {}
local can_be_touched = {}

local debounce_platforms = {}
local debounce_buttons = {}
local debounce_coins = {}

-- example on how a certain instance can be found using a saved part String name from a dictionary that is sent from server to client.
-- 1. a dictionary received from server is being looped over
-- 2. requires some nested looping to acquire the model(s)
-- 3. once the model(s) are acquired then they are being looped over
-- 4. model is being looped over and parts are being received, then a String part from the dictionary is being checked with String part from the model
-- 5. if they are equal, the actual part/model (its instance) can be found.

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

buttonEvent.OnClientEvent:Connect(function(otherPart, platform, debounce_buttons_sv)
	print("was it even received??")
	debounce_buttons = debounce_buttons_sv
	ButtonTouched(otherPart, platform)
end)

function ButtonTouched(otherPart, platform)
	local humanoid = otherPart.Parent:FindFirstChild("Humanoid")
	local player = game.Players:GetPlayerFromCharacter(otherPart.Parent)
	local player_userId = tostring(player.UserId)

	--coinLoop:FireServer()

	if can_be_touched[player.UserId] == nil then
		can_be_touched[player.UserId] = true

		coinLoop:FireServer(can_be_touched)

		platform.Transparency = 1
		platform.CanCollide = false

		local stages_ = stages[platform.Parent.name]["Time"]
		for i = 1, stages_, 1 do
			task.wait(1)
			print(i)

			if i == stages_ or humanoid.Health == 0 or debounce_platforms[player_userId] ~= nil and debounce_platforms[player_userId][platform.Parent.name] ~= nil then
				can_be_touched[player.UserId] = nil
				coinValue:FireServer(can_be_touched)

				platform.Transparency = 0
				platform.CanCollide = true

				clear_debounce(platform, otherPart)

				debounce_buttons[player_userId][platform.Parent.Name] = nil
				updateCache:FireServer(debounce_buttons, platform.Parent.Name)

				print("loop stopped")
				print(debounce_buttons)

				--for _, block in pairs(cached_coins) do
				--block.Transparency = 0
				--end

				break
			end
		end
	end
end

debounceToClient.OnClientEvent:Connect(function(d_coins)
	debounce_coins = d_coins
end)

platformEvent.OnClientEvent:Connect(function(otherPart, platform, debounce_platforms_sv)
	debounce_platforms = debounce_platforms_sv
	PlatformTouched(otherPart, platform)
end)

local respawn_locations = {}
local respawn_health_counter = {}
local leaderstats_ = {}

function PlatformTouched(otherPart, platform)
	local humanoid = otherPart.Parent:FindFirstChild("Humanoid") 

	if humanoid then
		local player = game.Players:GetPlayerFromCharacter(otherPart.Parent)
		local player_userId = tostring(player.UserId)

		local count = 0
		for key, value in pairs(debounce_coins[player_userId]) do

			if value == platform.Parent.Name then
				count = count + 1
			end
		end

		if stages[platform.Parent.name]["Points"] == count then
			player.leaderstats.Coins.Value += stages[platform.Parent.name]["Points"]

			if not leaderstats_[platform.Parent.name] then
				leaderstats_[platform.Parent.name] = stages[platform.Parent.name]["Points"]
			end

			print("You have collected all of the coins!")
			task.wait(0.1)

			if not respawn_locations[player_userId] then
				respawn_locations[player_userId] = {}
			end

			if not respawn_locations[player_userId][platform.Parent.Name] then
				respawn_locations[player_userId][platform.Parent.Name] = player.Character.HumanoidRootPart.Position
			end

			if respawn_health_counter[player_userId] ~= nil then
				for parent, value in pairs(respawn_health_counter[player_userId]) do
					if value < 3 then
						respawn_health_counter[player_userId][parent] = nil
					end
				end
			end
		else
			print("You HAVEN'T collected the coins for the next stage, try again!")
		end        
	end
end

function clear_debounce(platform, otherPart)
	local player = game.Players:GetPlayerFromCharacter(otherPart.Parent)
	local platform_parent = platform.Parent.Name
	local player_userId = tostring(player.UserId)

	-- counts how many coins are there for each stage
	local count = 0
	if debounce_coins[player_userId] ~= nil then
		for block, parent in pairs(debounce_coins[player_userId]) do
			for _, model in ipairs(game.Workspace.Obby:GetChildren()) do
				if parent == model.Name then
					count += 1
				end
			end
			--if platform_parent == parent then
			--count += 1
			--end
		end
	end

	-- counts whether there is more than 0 platforms
	local count_platforms = 0

	if debounce_platforms[player_userId] ~= nil then
		for parent, _ in pairs(debounce_platforms[player_userId]) do
			if platform_parent == parent then
				count_platforms = count_platforms + 1
			end
		end 
	end

	-- resets blocks if blocks are collected and the platform is reached
	if count_platforms > 0 then
		--for _, parent in pairs(debounce_platforms) do
		for parent, _ in pairs(debounce_platforms[player_userId]) do
			if parent == platform_parent then
				-- if required amount of coins is collected and the platform is reached
				for coin, parent in pairs(debounce_coins[player_userId]) do
					if platform_parent == parent then
						if count == stages[platform_parent]["Points"] then
							debounce_coins[player_userId][coin] = nil
						elseif count < stages[platform_parent]["Points"] then -- if the coins were collected not fully and the platform was reached
							debounce_coins[player_userId][coin] = nil
							debounce_platforms[player_userId][parent] = nil -- might bug

							respawnPlayer(player, platform) -- reset player to point where he starts the stage from again
						end 
					end
				end
			end
		end
		-- resets blocks if blocks are collected but the platform isn't reached
	elseif count_platforms == 0 then 
		if count == 0 then -- check if no coin blocks are collected
			respawnPlayer(player, platform)
		else -- if there are loop through every block and remove it
			for coin, parent in pairs(debounce_coins[player_userId]) do

				if platform.Parent.Name == parent then
					print("block collected: ", coin)
					debounce_coins[player_userId][coin] = nil
					respawnPlayer(player, platform) -- reset player to point where he starts the stage from again
				end
			end
		end

		--debounceToServer:FireServer(debounce_coins)
	end
end

function respawnPlayer(player, platform)
	-- check if there is a player saved, and if there is loop through spawn locations
	local respawn_count = 0
	local default_spawn = Vector3.new(21.88815689086914, 7.835575580596924, 30.61795425415039)
	local player_userId = tostring(player.UserId)

	if respawn_locations[player_userId] ~= nil then
		for _, _ in pairs(respawn_locations[player_userId]) do
			respawn_count += 1
		end
	end

    -- if there are locations
	if respawn_count > 0 then
		print("#respawn > 0")
		local i = 0
		for parent, _ in pairs(respawn_locations[player_userId]) do
			i = i + 1

			if i == respawn_count then
				player.Character:MoveTo(respawn_locations[player_userId][parent])
			end
		end
		-- handle if there arent any locations (use default spawn coords) 
	elseif respawn_count == 0 then
		print("#respawn == 0")
		print(respawn_locations)
		player.Character:MoveTo(default_spawn)
	end
end

local killpart_debounce = {}

debounceEvent.OnClientEvent:Connect(function(platforms_sv, respawns_sv, stage_sv, coins_sv)
	debounce_platforms = platforms_sv
	respawn_locations = respawns_sv
	respawn_health_counter = stage_sv
end)

-- might need to put to server side or maybe might not, NOT SURE

killPart.Touched:Connect(function(otherPart) 
	local humanoid = otherPart.Parent:FindFirstChild("Humanoid") 

	if humanoid then
		local player = game.Players:GetPlayerFromCharacter(otherPart.Parent)
		local player_userId = tostring(player.UserId)

		humanoid.Health = 0

		local respawn_count = 0
		if respawn_locations[player_userId] ~= nil then
			for _, _ in pairs(respawn_locations[player_userId]) do
				respawn_count += 1
			end
		end

		-- check if there are coordinates saved
		local health_for_sv = 0
		if respawn_count > 0 then
			local i = 0
			for parent, _ in pairs(respawn_locations[player_userId]) do
				i = i + 1
				-- print(i, respawn_count, parent) -- debug

				if i == respawn_count then
					if not respawn_health_counter[player_userId] then
						respawn_health_counter[player_userId] = {}
					end

					if not respawn_health_counter[player_userId][parent] then
						respawn_health_counter[player_userId][parent] = 0
					end
				end
			end


			respawnEvent:FireServer(respawn_locations, debounce_platforms, respawn_health_counter)
		end
	end
end)