local contextMenu = {}
local widgetsAreUs = require("lib.widgetsAreUs")
local c = require("lib.gimp_colors")

contextMenu.remove = nil

local choiceHeight = 10

---@param x2 x
---@param y2 y
---@param player player
---@param funcTable funcTable
---@param funcTable.text contextMenuOptionText
---@param funcTable.func onClick
---@param funcTable.args args for onClick
function contextMenu.init(x2, y2, player, funcTable)
    print("contextMenu - Line 10: Initializing context menu")
    --[[
    funcTable = {
        [1] = {text = "text", func = function, args = {args}},
        [2] = {text = "text", func = function, args = {args}},
            and so on
    ]]
    local x = math.floor(x2)
    local y = math.floor(y2)

    local suc, err = pcall(function()
        print("contextMenu - Line 16: Getting glasses proxy for player")
        component.glasses = require("displays.glasses_display").getGlassesProxy(player)

        if players[player].contextMenu and players[player].contextMenu.elements then
            print("contextMenu - Line 19: Removing existing context menu")
            contextMenu.remove(player)
        end

        if not players[player].contextMenu then
            print("contextMenu - Line 23: Creating new context menu structure")
            players[player].contextMenu = {}
        end

        players[player].contextMenu.elements = {}
        players[player].contextMenu.elements.backgroundBox = widgetsAreUs.createBox(x, y, 100, 1, c.contextMenuBackground, 0.3)
        print("contextMenu - Line 28: Created background box")

        local i = 0
        for key, args in ipairs(funcTable) do
            print("contextMenu - Line 31: Adding option " .. args.text)
            local text = widgetsAreUs.text(x + 1, y + 1 + (choiceHeight * i), args.text, 1.0, c.contextMenuPrimaryColour)
            table.insert(players[player].contextMenu.elements, text)
            if i > 0 then
                print("contextMenu - Line 35: Adding divisor")
                local divisor = widgetsAreUs.createBox(x, y + (choiceHeight * i) - 1, 100, 1, c.contextMenuBackground, 0.3)
                table.insert(players[player].contextMenu.elements, divisor)
            end
            i = i + 1
        end

        print("contextMenu - Line 41: Setting background box size")
        players[player].contextMenu.elements.backgroundBox.setSize(i * choiceHeight, 150)
        players[player].contextMenu.funcTable = funcTable
    end)
    if not suc then print("contextMenu - Line 46: " .. err) end
end

function contextMenu.onClick(eventName, address, player, x, y, button)
    print("contextMenu - Line 50: Handling onClick event", x, y)
    --local suc, err = pcall(function()
        component.glasses = require("displays.glasses_display").getGlassesProxy(player)
        if eventName == "hud_click" and button == 0 then
            print("contextMenu - Line 54: Left-click detected")
            if players[player].contextMenu.elements.backgroundBox.contains(x, y) then
                local choice = math.floor((y - players[player].contextMenu.elements.backgroundBox.y) / choiceHeight) + 1
                print("contextMenu - Line 57: Choice selected - " .. choice)
                local func = players[player].contextMenu.funcTable[choice].func
                local args = players[player].contextMenu.funcTable[choice].args
                contextMenu.remove(player)
                if args and args[1] then
                    print("contextMenu - Line 60: Calling function with arguments")
                    func(table.unpack(args))
                else
                    print("contextMenu - Line 63: Calling function without arguments")
                    func()
                end
            end
            return true
        end
    --end)
    --if not suc then print("contextMenu - Line 70: " .. err) end
end

function contextMenu.onClickRight(eventName, address, player, x, y, button)
    print("contextMenu - Line 74: Handling onClickRight event")
    local suc, err = pcall(function()
        if eventName == "hud_click" and button == 1 then
            print("contextMenu - Line 76: Right-click detected - removing context menu")
            contextMenu.remove(player)
            return true
        end
    end)
    if not suc then print("contextMenu - Line 80: " .. err) end
end

function contextMenu.remove(player)
    print("contextMenu - Line 84: Removing context menu for player")
    local suc, err = pcall(function()
        component.glasses = require("displays.glasses_display").getGlassesProxy(player)

        print("contextMenu - Line 87: Removing background box")
        players[player].contextMenu.elements.backgroundBox.remove()
        players[player].contextMenu.elements.backgroundBox = nil
        for i, element in ipairs(players[player].contextMenu.elements) do
            print("contextMenu - Line 91: Removing element " .. i)
            element.remove()
            players[player].contextMenu.elements[i] = nil
        end
        players[player].contextMenu.elements = nil
        players[player].contextMenu.funcTable = nil
        return true
    end)
    if not suc then 
        print("contextMenu - Line 96: " .. err) 
        error("context 114 - attempt to get stack", 2)
    end
end

return contextMenu