local component = require("component")
local widgetsAreUs = require("displays.widgetsAreUs")
local c = require("lib.gimp_colors")
local gimpHelper = require("lib.gimpHelper")
local event = require("event")

local power_overseer = {}

power_overseer.onClick = nil
power_overseer.onClickRight = nil
power_overseer.setVisible = nil
power_overseer.remove = nil

local function widget(x, y, width, height, player)
    component.glasses = require("displays.glasses_display").getGlassesProxy(player)
    local backgroundBox = widgetsAreUs.createBox(x, y, 203, 183, {0, 0, 0}, 0.8)

    local backgroundInterior = component.glasses.addRect()
    backgroundInterior.setPosition(x + 5, y + 5)
    backgroundInterior.setSize(173, 193)
    backgroundInterior.setColor(13, 255, 255)
    backgroundInterior.setAlpha(0.7)

    local header = component.glasses.addTextLabel()
    header.setScale(2)
    header.setText("Power Metrics")
    header.setPosition(x + 33, y + 10)
    
    local euInLabel = component.glasses.addTextLabel()
    euInLabel.setText("EU IN :")
    euInLabel.setPosition(x + 23, y + 43)
    euInLabel.setScale(2)

    local euInText = component.glasses.addTextLabel()
    euInText.setPosition(x + 103, y + 45)
    euInText.setText(" ")
    euInText.setScale(2)

    local euOutLabel = component.glasses.addTextLabel()
    euOutLabel.setText("EU OUT:")
    euOutLabel.setPosition(x + 15, y + 68)
    euOutLabel.setScale(2)

    local euOutText = component.glasses.addTextLabel()
    euOutText.setScale(2)
    euOutText.setText(" ")
    euOutText.setPosition(x + 103, y + 69)

    local wireless_stored_power_label = component.glasses.addTextLabel()
    wireless_stored_power_label.setText("Wireless:")
    wireless_stored_power_label.setPosition(x + 9, y + 100)
    wireless_stored_power_label.setScale(2)

    local wireless_stored_power_number = component.glasses.addTextLabel()
    wireless_stored_power_number.setText(" ")
    wireless_stored_power_number.setPosition(x + 103, y + 100)
    wireless_stored_power_number.setScale(2)

    local stored_label = component.glasses.addTextLabel()
    stored_label.setText("Stored:")
    stored_label.setPosition(x + 20, y + 125)
    stored_label.setScale(2)

    local storedNumber = component.glasses.addTextLabel()
    storedNumber.setText("")
    storedNumber.setPosition(x + 103, y + 125)
    storedNumber.setScale(2)

    local fillBarBackground = component.glasses.addRect()
    fillBarBackground.setPosition(x + 108, y + 148)
    fillBarBackground.setSize(20, 80)

    local fillBarForeground = component.glasses.addRect()
    fillBarForeground.setPosition(x + 108, y + 148)
    fillBarForeground.setSize(20, 1)
    fillBarForeground.setColor(1, 1, 0)

    local percentPower = component.glasses.addTextLabel()
    percentPower.setPosition(x + 33, y + 148)
    percentPower.setText(" ")
    percentPower.setScale(2)

    return {
        update = function(unserializedTable)
            local euin = unserializedTable.powerIn
            local out = unserializedTable.powerOut
            euInText.setText(widgetsAreUs.shorthandNumber(euin))
            euOutText.setText(widgetsAreUs.shorthandNumber(out))
            local euStored = unserializedTable.stored
            local powerMax = unserializedTable.max
            wireless_stored_power_number.setText(widgetsAreUs.shorthandNumber(gimpHelper.cleanBatteryStorageString(unserializedTable.wireless)))
            local percent = gimpHelper.calculatePercentage(euStored, powerMax)
            storedNumber.setText(gimpHelper.shorthandNumber(gimpHelper.cleanBatteryStorageString(euStored)))
            local fillWidth = math.ceil(74 * (percent / 100))
            fillBarForeground.setSize(20, fillWidth)
            percentPower.setText(string.format("%.2f%%", tonumber(percent)))
        end
    }
end

power_overseer.init = function(x, y, player)
    -- init tables and variables

    -- Create a pop-up instructing user

    while true do
        component.glasses = require("displays.glasses_display").getGlassesProxy(player)
        
        --read click (left and right do same as last time)
        local _, _, player_name, x, y, button = event.pull("hud_click")
        
        -- deal with clicks
        if button == 0 then
            -- Init Widget at location
        elseif button == 1 then
            -- Init Widget at 'negative' location
        elseif button == 2 then
            --remove pop-up
            break
        end
    end

    -- set background box on global table
    -- set functions on global table
end

return power_overseer