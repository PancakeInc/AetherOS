-- lib/desktop.lua
-- Copyright (c) 2026 Pancakse
-- SPDX-License-Identifier: BSD-3-Clause
-- The AetherOS desktop session: draws the wallpaper, desktop icons and
-- taskbar, and drives the window manager's event loop. This file is
-- dofile()'d once from boot/init.lua (or from `gui`) and only returns
-- when the user logs out / shuts down.

local wm = dofile("/lib/wm.lua")
local theme = dofile("/lib/theme.lua")
local ui = dofile("/lib/ui.lua")
local config = dofile("/lib/config.lua")

aether = aether or {}
aether.wm = wm

theme.refresh()
wm.topMargin = 1
wm.bottomMargin = 2

local screenW, screenH = term.getSize()
local menuBarY = 1
local dockY = screenH

local icons = {
    { label = "Terminal", program = "/bin/shell.lua", glyph = ">_", w = 42, h = 16 },
    { label = "Files", program = "/apps/files.lua", glyph = "[]", w = 40, h = 16 },
    { label = "Docs", program = "/apps/docs.lua", glyph = "D", w = 44, h = 16 },
    { label = "Sheets", program = "/apps/sheets.lua", glyph = "S", w = 48, h = 17 },
    { label = "Settings", program = "/apps/settings.lua", glyph = "*", w = 36, h = 14 },
    { label = "TaskMgr", program = "/apps/taskmgr.lua", glyph = "#", w = 40, h = 14 },
    { label = "Edit", program = "/bin/edit.lua", glyph = "Ab", w = 40, h = 16 },
}

local appleMenuOpen = false
local appleMenuBoxes = {}
local dockBoxes = {}

local function drawWallpaper()
    term.setBackgroundColor(theme.desktopBg)
    term.clear()
    -- subtle striped field to mimic a polished desktop texture
    for y = 2, screenH - 2 do
        local rowBg = (y % 2 == 0) and theme.desktopBg or theme.desktopBg2
        term.setBackgroundColor(rowBg)
        term.setCursorPos(1, y)
        term.clearLine()
    end

    term.setTextColor(theme.textDim)
    for y = 3, screenH - 3, 2 do
        for x = 1, screenW do
            if (x + y) % 12 == 0 then
                term.setCursorPos(x, y)
                term.write("*")
            end
        end
    end
end

