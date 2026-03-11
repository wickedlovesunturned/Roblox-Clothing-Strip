# Clothing Strip System
### by [Wicked Development](https://github.com/wickedlovesunturned)

A lightweight Roblox clothing toggle system that lets each player independently remove and re-equip their hat, hair, back, waist, shirt, and pants using simple chat commands  no respawning, no lag, no GUI required.

---

## Features

- `/hat`, `/hair`, `/back`, `/waist`, `/shirt`, `/pants` chat commands
- Per-player state each person controls their own appearance independently
- Uses `HumanoidDescription` to apply/remove clothing instantly with no respawn
- Persists through death removed slots stay off after natural respawn---

## File Structure

```
ClothingHandler.lua     → ServerScriptService
ClothingCommands.lua    → StarterPlayerScripts
```

---

## Installation

1. Place `ClothingHandler.lua` inside **ServerScriptService** as a `Script`
2. Place `ClothingCommands.lua` inside **StarterPlayerScripts** as a `LocalScript`
3. Hit Play no additional setup required

> The system automatically creates a `ClothingRemotes` folder inside `ReplicatedStorage` at runtime.

---

## Commands

| Command  | Effect                        |
|----------|-------------------------------|
| `/hat`   | Toggle hat accessories        |
| `/hair`  | Toggle hair accessories       |
| `/back`  | Toggle back accessories       |
| `/waist` | Toggle waist accessories      |
| `/shirt` | Toggle shirt                  |
| `/pants` | Toggle pants                  |

All commands are toggles run the same command again to put the item back on.

---

## How It Works

When a player's character loads, the server fetches their full `HumanoidDescription` and stores it as their source of truth. On each toggle command, a modified clone of that description is built  zeroing out clothing IDs or filtering out accessory types for removed slots  and applied to the character via `Humanoid:ApplyDescription()`. Because the original description is always preserved, toggling back on simply rebuilds the description without the filter applied.

---

## Notes

- Accessories are matched by `Enum.AccessoryType` hat and hair are fully independent
- If a player has no shirt/pants/accessory in a given slot, the command does nothing
- Compatible with both legacy Roblox chat and the new `TextChatService`

---

## License

© Wicked Development 2026 All Rights Reserved
