local c = require("lib.gimp_colors")
local event = require("event")

local widgetsAreUs = {}

--local print = function() end

-------------------------------------------
--- Force Conformity

function widgetsAreUs.attachCoreFunctions(obj)
    print("widgetsAreUs - Line 12: Attaching core functions.")
    if not obj.remove then
        if obj.getID then
            print("widgetsAreUs - Line 14: Object has getID, attaching remove function.")
            obj.remove = function()
                print("widgetsAreUs - Line 16: Removing object with getID.")
                component.glasses.removeObject(obj.getID())
                obj = nil
            end
        elseif type(obj) == "table" then
            print("widgetsAreUs - Line 22: Object is a table, attaching recursive remove function.")
            obj.remove = function()
                print("widgetsAreUs - Line 24: Recursively removing table elements.")
                for k, v in pairs(obj) do
                    if type(v) == "table" and v.remove then
                        print("widgetsAreUs - Line 27: Removing nested table element.")
                        v.remove()
                        obj[k] = nil
                    elseif type(v) == "table" and v.getID then
                        print("widgetsAreUs - Line 31: Removing nested object with getID.")
                        component.glasses.removeObject(v.getID())
                        obj[k] = nil
                    end
                end
                obj = nil
            end
        end
    end
    if not obj.setVisible then
        print("widgetsAreUs - Line 42: Attaching setVisible function.")
        obj.setVisible = function(visible)
            print("widgetsAreUs - Line 44: Setting visibility to", visible)
            for k, v in pairs(obj) do
                if type(v) == "table" and v.setVisible then
                    print("widgetsAreUs - Line 47: Setting visibility for nested element.")
                    v.setVisible(visible)
                end
            end
        end
    end
    if not obj.update then
        print("widgetsAreUs - Line 53: Attaching update function.")
        obj.update = function() end
    end
    if not obj.onClick then
        print("widgetsAreUs - Line 56: Attaching onClick function.")
        obj.onClick = function() end
    end
    if not obj.onClickRight then
        print("widgetsAreUs - Line 59: Attaching onClickRight function.")
        obj.onClickRight = function() end
    end
    if not obj.onDrag then
        print("widgetsAreUs - Line 62: Attaching onDrag function.")
        obj.onDrag = function() end
    end
    if not obj.onDragRight then
        print("widgetsAreUs - Line 65: Attaching onDragRight function.")
        obj.onDragRight = function() end
    end

    return obj
end

function widgetsAreUs.attachOnClick(obj, func)
    print("widgetsAreUs - Line 72: Attaching onClick function.")
    obj.onClick = function(...)
        print("widgetsAreUs - Line 74: onClick triggered.")
        return func(...)
    end
    return obj
end

function widgetsAreUs.attachOnClickRight(obj, func)
    print("widgetsAreUs - Line 79: Attaching onClickRight function.")
    obj.onClickRight = function(...)
        print("widgetsAreUs - Line 81: onClickRight triggered.")
        return func(...)
    end
    return obj
end

-------------------------------------------
--- Helper Functions

function widgetsAreUs.trim(s)
    print("widgetsAreUs - Line 88: Trimming string.")
    return (s:gsub("^%s*(.-)%s*$", "%1")):gsub("%c", "")
end

function widgetsAreUs.handleTextInput(textLabel, player)
    disableOnClick()
    local break_flag = false
    local timer
    print("widgetsAreUs - Line 92: Handling text input.")
    textLabel.setText("")
    while true do
        if not timer then
            timer = event.timer(timing.thirty, function() break_flag = true timer = nil end)
        end
        if break_flag then break end
        local _, _, player_name, character = event.pull(timing.seven, "hud_keyboard")
        print("widgetsAreUs - Line 96: Keyboard event received.", tostring(player_name), tostring(character))
        if player == player_name then
            if character == 13 then  -- Enter key
                print("widgetsAreUs - Line 97: Enter key pressed, breaking loop.")
                enableOnClick()
                return widgetsAreUs.trim(textLabel.getText())
            elseif character == 8 then  -- Backspace key
                print("widgetsAreUs - Line 100: Backspace key pressed, removing last character.")
                textLabel.setText(textLabel.getText():sub(1, -2))
            else
                print("widgetsAreUs - Line 103: Adding character to text.")
                textLabel.setText(textLabel.getText() .. string.char(character))
            end
        end
    end
end

function widgetsAreUs.shorthandNumber(numberToConvert)
    print("widgetsAreUs - Line 112: Converting number to shorthand format.")
    local num = tonumber(numberToConvert)
    local units = {"", "k", "M", "B", "T", "Qua", "E", "Z", "Y"}
    local unitIndex = 1
    while num >= 1000 and unitIndex < #units do
        num = num / 1000
        unitIndex = unitIndex + 1
    end
    print("widgetsAreUs - Line 118: Returning formatted number.")
    return string.format("%.2f%s", num, units[unitIndex])
end

