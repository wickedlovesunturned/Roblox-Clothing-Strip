--[[
 * ██╗    ██╗██╗ ██████╗██╗  ██╗███████╗██████╗
 * ██║    ██║██║██╔════╝██║ ██╔╝██╔════╝██╔══██╗
 * ██║ █╗ ██║██║██║     █████╔╝ █████╗  ██║  ██║
 * ██║███╗██║██║██║     ██╔═██╗ ██╔══╝  ██║  ██║
 * ╚███╔███╔╝██║╚██████╗██║  ██╗███████╗██████╔╝
 *  ╚══╝╚══╝ ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═════╝
 *
 *  W I C K E D   D E V E L O P M E N T
 * ─────────────────────────────────────────────
 *  Project  : wClothing
 *  Author   : Wicked
 *  Version  : 1.0.1
 *  Built    : 2026
 * ─────────────────────────────────────────────
 *  © Wicked Development — All Rights Reserved
--]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:FindFirstChild("ClothingRemotes") or Instance.new("Folder")
Remotes.Name   = "ClothingRemotes"
Remotes.Parent = ReplicatedStorage

local function getRemote(name)
	local r = Remotes:FindFirstChild(name)
	if not r then
		r = Instance.new("RemoteEvent")
		r.Name, r.Parent = name, Remotes
	end
	return r
end

local ToggleClothing = getRemote("ToggleClothing")
local SyncClothing   = getRemote("SyncClothing")

local playerData = {}

local function getData(player)
	if not playerData[player.UserId] then
		playerData[player.UserId] = { state = {}, shirtId = 0, pantsId = 0, hidden = {} }
	end
	return playerData[player.UserId]
end

local ACCESSORY_TYPE_SLOTS = {
	hat   = { Enum.AccessoryType.Hat },
	hair  = { Enum.AccessoryType.Hair },
	back  = { Enum.AccessoryType.Back },
	waist = { Enum.AccessoryType.Waist },
}

local ATTACHMENT_SLOTS = {
	hat   = { "HatAttachment", "TopScaleAttachment" },
	hair  = { "HairAttachment" },
	back  = { "BodyBackAttachment" },
	waist = { "WaistBackAttachment", "WaistFrontAttachment", "WaistCenterAttachment" },
}

local function getAccessorySlot(accessory)
	if accessory.AccessoryType ~= Enum.AccessoryType.Unknown then
		for slot, types in pairs(ACCESSORY_TYPE_SLOTS) do
			for _, t in ipairs(types) do
				if accessory.AccessoryType == t then return slot end
			end
		end
	end
	local handle = accessory:FindFirstChild("Handle")
	if handle then
		for slot, names in pairs(ATTACHMENT_SLOTS) do
			for _, attachName in ipairs(names) do
				if handle:FindFirstChild(attachName) then return slot end
			end
		end
	end
	return nil
end

local function setAccessoryVisible(accessory, visible)
	local handle = accessory:FindFirstChild("Handle")
	if not handle then return end
	local t = visible and 0 or 1
	handle.Transparency = t
	for _, part in ipairs(handle:GetDescendants()) do
		if part:IsA("BasePart") then part.Transparency = t end
	end
	for _, d in ipairs(handle:GetDescendants()) do
		if d:IsA("Decal") or d:IsA("Texture") then d.Transparency = t end
	end
end

local function removeAccessories(player, slot)
	local character = player.Character
	if not character then return false end
	local data = getData(player)
	if not data.hidden then data.hidden = {} end
	data.hidden[slot] = data.hidden[slot] or {}

	-- ✅ FIX: Check if already hidden (shouldn't re-hide)
	if data.state[slot] then
		print("[wClothing] Already hidden for slot:", slot)
		return false
	end

	local count = 0
	for _, obj in ipairs(character:GetChildren()) do
		if obj:IsA("Accessory") and getAccessorySlot(obj) == slot then
			setAccessoryVisible(obj, false)
			table.insert(data.hidden[slot], obj)
			count += 1
			print("[wClothing] Hidden:", obj.Name)
		end
	end
	if count == 0 then
		print("[wClothing] Nothing found for slot:", slot)
		return false
	end
	return true
end

local function restoreAccessories(player, slot)
	local data = getData(player)
	if not data.hidden or not data.hidden[slot] then
		print("[wClothing] No hidden table for slot:", slot)
		return
	end
	local count = 0
	for _, obj in ipairs(data.hidden[slot]) do
		if obj and obj.Parent then
			setAccessoryVisible(obj, true)
			count += 1
			print("[wClothing] Shown:", obj.Name)
		else
			print("[wClothing] Accessory gone:", tostring(obj))
		end
	end
	data.hidden[slot] = {}
	print("[wClothing] Restored", count, "for slot:", slot)
end

local function removeClothing(player, slot)
	local data = getData(player)
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local desc = humanoid:GetAppliedDescription()
	if slot == "shirt" then
		data.shirtId       = desc.Shirt
		desc.Shirt         = 0
		desc.GraphicTShirt = 0
	elseif slot == "pants" then
		data.pantsId = desc.Pants
		desc.Pants   = 0
	end
	humanoid:ApplyDescription(desc)
	data.state[slot] = true
end

local function restoreClothing(player, slot)
	local data = getData(player)
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local desc = humanoid:GetAppliedDescription()
	if slot == "shirt" then
		desc.Shirt         = data.shirtId
		desc.GraphicTShirt = 0
	elseif slot == "pants" then
		desc.Pants = data.pantsId
	end
	humanoid:ApplyDescription(desc)
	data.state[slot] = false
end

local CLOTHING_SLOTS  = { shirt = true, pants = true }
local ACCESSORY_SLOTS = { hat = true, hair = true, back = true, waist = true }
local VALID_SLOTS     = { hat=true, hair=true, back=true, waist=true, shirt=true, pants=true }

ToggleClothing.OnServerEvent:Connect(function(player, slot)
	slot = tostring(slot):lower()
	if not VALID_SLOTS[slot] then return end

	local data = getData(player)
	print("[wClothing] Toggle:", slot, "| state:", tostring(data.state[slot]))

	if ACCESSORY_SLOTS[slot] then
		if data.state[slot] then
			restoreAccessories(player, slot)
			data.state[slot] = false
		else
			local ok = removeAccessories(player, slot)
			if ok then
				data.state[slot] = true
			end
		end
	elseif CLOTHING_SLOTS[slot] then
		if data.state[slot] then
			restoreClothing(player, slot)
		else
			removeClothing(player, slot)
		end
	end

	SyncClothing:FireClient(player, data.state)
end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		local data = getData(player)
		data.state   = {}
		data.shirtId = 0
		data.pantsId = 0
		data.hidden  = {}
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	playerData[player.UserId] = nil
end)

-- — Built by Wicked Development | github.com/wickedlovesunturned
