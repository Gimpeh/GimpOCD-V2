local component = require("component")
local c = require("core.modules.GimpOCD.lib.gimp_colors")
local glasses = component.glasses
local event = require("event")

local verbosity = false
local print = print
if not verbosity then
    print = function()
        return false
    end
end

local widgetsAreUs = {}

-------------------------------------------
--- Force Conformity

function widgetsAreUs.attachCoreFunctions(obj)
    print("widgetsAreUs - Line 11: Attaching core functions.")
    if obj.getID then
        print("widgetsAreUs - Line 13: Object has getID, attaching remove function.")
        obj.remove = function()
            component.glasses.removeObject(obj.getID())
            obj = nil
        end
    elseif type(obj) == "table" then
        print("widgetsAreUs - Line 19: Object is a table, attaching recursive remove function.")
        obj.remove = function()
            for k, v in pairs(obj) do
                if type(v) == "table" and v.remove then
                    v.remove()
                    obj[k] = nil
                elseif type(v) == "table" and v.getID then
                    component.glasses.removeObject(v.getID())
                    obj[k] = nil
                else
                    obj[k] = nil
                end
            end
            obj = nil
        end
    end
    if not obj.setVisible then
        print("widgetsAreUs - Line 33: Attaching setVisible function.")
        obj.setVisible = function(visible)
            for k, v in pairs(obj) do
                if type(v) == "table" and v.setVisible then
                    v.setVisible(visible)
                end
            end
        end
    end
    if not obj.update then
        obj.update = function() end
    end
    if not obj.onClick then
        obj.onClick = function() end
    end
    if not obj.onClickRight then
        obj.onClickRight = function() end
    end
    if not obj.onDrag then
        obj.onDrag = function() end
    end
    if not obj.onDragRight then
        obj.onDragRight = function() end
    end

    return obj
end

function widgetsAreUs.attachOnClick(obj, func)
    print("widgetsAreUs - Line 44: Attaching onClick function.")
    obj.onClick = function(...)
        return func(obj, ...)
    end
    return obj
end

function widgetsAreUs.attachOnClickRight(obj, func)
    print("widgetsAreUs - Line 50: Attaching onClickRight function.")
    obj.onClickRight = function(...)
        return func(obj, ...)
    end
    return obj
end

-------------------------------------------
--- Helper Functions

function widgetsAreUs.trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1")):gsub("%c", "")
end

function widgetsAreUs.handleTextInput(textLabel)
    textLabel.setText("")
    while true do
        local _, _, _, character = event.pull("hud_keyboard")
        if character == 13 then  -- Enter key
            break
        elseif character == 8 then  -- Backspace key
            textLabel.setText(textLabel.getText():sub(1, -2))
        else
            textLabel.setText(textLabel.getText() .. string.char(character))
        end
    end
    local trimmedText = tostring(widgetsAreUs.trim(textLabel.getText()))
    return trimmedText
end

function widgetsAreUs.shorthandNumber(numberToConvert)
    local num = tonumber(numberToConvert)
    local units = {"", "k", "M", "B", "T", "Qua", "E", "Z", "Y"}
    local unitIndex = 1
    while num >= 1000 and unitIndex < #units do
        num = num / 1000
        unitIndex = unitIndex + 1
    end
    return string.format("%.2f%s", num, units[unitIndex])
end

function widgetsAreUs.flash(obj, color, timer)
    if not color then color = c.clicked end
    if not timer then timer = 0.2 end
    local originalColor = {obj.getColor()}
    obj.setColor(table.unpack(color))
    event.timer(timer, function()
        obj.setColor(table.unpack(originalColor))
    end)
end

-------------------------------------------
--- Base

function widgetsAreUs.createBox(x, y, width, height, color, alpha)
    local box = glasses.addRect()
    box.setSize(height, width)
    box.setPosition(x, y)
    box.setColor(table.unpack(color))
    if alpha then box.setAlpha(alpha) end
    box.x = x box.x2 = x+width box.y = y box.y2 = y+height
    function box.contains(px, py)
        return px >= x and px <= box.x2 and py >= y and py <= box.y2
    end
    box.width = width box.height = height
    return widgetsAreUs.attachCoreFunctions(box)
end

function widgetsAreUs.text(x, y, text1, scale, color)
    local text = glasses.addTextLabel()
    text.setPosition(x, y)
    text.setScale(scale)
    text.setText(text1)
    if color then text.setColor(table.unpack(color)) end
    return widgetsAreUs.attachCoreFunctions(text)