function widgetsAreUs.flash(obj, color, timer)
    print("widgetsAreUs - Line 122: Flashing object.")
    if not color then color = c.clicked end
    if not timer then timer = 0.2 end
    local originalColor = {obj.getColor()}
    obj.setColor(table.unpack(color))
    event.timer(timer, function()
        print("widgetsAreUs - Line 128: Restoring original color.")
        obj.setColor(table.unpack(originalColor))
    end)
end

-------------------------------------------
--- Base

function widgetsAreUs.createBox(x, y, width, height, color, alpha)
    print("widgetsAreUs - Line 135: Creating box.")
    local box = component.glasses.addRect()
    box.setSize(height, width)
    local old_setSize = box.setSize
    box.setPosition(x, y)
    box.setColor(table.unpack(color))
    if alpha then box.setAlpha(alpha) end
    box.x = x box.x2 = x+width box.y = y box.y2 = y+height
    box.setSize = function(height, width)
        print("widgetsAreUs - Line 142: Setting box size.")
        old_setSize(height, width)
        box.x2 = box.x + width box.y2 = box.y + height
    end
    function box.contains(px, py)
        print("widgetsAreUs - Line 143: Checking if point is inside box.")
        return px >= x and px <= box.x2 and py >= y and py <= box.y2
    end
    box.width = width box.height = height
    return widgetsAreUs.attachCoreFunctions(box)
end

function widgetsAreUs.text(x, y, text1, scale, color)
    print("widgetsAreUs - Line 150: Creating text label.")
    local text = component.glasses.addTextLabel()
    text.setPosition(x, y)
    text.setScale(scale)
    text.setText(text1)
    if color then text.setColor(table.unpack(color)) end
    return widgetsAreUs.attachCoreFunctions(text)
end

function widgetsAreUs.textBox(x, y, width, height, color, alpha, text, textScale, xOffset, yOffset)
    print("widgetsAreUs - Line 158: Creating text box.")
    local element = {}
    local box = widgetsAreUs.createBox(x, y, width, height, color, alpha)
    local text = widgetsAreUs.text(x + (xOffset or 5), y + (yOffset or 5), text, textScale or 1.5)

    return widgetsAreUs.attachCoreFunctions({box = box, text = text})
end

-------------------------------------------
--- Pop Up

function widgetsAreUs.popUp(x, y, width, height, line1, line2, line3, line4, line5, line6)
    print("widgetsAreUs - Line 166: Creating pop up.")
    local box = widgetsAreUs.createBox(x, y, width, height, c.beige, 0.5)
    local text1 = widgetsAreUs.text(x + 3, y + 3, line1, 1.2)
    local text2 = nil
    local text3 = nil
    local text4 = nil
    local text5 = nil
    local text6 = nil
    if line2 then
        text2 = widgetsAreUs.text(x + 3, y + 18, line2, 1.2)
    end
    if line3 then
        text3 = widgetsAreUs.text(x + 3, y + 33, line3, 1.2)
    end
    if line4 then
        text4 = widgetsAreUs.text(x + 3, y + 48, line4, 1.2)
    end
    if line5 then
        text5 = widgetsAreUs.text(x + 3, y + 63, line5, 1.2)
    end
    if line6 then
        text6 = widgetsAreUs.text(x + 3, y + 78, line6, 1.2)
    end
    local remove = function(player)
        component.glasses = require("displays.glasses_display").getGlassesProxy(player)
        print("widgetsAreUs - Line 166: Removing pop up.")
        component.glasses.removeObject(box.getID())
        component.glasses.removeObject(text1.getID())
        if text2 then component.glasses.removeObject(text2.getID()) end
        if text3 then component.glasses.removeObject(text3.getID()) end
        if text4 then component.glasses.removeObject(text4.getID()) end
        if text5 then component.glasses.removeObject(text5.getID()) end
        if text6 then component.glasses.removeObject(text6.getID()) end
        players[player].popUp = nil
    end
    box.onClick = function(eventName, address, player, x1, y1, button)
        remove(player)
    end
    return widgetsAreUs.attachCoreFunctions(box)
end

function widgetsAreUs.alertMessage(color, message, timer)
    print("widgetsAreUs - Line 167: Creating alert message.")
    local box = widgetsAreUs.createBox(300, 200, 200, 100, color or c.brightred, 0.6)

    local text = widgetsAreUs.text(310, 210, message, 1.5)

    local function remove()
        print("widgetsAreUs - Line 172: Removing alert message.")
        component.glasses.removeObject(box.getID())
        component.glasses.removeObject(text.getID())
        text = nil box = nil
    end
    local timer = event.timer(timer, remove)

    return {timer = timer}
end

function widgetsAreUs.beacon(x, y, z, color)
    print("widgetsAreUs - Line 180: Creating beacon.")
    local element = component.glasses.addDot3D()
    element.set3DPos(x, y, z)
    if color then
        element.setColor(table.unpack(color))
    else
        element.setColor(table.unpack(c.azure))
    end
    element.setViewDistance(500)
    element.setScale(1)
    return widgetsAreUs.attachCoreFunctions(element)
end

-------------------------------------------
--- Abstract

