-- panic.lua
-- Copyright (c) 2026 Pancakse
-- SPDX-License-Identifier: BSD-3-Clause
-- trigger a kernel panic for testing

local args = { ... }
local reason = table.concat(args, " ")

if reason == "" then
    reason = "Manual panic triggered"
end

if aether and aether.kernel and aether.kernel.panic then
    aether.kernel:panic(reason, { source = "panic command" })
else
    print("panic: kernel panic handler is unavailable")
end