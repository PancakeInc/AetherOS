--startup.lua
-- Copyright (c) 2026 Pancakse
-- SPDX-License-Identifier: BSD-3-Clause

-- ---------------------------------------------------------------------
-- Secure boot (CCSecureBoot). pxboot only verifies THIS file, so it has
-- to vouch for everything else: /boot.sums lists a SHA-256 for every
-- system file and is itself signed (/boot.sums.sig). Nothing below this
-- block runs unless the signature and every hash check out. If the
-- computer isn't enrolled in secure boot this whole block is skipped.
-- ---------------------------------------------------------------------
do
    if fs.exists("/rom/pxboot/certs/enrolled/" .. os.computerID()) then
        local function halt(msg)
            term.setBackgroundColor(colors.black)
            term.setTextColor(colors.red)
            print("SECURE BOOT: " .. msg)
            term.setTextColor(colors.white)
            print("Boot halted. Insert the key disk and reboot to use the boot menu.")
            while true do os.pullEventRaw() end
        end

        -- Always load codesign from ROM with dofile, never via require.
        local codesign = dofile("/rom/modules/main/codesign.lua")

        local okSig, sigErr = codesign.verify("/boot.sums")
        if not okSig then halt("/boot.sums is not validly signed: " .. tostring(sigErr)) end

        -- Only look in ROM for the hash library so a local file can't shadow it.
        local savedPath = package.path
        package.path = "/rom/modules/main/?.lua;/rom/modules/main/?/init.lua"
        local sha256 = require("ccryptolib.sha256")
        package.path = savedPath

        local function hex(s)
            return (s:gsub(".", function(c) return ("%02x"):format(c:byte()) end))
        end

        local list = fs.open("/boot.sums", "r")
        local entries = {}
        for line in list.readAll():gmatch("[^\r\n]+") do
            local sum, path = line:match("^(%x+)  (.+)$")
            if sum then entries[#entries + 1] = { sum = sum, path = path } end
        end
        list.close()
        if #entries == 0 then halt("/boot.sums is empty") end

        term.setTextColor(colors.lightGray)
        local _, row = term.getCursorPos()
        for i, e in ipairs(entries) do
            term.setCursorPos(1, row)
            term.clearLine()
            term.write(("Verifying system files %d/%d"):format(i, #entries))
            local f = fs.open("/" .. e.path, "rb")
            if not f then halt("missing file: " .. e.path) end
            local data = f.readAll()
            f.close()
            if hex(sha256.digest(data)) ~= e.sum then halt("file was modified: " .. e.path) end
            sleep(0) -- yield so a big file can't trip the "too long without yielding" timeout
        end
        print("")
        term.setTextColor(colors.white)
    end
end


local bootPath = "boot/init.lua"

local function read_boot_mode()
    if not fs.exists("/etc/bootmode") then
        return nil
    end

    local file = fs.open("/etc/bootmode", "r")
    if not file then
        return nil
    end

    local mode = file.readAll()
    file.close()
    if mode then
        mode = mode:gsub("^%s+", ""):gsub("%s+$", "")
    end
    return mode ~= "" and mode or nil
end

local function clear_boot_mode()
    if fs.exists("/etc/bootmode") then
        fs.delete("/etc/bootmode")
    end
end

local function path_exists(path)
    if not path or path == "" then
        return true
    end
    path = path:gsub("^/", "")
    return fs.exists(path)
end

local function setBootMode(mode)
    if not fs.exists("/etc") then
        fs.makeDir("/etc")
    end

    if mode and mode ~= "" then
        local file = fs.open("/etc/bootmode", "w")
        if file then
            file.write(mode)
            file.close()
        end
    else
        clear_boot_mode()
    end
end

local function read_local_version()
    if fs.exists("version.lua") then
        local f = fs.open("version.lua", "r")
        if f then
            local chunk = f.readAll()
            f.close()
            local v = chunk:match('return%(%s*"(.-)"%s*%)') or chunk:match('return%s+"(.-)"')
            if v and #v > 0 then return v end
        end
    end
    if fs.exists("version.txt") then
        local f = fs.open("version.txt", "r")
        if f then
            local v = f.readLine()
            f.close()
            if v then v = v:match("^%s*(.-)%s*$") end
            if v and #v > 0 then return v end
        end
    end
    return nil
end

package.preload["version"] = package.preload["version"] or function()
    return read_local_version() or "unknown"
end

local ok, ver = pcall(require, "version")
local version = ok and ver or "unknown"

local bootMode = read_boot_mode()
if bootMode == "recovery" then
    clear_boot_mode()
    shell.run("/recovery.lua")
    return
elseif bootMode and bootMode ~= "normal" then
    clear_boot_mode()
end

local function missing_manifest_files()
    if not fs.exists("manifest.txt") then
        return { "manifest.txt" }
    end

    local file = fs.open("manifest.txt", "r")
    if not file then
        return { "manifest.txt" }
    end

    local missing = {}
    for line in file.readAll():gmatch("[^\r\n]+") do
        local path = line:gsub("^%s+", ""):gsub("%s+$", "")
        if path ~= "" and not path:match("^#") and not path_exists(path) then
            table.insert(missing, path)
        end
    end
    file.close()
    return missing
end

local missingFiles = missing_manifest_files()
if #missingFiles > 0 then
    term.setTextColor(colors.red)
    print("ERROR: Required files are missing:")
    for _, path in ipairs(missingFiles) do
        print("  - " .. path)
    end
    print("")
    print("Entering recovery mode...")
    sleep(1.5)
    setBootMode("recovery")
    shell.run("/recovery.lua")
    return
end

if not fs.exists(bootPath) then
    term.setTextColor(colors.red)
    print("ERROR: System could not boot:")
    print("Core boot script missing at " .. bootPath)
    print("Rebooting to recovery")
    sleep(2)
    setBootMode("recovery")
    os.reboot()
    return
end

term.clear()
term.setCursorPos(1,1)
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)

local success, err = pcall(function()
    print("Welcome to AetherOS")
    sleep(1)
    print("Version: " .. version)
    sleep(0.5)
    print("Booting...")
    sleep(1)
    shell.run(bootPath)
end)

if not success then
    term.setTextColor(colors.red)
    print("ERROR: System could not boot: ")
    print(tostring(err))
    print("")
    print("Going to recovery shell")
    term.setTextColor(colors.white)
    shell.run("recovery.lua")
end
