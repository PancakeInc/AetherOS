-- craftos.lua
-- Copyright (c) 2026 Pancakse
-- SPDX-License-Identifier: BSD-3-Clause
-- starts a stock CraftOS shell session

local romShell = "/rom/programs/shell.lua"

if not fs.exists(romShell) then
    print("craftos: CraftOS shell not found at " .. romShell)
    return
end

print("Starting CraftOS shell (type 'exit' to return to AetherOS)...")
shell.run(romShell)
print("Returned to AetherOS shell.")