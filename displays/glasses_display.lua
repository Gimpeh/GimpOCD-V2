local event = require("event")
local modules = require("displays.modules.modules")
local hudSetup = require("displays.glasses_elements.hudSetup")
local widgetsAreUs = require("lib.widgetsAreUs")
local c = require("lib.gimp_colors")
local contextMenu = require("displays.glasses_elements.contextMenu")

-------------------------------------------------------
--- Module Context Vars & Functions + Forward Decs

local glasses_display = {}
glasses_display.hudPages = {}

local onClick
local init_phase2

-------------------------------------------------------
--- Getters/Setters

---@param eventName string
---@param address string
---@param player string
---@param max_x number
---@param max_y number
local function registerUsers(eventName, address, player, max_x, max_y)
    print("glasses_display - Line 27: registerUsers called for player: " .. player)
    local suc, err = pcall(function()
        if not players[player] then
            players[player]={}
        end
        if not players[player].modules then
            players[player].modules = {}
        end
        if not players[player].modules[1] then
            players[player].modules[1] = {}
        end
        if not players[player].modules[2] then
            players[player].modules[2] = {}
        end
        if not players[player].modules[3] then
            players[player].modules[3] = {}
        end
        modules.init(player)
        if not players[player].glasses_display then
            players[player].glasses_display = {}
        end
        if not players[player].hudSetup then
            players[player].hudSetup = {}
        end
        if not players[player].contextMenu then
            players[player].contextMenu = {}
        end
        if not players[player].glasses_display.elements then
            players[player].glasses_display.elements = {}
        end
        players[player].resolution = {x=max_x, y=max_y}
        print("glasses_display - Line 55: Setting current HUD page to 1 for player: " .. player)
        players[player].current_hudPage = 1
        if not players[player].glasses_display.elements then
            players[player].glasses_display.elements = {}
        end
        if not players[player].glasses_display.elements.detached then
            players[player].glasses_display.elements.detached = {}
        end
        print("glasses_display - Line 64: Initializing HUD setup for player: " .. player)
        hudSetup.init(player)
        print("glasses_display - Line 66: Calling init_phase2 for player: " .. player)
        init_phase2(player)
    end)
    if not suc then print(err) end
end

function glasses_display.getGlassesProxy(player)
    print("glasses_display - Line 72: getGlassProxy called for player: " .. player)
    local suc, result = pcall(function()
        print("glasses_display - Line 74: Searching for glasses components")
        for address, _ in pairs(component.list("glasses")) do
            local glasses = component.proxy(address)
            if glasses then
                print("glasses_display - Line 77: Glasses component found at address: " .. address)
                local owner = glasses.getBindPlayers()
                if owner == player then
                    print("glasses_display - Line 79: Glasses bound to player: " .. player)
                    return glasses
                end
            end
        end
        return nil
    end)
    if not suc then print(result) end
    return result
end

---@param player player_name
function glasses_display.getResolution(player)
    print("glasses_display - Line 88: getResolution called for player: " .. player)
    local suc, result = pcall(function()
        return players[player].resolution
    end)
    if not suc then print(result) end
    return result
end

-------------------------------------------------------
--- Initialization & Saving/Loading

-- init -> registerUsers (getters/setters) -> init_phase2
function glasses_display.init()
    print("glasses_display - Line 98: Initializing glasses_display")
    local suc, err = pcall(function()
        print("glasses_display - Line 100: Listening for glasses_on event")
        event.listen("glasses_on", registerUsers)
    end)
    if not suc then print(err) end
end

