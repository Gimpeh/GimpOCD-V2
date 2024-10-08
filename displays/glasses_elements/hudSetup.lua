local widgetsAreUs = require("lib.widgetsAreUs")
local contextMenu = require("displays.glasses_elements.contextMenu")
local modules = require("modules.displays.modules.lua")

local hudSetup = {}

local hasLoadedFunction = false
hudSetup.remove = nil

local horizontalSteps = 4
local verticalSteps = 9

function hudSetup.init(player)
    local glasses_display = require("displays.glasses_display")
    component.glasses = glasses_display.getGlassesProxy(player)
    local xThresholds = {}
    local yThresholds = {}
    local res = glasses_display.getResolution(player)
    local grid = {}
    grid.elements = {}
    local div1 = res.x/2-91
    local div2 = res.x/2+91

    if players[player].hudSetup.elements then
        hudSetup.remove(player)
    end

    if not players[player] then
        players[player] = {}
    end
    if not players[player].hudSetup then
        players[player].hudSetup = {}
    end
    if not players[player].hudSetup.elements then
        players[player].hudSetup.elements = {}
    end
    players[player].hudSetup = {}

    local step = div1 / horizontalSteps
    for i = 1, horizontalSteps do
        local line = widgetsAreUs.createBox(step*i, 0, 1, res.y, {0.1333, 0.1333, 0.1333}, 0.4)
        table.insert(grid, line)
        table.insert(xThresholds, step*i)
    end
    for i = 0, horizontalSteps do
        local line = widgetsAreUs.createBox(div2+step*i, 0, 1, res.y, {0.1333, 0.1333, 0.1333}, 0.4)
        table.insert(grid, line)
        table.insert(xThresholds, div2+step*i)
    end
    step = res.y / verticalSteps
    for i = 1, verticalSteps do
        local line = widgetsAreUs.createBox(0, step*i, res.x, 1, {0.1333, 0.1333, 0.1333}, 0.4)
        table.insert(grid, line)
        table.insert(yThresholds, step*i)
    end

    grid.surface = widgetsAreUs.createBox(0, 0, res.x, res.y, {0, 0, 0}, 0)

    players[player].hudSetup.xThresholds = xThresholds
    players[player].hudSetup.yThresholds = yThresholds
    players[player].hudSetup.elements = grid
end

function hudSetup.onClick(eventName, address, player, x, y, button)
    if players[player].hudSetup.elements.window then
        players[player].hudSetup.elements.window.remove()
        players[player].hudSetup.elements.window = nil
    end
    if eventName == "hud_click" and button == 0 then
        if players[player].hudSetup.selectionWindow then
            players[player].hudSetup.selectionWindow.remove()
            players[player].hudSetup.selectionWindow = nil
            players[player].hudSetup.selection = nil
        end
        players[player].hudSetup.selectionStart = {x=x, y=y}
    end
    return true
end

function hudSetup.onClickRight()
    return false
end

function hudSetup.onDrag(eventName, address, player, x, y, button)
    if eventName == "hud_drag" then
        component.glasses = require("displays.glasses_display").getGlassesProxy(player)
        local selection --init in a usable context        
        --get the coordinates of the mouse during the drag
        if players[player].hudSetup.selection == nil then
            selection = {x=x, y=y}
        end
        --Init Grid Coordinates in a usable context
        local gridSelectionLeft = nil
        local gridSelectionRight = nil
        local gridSelectionTop = nil
        local gridSelectionBottom = nil
        --convert the x coordinates to grid coordinates
        for _, gridCoords in ipairs(players[player].hudSetup.xThresholds) do
            if gridCoords <= players[player].hudSetup.selectionStart.x then -- decide if grid line is on the left or right side of the selection
                gridSelectionLeft = gridCoords
            else
                break -- stop checking once we have our value
            end
        end
        for _, gridCoords in ipairs(players[player].hudSetup.xThresholds) do
            if gridCoords >= selection.x then
                gridSelectionRight = gridCoords
                break
            end
        end
        --convert the y coordinates to grid coordinates
        for _, gridCoords in ipairs(players[player].hudSetup.yThresholds) do
            if gridCoords <= players[player].hudSetup.selectionStart.y then -- decide if grid line is on the top or bottom side of the selection
                gridSelectionTop = gridCoords
            else
                break -- stop checking once we have our value
            end
        end
        for _, gridCoords in ipairs(players[player].hudSetup.yThresholds) do
            if gridCoords >= selection.y then
                gridSelectionBottom = gridCoords
                break
            end
        end
        -- Make or resize the selection window
        if not players[player].hudSetup.elements.window then
        players[player].hudSetup.elements.window = widgetsAreUs.createBox(gridSelectionLeft, gridSelectionTop, gridSelectionRight-gridSelectionLeft, 
                gridSelectionBottom-gridSelectionTop, {0.537, 0.812, 0.941}, 0.5)
        elseif players[player].hudSetup.elements.window.x + players[player].hudSetup.elements.window.width < gridSelectionRight or
        players[player].hudSetup.elements.window.y + players[player].hudSetup.elements.window.height < gridSelectionBottom then
            players[player].hudSetup.elements.window.setSize(gridSelectionRight-gridSelectionLeft, gridSelectionBottom-gridSelectionTop)
        end

        if hasLoadedFunction then
            return
        else
            hasLoadedFunction = true
            local function spawnArgTable(player)
                local args = {}
                local i = 1
                for k, v in pairs(players[player].availableModules) do
                    local tbl = {
                        text = k,
                        func = players[player].availableModules[k],
                        args = {player}
                    }
                    table.insert(args, tbl)
                end
                return args
            end

            hudSetup.onClickRight = function(eventName, address, player, x, y, button)
                component.glasses = require("displays.glasses_display").getGlassesProxy(player)
                if eventName == "hud_click" and button == 1 then
                    contextMenu.init(x, y, player, spawnArgTable(player))
                end
            end
        end
    end
end

function hudSetup.setVisible(visible, player)
    for index, element in pairs(players[player].hudSetup.elements) do
        element.setVisible(visible)
    end
end

function hudSetup.remove(player)
    for index, element in pairs(players[player].hudSetup.elements) do
        element.remove()
        players[player].hudSetup.elements[index] = nil
    end
    players[player].hudSetup.elements = nil
    players[player].hudSetup.onClickRight = function() return false end
end

return hudSetup