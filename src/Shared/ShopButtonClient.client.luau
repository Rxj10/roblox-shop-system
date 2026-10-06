--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BuyItemEvent = ReplicatedStorage:WaitForChild("BuyItemEvent") :: RemoteEvent

local button = script.Parent :: TextButton
local ITEM_ID = "SpeedBoots"

local function onPurchaseClicked()
	button.Active = false
	BuyItemEvent:FireServer(ITEM_ID)
	
	-- Small cooldown to prevent spamming
	task.wait(0.5)
	button.Active = true
end

button.MouseButton1Click:Connect(onPurchaseClicked)
