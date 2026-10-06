--!strict

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GoldDataStore = DataStoreService:GetDataStore("PlayerGoldData_v2")

-- Session-based cache to minimize DataStore budget calls
local PlayerDataCache: { [number]: { Gold: number, Inventory: { string } } } = {}

-- Ensure networking instances exist
local BuyItemEvent = ReplicatedStorage:FindFirstChild("BuyItemEvent") :: RemoteEvent
if not BuyItemEvent then
	BuyItemEvent = Instance.new("RemoteEvent")
	BuyItemEvent.Name = "BuyItemEvent"
	BuyItemEvent.Parent = ReplicatedStorage
end

local ShopCatalog = require(ReplicatedStorage:WaitForChild("ShopCatalog") :: ModuleScript)

local DEFAULT_GOLD = 500

local function loadPlayerData(player: Player)
	local savedGold = DEFAULT_GOLD

	local success, result = pcall(function()
		return GoldDataStore:GetAsync(tostring(player.UserId))
	end)

	if success and result then
		savedGold = result
	elseif not success then
		warn("[DataManager] Failed to load data for " .. player.Name .. ": " .. tostring(result))
	end

	PlayerDataCache[player.UserId] = {
		Gold = savedGold,
		Inventory = {},
	}

	-- Create leaderstats folder for default client display
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local goldStat = Instance.new("IntValue")
	goldStat.Name = "Gold"
	goldStat.Value = savedGold
	goldStat.Parent = leaderstats

	-- Sync external value changes (e.g., coins, admin commands) to session cache
	goldStat.Changed:Connect(function(newValue: number)
		if PlayerDataCache[player.UserId] then
			PlayerDataCache[player.UserId].Gold = newValue
		end
	end)
end

local function savePlayerData(player: Player)
	local sessionData = PlayerDataCache[player.UserId]
	if not sessionData then return end

	local success, err = pcall(function()
		GoldDataStore:SetAsync(tostring(player.UserId), sessionData.Gold)
	end)

	if not success then
		warn("[DataManager] Failed to save data for " .. player.Name .. ": " .. tostring(err))
	end

	PlayerDataCache[player.UserId] = nil
end

-- Server Events
Players.PlayerAdded:Connect(loadPlayerData)
Players.PlayerRemoving:Connect(savePlayerData)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(loadPlayerData, player)
end

-- Save data during server shutdown
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		savePlayerData(player)
	end
end)

-- Handle purchase requests from client UI
BuyItemEvent.OnServerEvent:Connect(function(player: Player, itemId: string)
	local sessionData = PlayerDataCache[player.UserId]
	local itemInfo = ShopCatalog[itemId]

	-- Sanity checks
	if not sessionData or not itemInfo then
		warn("[Shop] Invalid request from " .. player.Name)
		return
	end

	-- Check double purchase
	if table.find(sessionData.Inventory, itemId) then
		warn("[Shop] Player " .. player.Name .. " already owns " .. itemId)
		return
	end

	-- Check funds
	if sessionData.Gold < itemInfo.Price then
		warn("[Shop] Insufficient balance for " .. player.Name)
		return
	end

	-- Deduct & reward
	sessionData.Gold -= itemInfo.Price
	table.insert(sessionData.Inventory, itemId)

	-- Update leaderstats display
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local goldStat = leaderstats:FindFirstChild("Gold") :: IntValue
		if goldStat then
			goldStat.Value = sessionData.Gold
		end
	end
end)
