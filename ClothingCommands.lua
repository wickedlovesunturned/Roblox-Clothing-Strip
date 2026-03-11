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

-- ClothingCommands (LocalScript — StarterPlayerScripts)

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService   = game:GetService("TextChatService")

local player     = Players.LocalPlayer
local Remotes    = ReplicatedStorage:WaitForChild("ClothingRemotes", 15)
local ToggleClothing = Remotes:WaitForChild("ToggleClothing", 10)
local SyncClothing   = Remotes:WaitForChild("SyncClothing", 10)

local COMMANDS = {
	["/hat"]   = "hat",
	["/hair"]  = "hair",
	["/back"]  = "back",
	["/waist"] = "waist",
	["/shirt"] = "shirt",
	["/pants"] = "pants",
}

local function onChat(message)
	local cmd = message:lower():match("^(/[%a]+)")
	if not cmd then return end
	local slot = COMMANDS[cmd]
	if not slot then return end
	ToggleClothing:FireServer(slot)
end

SyncClothing.OnClientEvent:Connect(function(_) end)

if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
	TextChatService.SendingMessage:Connect(function(msg)
		onChat(msg.Text)
	end)
else
	player.Chatted:Connect(onChat)
end

-- — Built by Wicked Development | github.com/wickedlovesunturned
