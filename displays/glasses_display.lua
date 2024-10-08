local event = require("event")
local modules = require("modules.module_loader")
local hudSetup = require("displays.glasses_elements.hudSetup")
local widgetsAreUs = require("lib.widgetsAreUs")
local c = require("lib.gimp_colors")

-------------------------------------------------------
--- Module Context Vars & Functions + Forward Decs

local glasses_display = {}
glasses_display.hudPages = {}

local onClick
local init_phase2



-------------------------------------------------------
--- Getters/Setters

---@param eventName event
---@param address address
---@param player player_name
---@param max_x screen_width
---@param max_y screen_height
local function registerUsers(eventName, address, player, max_x, max_y)
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
    players[player].current_hudPage = 1
    if not players[player].currentModules then
        players[player].currentModules = {}
    end
    if not players[player].availableModules then
        players[player].availableModules = loadfile("displays.modules.modules")()
    end
    if not players[player].glasses_display.elements then
        players[player].glasses_display.elements = {}
    end
    hudSetup.init(player)
    init_phase2(player)
end

function glasses_display.getGlassProxy(player)
    for address, _ in pairs(component.list("glasses")) do
        local glasses = component.proxy(address)
        if glasses then
            local owner = glasses.getBindPlayers()
            if owner == player then return glasses end
        end
    end
    return nil
end

---@param player player_name
function glasses_display.getResolution(player)
    return players[player].resolution
end

-------------------------------------------------------
--- Initialization & Saving/Loading

-- init -> registerUsers (getters/setters) -> init_phase2
function glasses_display.init()
    event.listen("glasses_on", registerUsers)
end

init_phase2 = function(player)
    --**To-DO** Remove All displayed elements and reload state from save file (probably should save the relevant states first)


    component.glasses = glasses_display.getGlassProxy(player)
    local mid = players[player].resolution.x/2

    -- Create the buttons for controlling the hud page
    players[player].glasses_display.elements[1] = widgetsAreUs.symbolBox(mid-21, 5, "1", c.pagesButton_active, function() 
        players[player].current_hudPage = 1
        for index, page in ipairs(players[player].modules) do
            if index == players[player].current_hudPage then
                players[player].glasses_display.elements[1].box.setColor(table.unpack(c.pagesButton_active))
                for moduleName, module in pairs(players[player].modules[index]) do
                    module.setVisible(true)
                end
            elseif index ~= players[player].current_hudPage then
                players[player].glasses_display.elements[index].box.setColor(table.unpack(c.pagesButton_inactive))
                for moduleName, module in pairs(players[player].modules[index]) do
                    module.setVisible(false)
                end
            end
        end
    end)
    players[player].glasses_display.elements[2] = widgetsAreUs.symbolBox(mid+21, 5, "2", c.pagesButton_inactive, function() 
        players[player].current_hudPage = 2
        for index, page in ipairs(players[player].modules) do
            if index == players[player].current_hudPage then
                players[player].glasses_display.elements[2].box.setColor(table.unpack(c.pagesButton_active))
                for moduleName, module in pairs(players[player].modules[index]) do
                    module.setVisible(true)
                end
            elseif index ~= players[player].current_hudPage then
                players[player].glasses_display.elements[index].box.setColor(table.unpack(c.pagesButton_inactive))
                for moduleName, module in pairs(players[player].modules[index]) do
                    module.setVisible(false)
                end
            end
        end
    end)
    players[player].glasses_display.elements[3] = widgetsAreUs.symbolBox(mid+43, 5, "3", c.pagesButton_inactive, function() 
        players[player].current_hudPage = 3
        for index, page in ipairs(players[player].modules) do
            if index == players[player].current_hudPage then
                players[player].glasses_display.elements[3].box.setColor(table.unpack(c.pagesButton_active))
                for moduleName, module in pairs(players[player].modules[index]) do
                    module.setVisible(true)
                end
            elseif index ~= players[player].current_hudPage then
                players[player].glasses_display.elements[index].box.setColor(table.unpack(c.pagesButton_inactive))
                for moduleName, module in pairs(players[player].modules[index]) do
                    module.setVisible(false)
                end
            end
        end
    end)

    -- Create the button for toggling the grid
    players[player].glasses_display.elements.grid_button = widgetsAreUs.symbolBox(mid-43, 5, "G", c.pagesButton_active, function()
        if players[player].hudSetup.elements then
            for key, element in pairs(players[player].hudSetup.elements) do
                element.remove()
                players[player].hudSetup.elements[key] = nil
            end
            players[player].hudSetup.elements = nil
            players[player].hudSetup.xThresholds = {}
            players[player].hudSetup.yThresholds = {}
        else
            hudSetup.init(player)
        end
    end)
end

-------------------------------------------------------
--- Command & Control 

glasses_display.onClick = function(eventName, address, player, x, y, button)
    local short = players[player].glasses_display.elements

    if eventName == "hud_click" and button == 0 then
        if players[player].contextMenu and players[player].contextMenu.elements and players[player].contextMenu.elements.backgroundBox.contains(x, y) then
            players[player].contextMenu.onClick(eventName, address, player, x, y, button)
        elseif short[1].box.contains(x, y) then
            short[1].onClick()
        elseif short[2].box.contains(x, y) then
            short[2].onClick()
        elseif short[3].box.contains(x, y) then
            short[3].onClick()
        elseif short.grid_button.box.contains(x, y) then
            short.grid_button.onClick()
        elseif players[player].hudSetup.elements then
            players[player].hudSetup.onClick(eventName, address, player, x, y, button)
        else
            for moduleName, module in pairs(players[player].modules[players[player].current_hudPage]) do
                if module and module.elements and module.elements.backgroundBox and module.elements.backgroundBox.contains(x, y) then
                    module.onClick(eventName, address, player, x, y, button)
                end
            end
        end
    end
end

glasses_display.onClickRight = function(eventName, address, player, x, y, button)
    if eventName == "hud_click" and button == 1 then
        if players[player].contextMenu and players[player].contextMenu.elements and players[player].contextMenu.elements.backgroundBox.contains(x, y) then
            players[player].contextMenu.onClickRight(eventName, address, player, x, y, button)
        elseif players[player].hudSetup.elements then
            players[player].hudSetup.onClickRight(eventName, address, player, x, y, button)
        else
            for moduleName, module in pairs(players[player].modules[players[player].current_hudPage]) do
                if module and module.elements and module.elements.backgroundBox and module.elements.backgroundBox.contains(x, y) then
                    module.onClickRight(eventName, address, player, x, y, button)
                end
            end
        end
    end
end

glasses_display.onDrag = function(eventName, address, player, x, y, button)
    if eventName == "hud_drag" then
        if players[player].hudSetup.elements then 
            if players[player].contextMenu and players[player].contextMenu.elements then
                return false
            else
                players[player].hudSetup.onDrag(eventName, address, player, x, y, button)
            end
        end
    end
end

glasses_display.update = function(player)
    for index, page in ipairs(players[player].modules) do
        if index == players[player].current_hudPage then
            for moduleName, module in pairs(players[player].modules[index]) do
                module.update()
            end
        end
    end
end

return glasses_display