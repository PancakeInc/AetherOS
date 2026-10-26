-- seal.lua
-- Copyright (c) 2026 Pancakse
-- SPDX-License-Identifier: BSD-3-Clause
-- Re-seals AetherOS for CCSecureBoot: hashes every system file into
-- /boot.sums, then signs /boot.sums and /startup.lua with the key disk.
-- Run it (with the key disk inserted) after install, after every update,
-- and after editing any system file.
-- usage: seal

local DIRS = { "boot", "kernel", "lib", "bin", "sbin", "apps", "recovery", "templates" }
local ROOT_FILES = { "version.txt", "version.lua", "manifest.txt", "shell.lua", "recovery.lua", "netinstall.lua" }

local savedPath = package.path
package.path = "/rom/modules/main/?.lua;/rom/modules/main/?/init.lua"
local sha256 = require("ccryptolib.sha256")
package.path = savedPath

local function hex(s)
    return (s:gsub(".", function(c) return ("%02x"):format(c:byte()) end))
end

local files = {}
local function walk(dir)
    for _, name in ipairs(fs.list(dir)) do
        local p = fs.combine(dir, name)
        if fs.isDir(p) then walk(p) elseif p:match("%.lua$") or p:match("%.json$") or p:match("%.md$") or p:match("%.txt$") then
            files[#files + 1] = p
        end
    end
end
for _, d in ipairs(DIRS) do if fs.exists(d) then walk(d) end end
for _, f in ipairs(ROOT_FILES) do if fs.exists(f) then files[#files + 1] = f end end
table.sort(files)

if #fs.find("/disk*/secure-boot-*.key") == 0 then
    printError("Insert the secure boot key disk first.")
    return
end

local out = {}
for i, path in ipairs(files) do
    -- startup.lua is verified directly by pxboot; boot.sums is the list itself.
    local f = fs.open(path, "rb")
    local data = f.readAll()
    f.close()
    out[#out + 1] = hex(sha256.digest(data)) .. "  " .. path
    term.setCursorPos(1, select(2, term.getCursorPos()))
    term.clearLine()
    term.write(("Hashing %d/%d"):format(i, #files))
    sleep(0)
end
print("")

local h = fs.open("/boot.sums", "w")
h.write(table.concat(out, "\n") .. "\n")
h.close()

-- ROM 'sign' handles the key disk and password prompt.
print("Signing /boot.sums...")
shell.run("sign", "/boot.sums")
print("Signing /startup.lua...")
shell.run("sign", "/startup.lua")

if fs.exists("/boot.sums.sig") and fs.exists("/startup.lua.sig") then
    term.setTextColor(colors.lime)
    print("Sealed " .. #files .. " files.")
    term.setTextColor(colors.white)
else
    printError("Signing failed - system is NOT sealed.")
end