init_phase2 = function(player)
    print("glasses_display - Line 107: init_phase2 called for player: " .. player)
    local suc, err = pcall(function()
        --**To-DO** Remove All displayed elements and reload state from save file (probably should save the relevant states first)

        print("glasses_display - Line 111: Getting GlassProxy for player: " .. player)
        component.glasses = glasses_display.getGlassesProxy(player)
        local mid = players[player].resolution.x/2

        -- Create the buttons for controlling the hud page
        players[player].glasses_display.elements[1] = widgetsAreUs.symbolBox(mid-21, 5, "1", c.pagesButton_active, function() 
            local suc, err = pcall(function()
                players[player].current_hudPage = 1
                for index, page in ipairs(players[player].modules) do
                    if index == players[player].current_hudPage then
                        players[player].glasses_display.elements[1].box.setColor(table.unpack(c.pagesButton_active))
                        for moduleName, module in pairs(players[player].modules[index]) do
                            print("glasses_display - Line 121: Setting module visible for player: " .. player)
                            module.setVisible(true, player)
                        end
                    elseif index ~= players[player].current_hudPage then
                        players[player].glasses_display.elements[index].box.setColor(table.unpack(c.pagesButton_inactive))
                        for moduleName, module in pairs(players[player].modules[index]) do
                            print("glasses_display - Line 126: Setting module invisible for player: " .. player)
                            module.setVisible(false, player)
                        end
                    end
                end
            end)
            if not suc then print(err) end
        end, player)
        players[player].glasses_display.elements[2] = widgetsAreUs.symbolBox(mid+21, 5, "2", c.pagesButton_inactive, function() 
            local suc, err = pcall(function()
                players[player].current_hudPage = 2
                for index, page in ipairs(players[player].modules) do
                    if index == players[player].current_hudPage then
                        players[player].glasses_display.elements[2].box.setColor(table.unpack(c.pagesButton_active))
                        for moduleName, module in pairs(players[player].modules[index]) do
                            print("glasses_display - Line 138: Setting module visible for player: " .. player)
                            module.setVisible(true, player)
                        end
                    elseif index ~= players[player].current_hudPage then
                        players[player].glasses_display.elements[index].box.setColor(table.unpack(c.pagesButton_inactive))
                        for moduleName, module in pairs(players[player].modules[index]) do
                            print("glasses_display - Line 143: Setting module invisible for player: " .. player)
                            module.setVisible(false, player)
                        end
                    end
                end
            end)
            if not suc then print(err) end
        end, player)
        players[player].glasses_display.elements[3] = widgetsAreUs.symbolBox(mid+43, 5, "3", c.pagesButton_inactive, function() 
            local suc, err = pcall(function()
                players[player].current_hudPage = 3
                for index, page in ipairs(players[player].modules) do
                    if index == players[player].current_hudPage then
                        players[player].glasses_display.elements[3].box.setColor(table.unpack(c.pagesButton_active))
                        for moduleName, module in pairs(players[player].modules[index]) do
                            print("glasses_display - Line 155: Setting module visible for player: " .. player)
                            module.setVisible(true, player)
                        end
                    elseif index ~= players[player].current_hudPage then
                        players[player].glasses_display.elements[index].box.setColor(table.unpack(c.pagesButton_inactive))
                        for moduleName, module in pairs(players[player].modules[index]) do
                            print("glasses_display - Line 160: Setting module invisible for player: " .. player)
                            module.setVisible(false, player)
                        end
                    end
                end
            end)
            if not suc then print(err) end
        end, player)

        -- Create the button for toggling the grid
        players[player].glasses_display.elements.grid_button = widgetsAreUs.symbolBox(mid-43, 5, "G", c.pagesButton_active, function()
            local suc, err = pcall(function()
                if players[player].hudSetup.elements then
                    hudSetup.remove(player)
                else
                    print("glasses_display - Line 176: Initializing HUD setup for player: " .. player)
                    hudSetup.init(player)
                end
            end)
            if not suc then print(err) end
        end, player)
    end)
    if not suc then print(err) end
end

-------------------------------------------------------
--- Command & Control 

glasses_display.onClick = function(eventName, address, player, x, y, button)
    print("glasses_display - Line 190: onClick called for player: " .. player)
    --local suc, err = pcall(function()
        local short = players[player].glasses_display.elements

        if eventName == "hud_click" and button == 0 then
            if players[player].contextMenu and players[player].contextMenu.elements then
                if players[player].contextMenu.elements.backgroundBox.contains(x, y) then
                    contextMenu.onClick(eventName, address, player, x, y, button)
                else
                    contextMenu.remove(player)
                end
            elseif short[1].box.contains(x, y) then
                short[1].onClick()
            elseif short[2].box.contains(x, y) then
                short[2].onClick()
            elseif short[3].box.contains(x, y) then
                short[3].onClick()
            elseif short.grid_button.box.contains(x, y) then
                short.grid_button.onClick()
            elseif players[player].popUp and players[player].popUp.contains(x, y) then
                players[player].popUp.onClick(eventName, address, player, x, y, button)
            elseif players[player].hudSetup.elements then
                print("glasses_display - Line 207: HUD setup onClick triggered for player: " .. player)
                hudSetup.onClick(eventName, address, player, x, y, button)
            elseif players[player].glasses_display.elements.detached and players[player].glasses_display.elements.detached[players[player].current_hudPage] then
                for _, widget in ipairs(players[player].glasses_display.elements.detached[players[player].current_hudPage]) do
                    if widget.box.contains(x, y) then
                        widget.onClick(eventName, address, player, x, y, button)
                    end
                end
            else
                for moduleName, module in pairs(players[player].modules[players[player].current_hudPage]) do
                    if module and module.backgroundBox and module.backgroundBox.contains(x, y) then
                        module.onClick(eventName, address, player, x, y, button)
                    end
                end
            end
        end
    --end)
    --if not suc then print(err) end
