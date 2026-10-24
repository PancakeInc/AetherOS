-- gui.lua
-- Copyright (c) 2026 Pancakse
-- SPDX-License-Identifier: BSD-3-Clause
-- Launches the AetherOS desktop session.

if not term.isColor() then
	print("gui: advanced/color terminal required for desktop mode.")
	print("Falling back to terminal shell.")
	return
end

if not fs.exists("/lib/desktop.lua") then
	print("gui: desktop session is missing (/lib/desktop.lua).")
	return
end

local ok, err = pcall(dofile, "/lib/desktop.lua")
if not ok then
	term.setTextColor(colors.red)
	print("gui: desktop crashed: " .. tostring(err))
	term.setTextColor(colors.white)
end