end

function widgetsAreUs.textBox(x, y, width, height, color, alpha, text, textScale, xOffset, yOffset)
    local element = {}
    local box = widgetsAreUs.createBox(x, y, width, height, color, alpha)
    local text = widgetsAreUs.text(x + (xOffset or 5), y + (yOffset or 5), text, textScale or 1.5)

    return widgetsAreUs.attachCoreFunctions({box = box, text = text})
end

-------------------------------------------
--- Pop Up

function widgetsAreUs.alertMessage(color, message, timer)
    local box = widgetsAreUs.createBox(300, 200, 200, 100, color or c.brightred, 0.6)

    local text = widgetsAreUs.text(310, 210, message, 1.5)

    local function remove() component.glasses.removeObject(box.getID()) component.glasses.removeObject(text.getID()) text = nil box = nil end
    local timer = event.timer(timer, remove)

    return {timer = timer}
end

function widgetsAreUs.beacon(x, y, z, color)
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
    if not colorOrGreen then colorOrGreen = c.lime end
    local box = widgetsAreUs.createBox(x, y, 20, 20, colorOrGreen, 0.8)
    local symbol = widgetsAreUs.text(x+3, y+3, symbolText, 2)

    box.onClick = function()
        func(args)
        widgetsAreUs.flash(box)
    end

    return widgetsAreUs.attachCoreFunctions({box = box, symbol = symbol, onClick = box.onClick})
end

-------------------------------------------
--- Specific

function widgetsAreUs.levelMaintainer(x, y, argsTable)
    local itemStack = argsTable.itemStack
    local box = widgetsAreUs.titleBox(x, y, 150, 30, c.object, 0.8, itemStack.label)

    local batchText = widgetsAreUs.titleBox(x + 5, y + 10, 60, 20, c.configsetting, 0.8, "Batch")
    local batch = widgetsAreUs.text(x + 5, y + 20, tostring(argsTable.batch), 0.9)
    batch.onClick = function()
        batch.setText(tostring(widgetsAreUs.handleTextInput(batch)))
        local args = {batch = widgetsAreUs.trim(batch.getText())}
        return args
    end

    local amountText = widgetsAreUs.titleBox(x + 70, y + 10, 75, 20, c.configsetting, 0.8, "Amount")
    local amount = widgetsAreUs.text(x + 70, y + 20, tostring(argsTable.amount), 0.9)
    amount.onClick = function()
        amount.setText(tostring(widgetsAreUs.handleTextInput(amount)))
        local args = {amount = widgetsAreUs.trim(amount.getText())}
        return args
    end

    return widgetsAreUs.attachCoreFunctions({box = box.box, boxText = box.text, batch = batch, amount = amount, itemStack = itemStack, batchText = batchText, amountText = amountText, onClick = function(x1, y1)
        if batchText.box.contains(x1, y1) then
            batch.onClick()
        elseif amountText.box.contains(x1, y1) then
            amount.onClick()
        end
        
    end
    })
end

function widgetsAreUs.itemBox(x, y, itemStack)
    local background = widgetsAreUs.createBox(x, y, 80, 34, c.object, 0.8)

    local name = widgetsAreUs.text(x+2, y+2, itemStack.label, 0.9)

    local icon = component.glasses.addItem()
    icon.setPosition(x, y+6)
    if component.database then
        component.database.clear(1)
        component.database.set(1, itemStack.name, itemStack.damage, itemStack.tag)
        icon.setItem(component.database.address, 1)
    end

    local amount = widgetsAreUs.text(x+30, y+18, tostring(widgetsAreUs.shorthandNumber(itemStack.size)), 1)

    return widgetsAreUs.attachCoreFunctions({box = background, name = name, icon = icon, amount = amount, itemStack = itemStack,
    update = function()
        local updatedItemStack = component.me_interface.getItemsInNetwork({label = itemStack.label, name = itemStack.name, damage = itemStack.damage})[1]
        amount.setText(tostring(updatedItemStack.size))
    end
    })
end

function widgetsAreUs.searchBar(x, y, length)
    local box = widgetsAreUs.createBox(x, y, length, 20, c.objectinfo, 0.7)
    local text = widgetsAreUs.text(x+3, y+5, "Search", 1)

    return widgetsAreUs.attachCoreFunctions({box = box, text = text,
    getText = function()
        return text.getText()
    end,
    setText = function(text)
        text.setText(text)
    end
    })
end

return widgetsAreUs