local contextMenu = {}
local widgetsAreUs = require("lib.widgetsAreUs")
local c = require("lib.gimp_colors")

contextMenu.remove = nil

local choiceHeight = 10

function contextMenu.init(x, y, player, funcTable)
    --[[
    funcTable = {
        [1] = {text = "text", func = function, args = {args}},
        [2] = {text = "text", func = function, args = {args}},
            and so on
    ]]

    --clear pre-existing (if any)
    component.glasses = require("lib.glasses_display").getGlassProxy(player)

    if players[player].contextMenu then
        contextMenu.remove(player)
    end

    if not players[player].contextMenu then
        players[player].contextMenu = {}
    end
    players[player].contextMenu.elements = {}
    players[player].contextMenu.elements.backgroundBox = widgetsAreUs.createBox(x, y, 100, 1, c.contextMenuBackground, 0.3)

    local i=0
    for key, args in ipairs(funcTable) do

        local text = widgetsAreUs.text(x+1, y+1+(choiceHeight*i), args.text, 1.0, c.contextMenuPrimaryColour)
        table.insert(players[player].contextMenu.elements, text)
        if i > 0 then
            local divisor = widgetsAreUs.createBox(x, y+(choiceHeight*i)-1, 100, 1, c.contextMenuBackground, 0.3)
            table.insert(players[player].contextMenu.elements, divisor)
        end
        i = i + 1
    end
    players[player].contextMenu.elements.backgroundBox.setSize(i*choiceHeight, 100)
    players[player].contextMenu.funcTable = funcTable
end

function contextMenu.onClick(eventName, address, player, x, y, button)
    component.glasses = require("displays.glasses_display").getGlassProxy(player)
    if eventName == "hud_click" and button == 0 then
        if players[player].contextMenu.elements.backgroundBox.contains(x, y) then
            local choice = (y - players[player].contextMenu.elements.backgroundBox.y) / choiceHeight
            local func = players[player].contextMenu.funcTable[choice].func
            if players[player].contextMenu.funcTable[choice].args and players[player].contextMenu.funcTable[choice].args[1] then
                func(table.unpack(players[player].contextMenu.funcTable[choice].args))
            else
                func()
            end
        end
        contextMenu.remove(player)
        return true
    end
end

function contextMenu.onClickRight(eventName, address, player, x, y, button)
    if eventName == "hud_click" and button == 1 then
        contextMenu.remove(player)
        return true
    end
end

function contextMenu.remove(player)
    component.glasses = require("displays.glasses_display").getGlassProxy(player)
    
    players[player].contextMenu.elements.backgroundBox.remove()
    players[player].contextMenu.elements.backgroundBox = nil
    for i, element in ipairs(players[player].contextMenu.elements) do
        element.remove()
        players[player].contextMenu.elements[i] = nil
    end
    players[player].contextMenu.elements = nil
    return true
end

return contextMenu