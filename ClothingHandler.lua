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
 *  Version  : 1.0.0
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
	playerData[player.UserId] = playerData[player.UserId] or { state = {}, originalDesc = nil }
	return playerData[player.UserId]
end

-- Method 1: AccessoryType (R15 tagged)
local ACCESSORY_TYPE_SLOTS = {
	hat   = { Enum.AccessoryType.Hat },
	hair  = { Enum.AccessoryType.Hair },
	back  = { Enum.AccessoryType.Back },
	waist = { Enum.AccessoryType.Waist },
}

-- Method 2: Attachment names inside Handle (R6 / ACS / untagged)
local ATTACHMENT_SLOTS = {
	hat   = { "HatAttachment", "TopScaleAttachment", "FaceFrontAttachment", "FaceBackAttachment" },
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
			for _, name in ipairs(names) do
				if handle:FindFirstChild(name) then return slot end
			end
		end
	end
	return nil
end

-- Strip toggled accessories directly off the character
local function stripAccessories(character, state)
	for _, obj in ipairs(character:GetChildren()) do
		if obj:IsA("Accessory") then
			local slot = getAccessorySlot(obj)
			if slot and state[slot] then
				obj:Destroy()
			end
		end
	end
end

local function applyToPlayer(player)
	local data = getData(player)
	if not data.originalDesc then return end

	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Build a clean desc clone
	local desc = data.originalDesc:Clone()

	-- Zero out shirt/pants if toggled off
	if data.state.shirt then
		desc.Shirt         = 0
		desc.GraphicTShirt = 0
	end
	if data.state.pants then
		desc.Pants = 0
	end

	-- Apply — this re-adds everything from the saved original desc
	humanoid:ApplyDescription(desc)

	-- After apply, strip accessories that are still toggled off
	-- task.defer runs next frame, after ApplyDescription finishes adding accessories
	local stateSnapshot = {}
	for k, v in pairs(data.state) do stateSnapshot[k] = v end

	task.defer(function()
		character = player.Character
		if not character then return end
		stripAccessories(character, stateSnapshot)
	end)

	SyncClothing:FireClient(player, data.state)
end

local function onCharacterAdded(player, character)
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then return end

	local data = getData(player)

	-- Wait for ACS and game systems to finish dressing the character
	-- then snapshot whatever is actually on the character as the source of truth
	task.wait(2)

	character = player.Character
	if not character then return end
	humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	data.originalDesc = humanoid:GetAppliedDescription()

	-- Re-apply state if any slots are toggled (e.g. after death)
	local hasAny = false
	for _, v in pairs(data.state) do if v then hasAny = true; break end end
	if hasAny then
		applyToPlayer(player)
	end
end

local VALID_SLOTS = { hat=true, hair=true, back=true, waist=true, shirt=true, pants=true }

ToggleClothing.OnServerEvent:Connect(function(player, slot)
	slot = tostring(slot):lower()
	if not VALID_SLOTS[slot] then return end
	local data = getData(player)
	data.state[slot] = not data.state[slot]
	applyToPlayer(player)
end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	playerData[player.UserId] = nil
end)

-- — Built by Wicked Development | github.com/wickedlovesunturned