function widgetsAreUs.symbolBox(x, y, symbolText, colorOrGreen, func, args)
    print("widgetsAreUs - Line 193: Creating symbol box.")
    if not colorOrGreen then colorOrGreen = c.lime end
    local box = widgetsAreUs.createBox(x, y, 20, 20, colorOrGreen, 0.8)
    local symbol = widgetsAreUs.text(x+3, y+3, symbolText, 2)

    box.onClick = function()
        print("widgetsAreUs - Line 199: Symbol box clicked.")
        widgetsAreUs.flash(box)
        func(args)
    end

    return widgetsAreUs.attachCoreFunctions({box = box, symbol = symbol, onClick = box.onClick})
end

function widgetsAreUs.titleBox(x, y, width, height, color, alpha, text1)
    print("widgetsAreUs - Line 127: Creating a title box.")
    local box = widgetsAreUs.createBox(x, y, width, height, color, alpha)
    local text = widgetsAreUs.text(x + 20, y + 2, text1, 0.9)
    return widgetsAreUs.attachCoreFunctions{box = box, text = text}
end

-------------------------------------------
--- Specific

function widgetsAreUs.levelMaintainer(x, y, argsTable, player)
    print("widgetsAreUs - Line 208: Creating level maintainer.")
    local itemStack = argsTable.itemStack
    local box = widgetsAreUs.titleBox(x, y, 150, 30, c.object, 0.8, itemStack.label)

    local batchText = widgetsAreUs.titleBox(x + 5, y + 10, 60, 20, c.configsetting, 0.8, "Batch")
    local batch = widgetsAreUs.text(x + 5, y + 20, tostring(argsTable.batch), 0.9)
    batch.onClick = function()
        print("widgetsAreUs - Line 214: Batch text clicked.")
        batch.setText(tostring(widgetsAreUs.handleTextInput(batch, player)))
        local args = {batch = widgetsAreUs.trim(batch.getText())}
        return args
    end

    local amountText = widgetsAreUs.titleBox(x + 70, y + 10, 75, 20, c.configsetting, 0.8, "Amount")
    local amount = widgetsAreUs.text(x + 70, y + 20, tostring(argsTable.amount), 0.9)
    amount.onClick = function()
        print("widgetsAreUs - Line 221: Amount text clicked.")
        amount.setText(tostring(widgetsAreUs.handleTextInput(amount, player)))
        local args = {amount = widgetsAreUs.trim(amount.getText())}
        return args
    end

    return widgetsAreUs.attachCoreFunctions({box = box.box, boxText = box.text, batch = batch, amount = amount, itemStack = itemStack, batchText = batchText, amountText = amountText, onClick = function(_, _, _, x1, y1, _)
        print("widgetsAreUs - Line 228: Level maintainer clicked.")
        if batchText.box.contains(x1, y1) then
            batch.onClick()
        elseif amountText.box.contains(x1, y1) then
            amount.onClick()
        end
    end
    })
end

function widgetsAreUs.itemBox(x, y, itemStack)
    print("widgetsAreUs - Line 238: Creating item box.")
    local background = widgetsAreUs.createBox(x, y, 80, 34, c.object, 0.8)

    local name = widgetsAreUs.text(x+2, y+2, itemStack.label, 0.9)

    local icon = component.glasses.addItem()
    icon.setPosition(x, y+6)
    if component.database then
        print("widgetsAreUs - Line 245: Setting item in database.")
        component.database.clear(1)
        component.database.set(1, itemStack.name, itemStack.damage, itemStack.tag)
        icon.setItem(component.database.address, 1)
    end

    local amount = widgetsAreUs.text(x+30, y+18, tostring(widgetsAreUs.shorthandNumber(itemStack.size)), 1)

    return widgetsAreUs.attachCoreFunctions({box = background, name = name, icon = icon, amount = amount,
    update = function()
        print("widgetsAreUs - Line 253: Updating item box.")
        local updatedItemStack = component.me_interface.getItemsInNetwork({label = itemStack.label, name = itemStack.name, damage = itemStack.damage})[1]
        amount.setText(tostring(updatedItemStack.size))
    end
    })
end

function widgetsAreUs.searchBar(x, y, length)
    print("widgetsAreUs - Line 260: Creating search bar.")
    local box = widgetsAreUs.createBox(x, y, length, 20, c.objectinfo, 0.7)
    local text = widgetsAreUs.text(x+3, y+5, "Search", 1)

    return widgetsAreUs.attachCoreFunctions({box = box, text = text,
    getText = function()
        print("widgetsAreUs - Line 265: Getting search bar text.")
        return text.getText()
    end,
    setText = function(newText)
        print("widgetsAreUs - Line 268: Setting search bar text.")
        text.setText(newText)
    end
    })
end

function widgetsAreUs.windowTitle(x, y, width, text)
    local titleBox = widgetsAreUs.createBox(x, y, width, 20, c.black, 0.8)
    local title = widgetsAreUs.text(x+10, y+5, text, 1, c.white)

    return widgetsAreUs.attachCoreFunctions({box = titleBox, text = title})
end

return widgetsAreUs