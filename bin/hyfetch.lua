-- hyfetch.lua
-- Copyright (c) 2026 Pancakse
-- SPDX-License-Identifier: BSD-3-Clause
-- colorful system summary inspired by hyfetch

local version = (aether and aether.version) or "unknown"

local config = (aether and aether.config) or dofile("/lib/config.lua")
local util = dofile("/lib/util.lua")

local uptimeSeconds = (aether and aether.kernel) and (os.clock() - aether.kernel.bootTime) or os.clock()

local lines = {
    { "OS", "AetherOS " .. version },
    { "Host", config.get("hostname") or "aether" },
    { "Runtime", _HOST or "CC:Tweaked" },
    { "Uptime", util.formatUptime(uptimeSeconds) },
    { "Shell", "/shell.lua" },
    { "Terminal", term.isColor() and "Advanced (color)" or "Standard" },
    { "Resolution", select(1, term.getSize()) .. "x" .. select(2, term.getSize()) },
    { "Free space", util.formatBytes(fs.getFreeSpace("/")) },
}

local art = {
    "      .--.      ",
    "   .-(    ).    ",
    "  (___.__)__)   ",
    "                ",
}

local pride = {
    colors.red,
    colors.orange,
    colors.yellow,
    colors.lime,
    colors.cyan,
    colors.blue,
    colors.purple,
}

if not term.isColor() then
    shell.run("/bin/neofetch.lua")
    return
end

for i, row in ipairs(art) do
    term.setTextColor(pride[((i - 1) % #pride) + 1])
    print(row)
end
term.setTextColor(colors.white)

print("")
for i, entry in ipairs(lines) do
    term.setTextColor(pride[((i - 1) % #pride) + 1])
    term.write(("%-12s"):format(entry[1]))
    term.setTextColor(colors.white)
    print(entry[2])
end

print("")
term.setTextColor(colors.lightGray)
for i = 1, #pride do
    term.setBackgroundColor(pride[i])
    term.write("  ")
end
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
print("")