end

glasses_display.onClickRight = function(eventName, address, player, x, y, button)
    print("glasses_display - Line 220: onClickRight called for player: " .. player)
    --local suc, err = pcall(function()
        if eventName == "hud_click" and button == 1 then
            if players[player].contextMenu and players[player].contextMenu.elements and players[player].contextMenu.elements.backgroundBox.contains(x, y) then
                contextMenu.onClickRight(eventName, address, player, x, y, button)
            elseif players[player].hudSetup.elements then
                print("glasses_display - Line 225: HUD setup onClickRight triggered for player: " .. player)
                hudSetup.onClickRight(eventName, address, player, x, y, button)
            elseif players[player].glasses_display.elements.detached and players[player].glasses_display.elements.detached[players[player].current_hudPage] then
                for _, widget in ipairs(players[player].glasses_display.elements.detached[players[player].current_hudPage]) do
                    if widget.box.contains(x, y) then
                        widget.onClickRight(eventName, address, player, x, y, button)
                    end
                end
            else
                for moduleName, module in pairs(players[player].modules[players[player].current_hudPage]) do
                    if module and module.backgroundBox and module.backgroundBox.contains(x, y) then
                        module.onClickRight(eventName, address, player, x, y, button)
                    end
                end
            end
        end
    --end)
    --if not suc then print(err) end
end

glasses_display.onDrag = function(eventName, address, player, x, y, button)
    print("glasses_display - Line 237: onDrag called for player: " .. player)
    local suc, err = pcall(function()
        if eventName == "hud_drag" then
            if players[player].hudSetup.elements then 
                if players[player].contextMenu and players[player].contextMenu.elements then
                    print("glasses_display - Line 242: Context Menu Exists")
                    return false
                else
                    print("glasses_display - Line 243: HUD setup onDrag triggered for player: " .. player)
                    hudSetup.onDrag(eventName, address, player, x, y, button)
                end
            elseif players[player].glasses_display.selectedForDrag and players[player].glasses_display.selectedForDrag.func then
                players[player].glasses_display.selectedForDrag.func(x, y)
            end
        end
    end)
    if not suc then print(err) end
end

glasses_display.update = function()
    print("glasses_display - Line 252: update called for player: " .. tostring(player))
    local suc, err = pcall(function()
        for playerName, playerTable in ipairs(players) do
            for moduleName, module in pairs(players[playerName].modules[players[playerName].current_hudPage]) do
                if module and module.update then
                    print("glasses_display - Line 256: Updating module: " .. tostring(module) .. " for player: " .. tostring(player))
                    module.update()
                end
            end
        end
    end)
    if not suc then print(err) end
end

-------------------------------------------------------
--- Events

local function detach(widgetFunc, args, player)
    component.glasses = require("displays.glasses_display").getGlassesProxy(player)

    if not players[player].glasses_display.elements.detached then
        players[player].glasses_display.elements.detached = {}
    end
    if not players[player].glasses_display.elements.detached[players[player].current_hudPage] then
        players[player].glasses_display.elements.detached[players[player].current_hudPage] = {}
    end

    local widget = widgetFunc(table.unpack(args), #players[player].glasses_display.elements.detached[players[player].current_hudPage]+1)

    widget.onClick = function(eventName, address, player, x, y, button)
        print("glasses_display - Line 272: onClick called for detached widget")
        local suc, err = pcall(function()
            if eventName == "hud_click" and button == 0 then
                players[player].glasses_display.selectedForDrag.func = widget.move

                local startX, startY = widget.getPosition()
                players[player].glasses_display.selectedForDrag.offset = {x = x-startX, y = y-startY}
            end
        end)
    end

    widget.onDrag = function(eventName, address, player, x, y, button)
        widget.move(x+players[player].glasses_display.selectedForDrag.offset.x, y+players[player].glasses_display.selectedForDrag.offset.Y)
    end
    
    table.insert(players[player].glasses_display.elements.detached[players[player].current_hudPage], widget)
end

local updateTimer = event.timer(timing.ten, glasses_display.update, math.huge)
event.listen("detach_element", detach)

return glasses_display