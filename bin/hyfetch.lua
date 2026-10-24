-- hyfetch.lua
-- Copyright (c) 2026 Pancakse
-- SPDX-License-Identifier: BSD-3-Clause
-- colorful system summary inspired by hyfetch

local args = { ... }
local version = (aether and aether.version) or "unknown"

local config = (aether and aether.config) or dofile("/lib/config.lua")
local util = dofile("/lib/util.lua")

local palettes = {
    rainbow = { colors.red, colors.orange, colors.yellow, colors.lime, colors.cyan, colors.blue, colors.purple },
    trans = { colors.lightBlue, colors.pink, colors.white, colors.pink, colors.lightBlue },
    bi = { colors.pink, colors.purple, colors.blue },
    lesbian = { colors.red, colors.orange, colors.white, colors.pink, colors.purple },
    pan = { colors.pink, colors.yellow, colors.cyan },
    ace = { colors.gray, colors.lightGray, colors.white, colors.purple },
    nonbinary = { colors.yellow, colors.white, colors.purple, colors.gray },
    agender = { colors.black, colors.lightGray, colors.white, colors.lime, colors.white, colors.lightGray, colors.black },
    aro = { colors.green, colors.lime, colors.white, colors.gray, colors.black },
    aroace = { colors.orange, colors.yellow, colors.white, colors.lightBlue, colors.blue },
    demisexual = { colors.black, colors.white, colors.purple, colors.lightGray },
    demiromantic = { colors.black, colors.white, colors.lime, colors.lightGray },
    genderfluid = { colors.pink, colors.white, colors.purple, colors.black, colors.blue },
    genderqueer = { colors.purple, colors.white, colors.lime },
    intersex = { colors.yellow, colors.purple, colors.yellow },
    progress = { colors.white, colors.pink, colors.lightBlue, colors.brown, colors.black, colors.red, colors.orange, colors.yellow, colors.lime, colors.cyan, colors.blue, colors.purple },
    mlm = { colors.blue, colors.cyan, colors.white, colors.cyan, colors.blue },
    demiboy = { colors.lightGray, colors.gray, colors.lightBlue, colors.white, colors.lightBlue, colors.gray, colors.lightGray },
    demigirl = { colors.lightGray, colors.gray, colors.pink, colors.white, colors.pink, colors.gray, colors.lightGray },
    bigender = { colors.pink, colors.purple, colors.white, colors.purple, colors.blue },
    omnisexual = { colors.pink, colors.pink, colors.purple, colors.blue, colors.blue },
    polysexual = { colors.pink, colors.lime, colors.blue },
    abrosexual = { colors.green, colors.lime, colors.white, colors.pink, colors.magenta },
    polyamory = { colors.blue, colors.red, colors.black, colors.yellow },
}

local paletteLabels = {
    rainbow = "Rainbow",
    trans = "Trans",
    bi = "Bi",
    lesbian = "Lesbian",
    pan = "Pan",
    ace = "Ace",
    nonbinary = "Nonbinary",
    agender = "Agender",
    aro = "Aromantic",
    aroace = "AroAce",
    demisexual = "Demisexual",
    demiromantic = "Demiromantic",
    genderfluid = "Genderfluid",
    genderqueer = "Genderqueer",
    intersex = "Intersex",
    progress = "Progress Pride",
    mlm = "MLM",
    demiboy = "Demiboy",
    demigirl = "Demigirl",
    bigender = "Bigender",
    omnisexual = "Omnisexual",
    polysexual = "Polysexual",
    abrosexual = "Abrosexual",
    polyamory = "Polyamory",
}

local paletteOrder = {
    "rainbow", "progress", "trans", "bi", "lesbian", "mlm", "pan", "ace", "aro", "aroace",
    "nonbinary", "agender", "genderfluid", "genderqueer", "intersex", "demisexual", "demiromantic",
    "demiboy", "demigirl", "bigender", "omnisexual", "polysexual", "abrosexual", "polyamory",
}

local paletteAliases = {
    pride = "rainbow",
    lgbt = "rainbow",
    lgbtq = "rainbow",
    lgbtqia = "rainbow",
    transsexual = "trans",
    bisexual = "bi",
    pansexual = "pan",
    asexual = "ace",
    nb = "nonbinary",
    nonbinary = "nonbinary",
    nonbinaryflag = "nonbinary",
    aromantic = "aro",
    aroace = "aroace",
    arospec = "aro",
    acespec = "ace",
    demi = "demisexual",
    demisexual = "demisexual",
    demiromantic = "demiromantic",
    genderfluid = "genderfluid",
    gfluid = "genderfluid",
    genderqueer = "genderqueer",
    gq = "genderqueer",
    intersex = "intersex",
    progress = "progress",
    progresspride = "progress",
    mlm = "mlm",
    vincian = "mlm",
    gaymen = "mlm",
    demiboy = "demiboy",
    demigirl = "demigirl",
    bigender = "bigender",
    omni = "omnisexual",
    omnisexual = "omnisexual",
    polysexual = "polysexual",
    poly = "polysexual",
    abro = "abrosexual",
    abrosexual = "abrosexual",
    polyamory = "polyamory",
    polyam = "polyamory",
}

local function normalizeName(input)
    return (input or ""):lower():gsub("[^%w]", "")
end

local function pickPalette()
    print("First-time hyfetch setup")
    print("Pick the palette you want to use:")

    for i, name in ipairs(paletteOrder) do
        print(("  %d) %s"):format(i, paletteLabels[name]))
    end

    term.write("Choose [1-" .. #paletteOrder .. "] or name (default rainbow): ")
    local raw = read() or ""
    local input = raw:lower():gsub("^%s+", ""):gsub("%s+$", "")

    if input == "" then
        return "rainbow"
    end

    local asNum = tonumber(input)
    if asNum and paletteOrder[asNum] then
        return paletteOrder[asNum]
    end

    local normalized = normalizeName(input)
    if palettes[normalized] then
        return normalized
    end

    if paletteAliases[normalized] and palettes[paletteAliases[normalized]] then
        return paletteAliases[normalized]
    end

    term.setTextColor(colors.yellow)
    print("Unknown choice, using Rainbow.")
    term.setTextColor(colors.white)
    return "rainbow"
end

if not term.isColor() then
    shell.run("/bin/neofetch.lua")
    return
end

local paletteName = config.get("hyfetchPalette")
local wantsSetup = args[1] == "--setup" or args[1] == "setup"

if wantsSetup or not palettes[paletteName] then
    paletteName = pickPalette()
    config.set("hyfetchPalette", paletteName)
    print("Saved palette: " .. paletteLabels[paletteName])
    print("")
end

local uptimeSeconds = (aether and aether.kernel) and (os.clock() - aether.kernel.bootTime) or os.clock()
local palette = palettes[paletteName]

local lines = {
    { "OS", "AetherOS " .. version },
    { "Host", config.get("hostname") or "aether" },
    { "Runtime", _HOST or "CC:Tweaked" },
    { "Uptime", util.formatUptime(uptimeSeconds) },
    { "Palette", paletteLabels[paletteName] },
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

for i, row in ipairs(art) do
    term.setTextColor(palette[((i - 1) % #palette) + 1])
    print(row)
end
term.setTextColor(colors.white)

print("")
for i, entry in ipairs(lines) do
    term.setTextColor(palette[((i - 1) % #palette) + 1])
    term.write(("%-12s"):format(entry[1]))
    term.setTextColor(colors.white)
    print(entry[2])
end

print("")
term.setTextColor(colors.lightGray)
for i = 1, #palette do
    term.setBackgroundColor(palette[i])
    term.write("  ")
end
term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
print("")