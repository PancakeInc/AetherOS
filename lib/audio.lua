-- lib/audio.lua
-- Copyright (c) 2026 Pancakse
-- SPDX-License-Identifier: BSD-3-Clause
-- Speaker support for AetherOS: finds CC:Tweaked speakers, plays notes,
-- Minecraft sounds, and streams DFPWM audio from a file or URL.
-- Used by /bin/speaker.lua; apps and packages can dofile it too:
--   local audio = dofile("/lib/audio.lua")
--   audio.note(audio.speakers(), "harp", 12)

local audio = {}

audio.INSTRUMENTS = {
    "harp", "basedrum", "snare", "hat", "bass", "flute", "bell", "guitar",
    "chime", "xylophone", "iron_xylophone", "cow_bell", "didgeridoo",
    "bit", "banjo", "pling",
}

local CHUNK_BYTES = 16 * 1024 -- DFPWM bytes per playAudio() buffer

local function isSpeaker(name)
    if peripheral.hasType then return peripheral.hasType(name, "speaker") end
    return peripheral.getType(name) == "speaker"
end

-- Returns { {name=, p=}, ... } for every attached speaker, sorted by name.
function audio.speakers()
    local out = {}
    for _, name in ipairs(peripheral.getNames()) do
        if isSpeaker(name) then
            out[#out + 1] = { name = name, p = peripheral.wrap(name) }
        end
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end

-- With a name: just that speaker. Without: all of them.
-- Returns list, err
function audio.select(name)
    local all = audio.speakers()
    if #all == 0 then return nil, "no speakers attached" end
    if not name then return all end
    for _, s in ipairs(all) do
        if s.name == name then return { s } end
    end
    return nil, "no speaker named '" .. name .. "'"
end

function audio.stop(targets)
    for _, s in ipairs(targets) do s.p.stop() end
end

-- instrument: see audio.INSTRUMENTS. volume 0-3, pitch 0-24 (12 = middle).
function audio.note(targets, instrument, pitch, volume)
    local ok = true
    for _, s in ipairs(targets) do
        ok = s.p.playNote(instrument or "harp", volume or 1, pitch or 12) and ok
    end
    return ok
end

-- Any Minecraft sound id, e.g. "minecraft:entity.experience_orb.pickup".
function audio.sound(targets, name, volume, pitch)
    local ok = true
    for _, s in ipairs(targets) do
        ok = s.p.playSound(name, volume or 1, pitch or 1) and ok
    end
    return ok
end

-- Short rising "boot" arpeggio. Blocks for about half a second.
function audio.chime(targets)
    local pitches = { 6, 10, 13, 18 }
    for i, pitch in ipairs(pitches) do
        audio.note(targets, "pling", pitch, 1.5)
        if i < #pitches then sleep(0.12) end
    end
end

-- Opens a local file or http(s) URL for binary reading.
-- Returns a reader function (returns the next chunk or nil) + a close
-- function, or nil, err.
function audio.open(source)
    if source:match("^https?://") then
        if not http then return nil, "HTTP API is disabled on this computer" end
        local res, err = http.get({ url = source, binary = true })
        if not res then return nil, "couldn't fetch " .. source .. (err and (": " .. err) or "") end
        return function() return res.read(CHUNK_BYTES) end, function() res.close() end
    end
    local path = shell and shell.resolve(source) or source
    if not fs.exists(path) or fs.isDir(path) then return nil, "no such file: " .. source end
    local f = fs.open(path, "rb")
    if not f then return nil, "couldn't open " .. source end
    return function() return f.read(CHUNK_BYTES) end, function() f.close() end
end

-- Streams DFPWM audio to every speaker in `targets`.
-- source: file path or URL. volume: 0.0-3.0 (default 1.0).
-- Blocks until done; Ctrl+T stops it cleanly. Returns ok, err.
function audio.playDfpwm(targets, source, volume)
    local read, closeOrErr = audio.open(source)
    if not read then return false, closeOrErr end

    local dfpwm = require("cc.audio.dfpwm")
    local decoder = dfpwm.make_decoder()
    volume = volume or 1.0

    local ok, err = pcall(function()
        while true do
            local chunk = read()
            if not chunk or #chunk == 0 then break end
            local buffer = decoder(chunk)
            for _, s in ipairs(targets) do
                while not s.p.playAudio(buffer, volume) do
                    os.pullEvent("speaker_audio_empty")
                end
            end
        end
    end)

    closeOrErr()
    if not ok then
        audio.stop(targets)
        if tostring(err):find("Terminated") then return false, "stopped" end
        return false, tostring(err)
    end
    return true
end

return audio
