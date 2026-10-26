-- speaker.lua
-- Copyright (c) 2026 Pancakse
-- SPDX-License-Identifier: BSD-3-Clause
-- control CC:Tweaked speakers: list, beep, notes, sounds, DFPWM playback
-- usage: speaker list
--        speaker beep
--        speaker chime
--        speaker note <instrument> [pitch 0-24] [volume 0-3]
--        speaker sound <sound id> [volume] [pitch]
--        speaker play <file|url> [-v volume] [-o speaker]
--        speaker stop

local audio = dofile("/lib/audio.lua")
local args = { ... }
local sub = args[1]

local function fail(msg)
    term.setTextColor(colors.red)
    print("speaker: " .. msg)
    term.setTextColor(colors.white)
end

-- Pulls "-o name" / "-v number" out of the arg list, returns the rest.
local function parseFlags(list)
    local rest, opts = {}, {}
    local i = 1
    while i <= #list do
        local a = list[i]
        if a == "-o" and list[i + 1] then
            opts.output = list[i + 1]; i = i + 2
        elseif a == "-v" and list[i + 1] then
            opts.volume = tonumber(list[i + 1]); i = i + 2
        else
            rest[#rest + 1] = a; i = i + 1
        end
    end
    return rest, opts
end

local function usage()
    print("usage:")
    print("  speaker list")
    print("  speaker beep")
    print("  speaker chime                      play the startup chime")
    print("  speaker note <instrument> [pitch] [volume]")
    print("  speaker sound <sound id> [volume] [pitch]")
    print("  speaker play <file|url> [-v volume] [-o speaker]")
    print("  speaker stop")
    print("")
    print("Add '-o <name>' to any command to use one speaker instead of all.")
    print("Instruments: " .. table.concat(audio.INSTRUMENTS, ", "))
    print("play needs DFPWM audio (.dfpwm).")
end

if sub == "list" then
    local all = audio.speakers()
    if #all == 0 then print("No speakers attached.") return end
    term.setTextColor(colors.lightBlue)
    print("SPEAKERS")
    term.setTextColor(colors.white)
    for _, s in ipairs(all) do print("  " .. s.name) end

elseif sub == "beep" or sub == "chime" or sub == "note" or sub == "sound" or sub == "play" or sub == "stop" then
    local rest, opts = parseFlags({ table.unpack(args, 2) })
    local targets, err = audio.select(opts.output)
    if not targets then fail(err) return end

    if sub == "beep" then
        audio.note(targets, "pling", 12, 1)

    elseif sub == "chime" then
        audio.chime(targets)

    elseif sub == "note" then
        local instrument = rest[1]
        if not instrument then fail("usage: speaker note <instrument> [pitch] [volume]") return end
        local valid = false
        for _, i in ipairs(audio.INSTRUMENTS) do if i == instrument then valid = true end end
        if not valid then fail("unknown instrument '" .. instrument .. "'") return end
        audio.note(targets, instrument, tonumber(rest[2]), tonumber(rest[3]))

    elseif sub == "sound" then
        if not rest[1] then fail("usage: speaker sound <sound id> [volume] [pitch]") return end
        if not audio.sound(targets, rest[1], tonumber(rest[2]), tonumber(rest[3])) then
            fail("sound not played (bad id, or another sound is still playing)")
        end

    elseif sub == "play" then
        if not rest[1] then fail("usage: speaker play <file|url> [-v volume] [-o speaker]") return end
        print("Playing " .. rest[1] .. " (Ctrl+T to stop)")
        local ok, perr = audio.playDfpwm(targets, rest[1], opts.volume)
        if not ok and perr ~= "stopped" then fail(perr) end

    elseif sub == "stop" then
        audio.stop(targets)
    end

else
    usage()
end
