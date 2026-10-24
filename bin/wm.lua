-- wm.lua
-- Copyright (c) 2026 Pancakse
-- SPDX-License-Identifier: BSD-3-Clause
-- simple window manager command wrapper

local args = { ... }
local sub = args[1] or "start"

if sub == "start" then
    shell.run("/bin/gui.lua")
    return
end

if sub == "help" or sub == "--help" or sub == "-h" then
    print("usage: wm [start]")
    print("  start  Start the desktop/window manager session.")
    return
end

print("wm: unknown subcommand '" .. tostring(sub) .. "'")
print("usage: wm [start]")