local function drawMenuBar()
    term.setCursorPos(1, menuBarY)
    term.setBackgroundColor(theme.menubarBg)
    term.setTextColor(theme.menubarText)
    term.clearLine()

    term.setCursorPos(1, menuBarY)
    term.setBackgroundColor(appleMenuOpen and theme.accent or theme.menubarBg)
    term.setTextColor(appleMenuOpen and colors.black or theme.menubarText)
    term.write(" Aether ")

    local focused = wm.focused()
    local appLabel = focused and focused.title or "Desktop"
    term.setCursorPos(10, menuBarY)
    term.setBackgroundColor(theme.menubarBg)
    term.setTextColor(theme.textDim)
    term.write(appLabel:sub(1, math.max(0, screenW - 24)))

    local clock = textutils.formatTime(os.time(), true)
    term.setCursorPos(screenW - #clock + 1, menuBarY)
    term.setTextColor(theme.menubarText)
    term.write(clock)
end

local function drawDock()
    local dockBg = theme.dockBg

    term.setCursorPos(1, dockY - 1)
    term.setBackgroundColor(theme.desktopBg2)
    term.clearLine()

    term.setCursorPos(1, dockY)
    term.setBackgroundColor(dockBg)
    term.clearLine()

    local totalW = 0
    for _, icon in ipairs(icons) do
        totalW = totalW + math.max(6, #icon.label + 2) + 1
    end

    local x = math.max(2, math.floor((screenW - totalW) / 2))
    dockBoxes = {}

    for _, icon in ipairs(icons) do
        local buttonW = math.max(6, #icon.label + 2)
        local running = false
        local focused = false
        for _, win in ipairs(wm.windows) do
            if win.program == icon.program then
                running = true
                if win.id == wm.focusedId then focused = true end
            end
        end

        term.setCursorPos(x, dockY)
        term.setBackgroundColor(focused and theme.accent or dockBg)
        term.setTextColor(focused and colors.black or theme.text)
        term.write(" " .. icon.label:sub(1, buttonW - 2):gsub("%s+$", "") .. string.rep(" ", math.max(0, buttonW - #icon.label - 1)))

        if running then
            term.setCursorPos(x + math.floor(buttonW / 2), dockY - 1)
            term.setBackgroundColor(theme.desktopBg2)
            term.setTextColor(theme.ok)
            term.write(".")
        end

        table.insert(dockBoxes, { x1 = x, y1 = dockY, x2 = x + buttonW - 1, y2 = dockY, icon = icon })
        x = x + buttonW + 1
    end
end

local function drawAppleMenu()
    if not appleMenuOpen then return end

    local items = {
        { label = "About AetherOS", action = "about" },
        { sep = true },
        { label = "Files", icon = icons[2] },
        { label = "Settings", icon = icons[5] },
        { label = "Task Manager", icon = icons[6] },
        { sep = true },
        { label = "Reboot", action = "reboot" },
        { label = "Shutdown", action = "shutdown" },
    }

    local x, y, w = 1, 2, 22
    local h = #items + 2
    ui.panel(x, y, w, h, nil, { bg = theme.panelBg, fg = theme.text })

    appleMenuBoxes = {}
    for i, item in ipairs(items) do
        local row = y + i
        term.setCursorPos(x + 1, row)
        term.setBackgroundColor(theme.panelBg)
        if item.sep then
            term.setTextColor(theme.textDim)
            term.write(string.rep("-", w - 2))
        else
            term.setTextColor(theme.text)
            term.write(" " .. item.label .. string.rep(" ", math.max(0, w - 3 - #item.label)))
            table.insert(appleMenuBoxes, { x1 = x + 1, y1 = row, x2 = x + w - 2, y2 = row, icon = item.icon, action = item.action })
        end
    end
end

local function launch(icon)
    wm.spawnWindow(icon.program, {}, { title = icon.label, w = icon.w, h = icon.h })
end

local function redrawAll()
    drawWallpaper()
    wm.compositeAll()
    drawMenuBar()
    drawDock()
    drawAppleMenu()
end

redrawAll()

local kernel = aether.kernel

local function onEvent(event)
    local kind = event[1]
    local changed = false

    if kind == "mouse_click" then
        local mx, my = event[3], event[4]

        if appleMenuOpen then
            local hit = ui.hitAny(appleMenuBoxes, mx, my)
            appleMenuOpen = false
            if hit then
                if hit.icon then
                    launch(hit.icon)
                elseif hit.action == "shutdown" then
                    os.shutdown()
                elseif hit.action == "reboot" then
                    os.reboot()
                elseif hit.action == "about" then
                    wm.spawnWindow("/bin/neofetch.lua", {}, { title = "About AetherOS", w = 42, h = 16 })
                end
            end
            changed = true
        elseif my == menuBarY then
            if mx <= 8 then
                appleMenuOpen = true
                changed = true
            end
        elseif my == dockY then
            local hit = ui.hitAny(dockBoxes, mx, my)
            if hit then
                local focusedExisting = nil
                for _, win in ipairs(wm.windows) do
                    if win.program == hit.icon.program then
                        focusedExisting = win
                    end
                end
                if focusedExisting then
                    wm.focus(focusedExisting.id)
                else
                    launch(hit.icon)
                end
                changed = true
            end
        else
            local windowHandled = wm.handleEvent(event)
            changed = windowHandled or changed
        end
    elseif kind == "term_resize" then
        screenW, screenH = term.getSize()
        dockY = screenH
        wm.screenW, wm.screenH = screenW, screenH
        wm.reflow()
        changed = true
    else
        changed = wm.handleEvent(event) or changed
    end

    if wm.reapDead() then changed = true end
    if changed then redrawAll() end
end

kernel:run(onEvent)
