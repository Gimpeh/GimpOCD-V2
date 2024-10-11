local widgetsAreUs = require("lib.widgetsAreUs")
local c = require("lib.gimp_colors")
local gimpHelper = require("lib.gimpHelper")
local event = require("event")
local contextMenu = require("displays.glasses_elements.contextMenu")
local s = require("serialization")

local power_overseer = {}
power_overseer.players = {}

power_overseer.onClick = nil
power_overseer.onClickRight = nil
power_overseer.setVisible = nil
power_overseer.remove = nil
power_overseer.onModemMessage = nil

print("power_overseer [Line 12]  -Initialized power_overseer table")

local function widget(x, y, width, height, player)
    print("power_overseer [Line 17]  -Creating widget for player: " .. player)
    component.glasses = require("displays.glasses_display").getGlassesProxy(player)
    local backgroundBox = widgetsAreUs.createBox(x, y, 203, 183, {0, 0, 0}, 0.8)
    print("power_overseer [Line 20]  -Created background box")

    local backgroundInterior = widgetsAreUs.attachCoreFunctions(component.glasses.addRect())
    backgroundInterior.setPosition(x + 5, y + 5)
    backgroundInterior.setSize(173, 193)
    backgroundInterior.setColor(13, 255, 255)
    backgroundInterior.setAlpha(0.7)
    print("power_overseer [Line 25]  -Created background interior")

    local header = widgetsAreUs.attachCoreFunctions(component.glasses.addTextLabel())
    header.setScale(2)
    header.setText("Power Metrics")
    header.setPosition(x + 33, y + 10)
    print("power_overseer [Line 31]  -Created header label")
    
    local euInLabel = widgetsAreUs.attachCoreFunctions(component.glasses.addTextLabel())
    euInLabel.setText("EU IN :")
    euInLabel.setPosition(x + 23, y + 43)
    euInLabel.setScale(2)
    print("power_overseer [Line 36]  -Created EU IN label")

    local euInText = widgetsAreUs.attachCoreFunctions(component.glasses.addTextLabel())
    euInText.setPosition(x + 103, y + 45)
    euInText.setText(" ")
    euInText.setScale(2)
    print("power_overseer [Line 41]  -Created EU IN text label")

    local euOutLabel = widgetsAreUs.attachCoreFunctions(component.glasses.addTextLabel())
    euOutLabel.setText("EU OUT:")
    euOutLabel.setPosition(x + 15, y + 68)
    euOutLabel.setScale(2)
    print("power_overseer [Line 46]  -Created EU OUT label")

    local euOutText = widgetsAreUs.attachCoreFunctions(component.glasses.addTextLabel())
    euOutText.setScale(2)
    euOutText.setText(" ")
    euOutText.setPosition(x + 103, y + 69)
    print("power_overseer [Line 51]  -Created EU OUT text label")

    local wireless_stored_power_label = widgetsAreUs.attachCoreFunctions(component.glasses.addTextLabel())
    wireless_stored_power_label.setText("Wireless:")
    wireless_stored_power_label.setPosition(x + 9, y + 100)
    wireless_stored_power_label.setScale(2)
    print("power_overseer [Line 56]  -Created wireless stored power label")

    local wireless_stored_power_number = widgetsAreUs.attachCoreFunctions(component.glasses.addTextLabel())
    wireless_stored_power_number.setText(" ")
    wireless_stored_power_number.setPosition(x + 103, y + 100)
    wireless_stored_power_number.setScale(2)
    print("power_overseer [Line 61]  -Created wireless stored power number label")

    local stored_label = widgetsAreUs.attachCoreFunctions(component.glasses.addTextLabel())
    stored_label.setText("Stored:")
    stored_label.setPosition(x + 20, y + 125)
    stored_label.setScale(2)
    print("power_overseer [Line 66]  -Created stored label")

    local storedNumber = widgetsAreUs.attachCoreFunctions(component.glasses.addTextLabel())
    storedNumber.setText("")
    storedNumber.setPosition(x + 103, y + 125)
    storedNumber.setScale(2)
    print("power_overseer [Line 71]  -Created stored number label")

    local fillBarBackground = widgetsAreUs.attachCoreFunctions(component.glasses.addRect())
    fillBarBackground.setPosition(x + 108, y + 148)
    fillBarBackground.setSize(20, 80)
    print("power_overseer [Line 75]  -Created fill bar background")

    local fillBarForeground = widgetsAreUs.attachCoreFunctions(component.glasses.addRect())
    fillBarForeground.setPosition(x + 108, y + 148)
    fillBarForeground.setSize(20, 1)
    fillBarForeground.setColor(1, 1, 0)
    print("power_overseer [Line 79]  -Created fill bar foreground")

    local percentPower = widgetsAreUs.attachCoreFunctions(component.glasses.addTextLabel())
    percentPower.setPosition(x + 33, y + 148)
    percentPower.setText(" ")
    percentPower.setScale(2)
    print("power_overseer [Line 83]  -Created percent power label")

    return {
        backgroundBox = backgroundBox,
        remove = function()
            print("power_overseer [Line 88]  -Removing widget components")
            backgroundBox.remove()
            backgroundInterior.remove()
            header.remove()
            euInLabel.remove()
            euInText.remove()
            euOutLabel.remove()
            euOutText.remove()
            wireless_stored_power_label.remove()
            wireless_stored_power_number.remove()
            stored_label.remove()
            storedNumber.remove()
            fillBarBackground.remove()
            fillBarForeground.remove()
            percentPower.remove()

            backgroundBox = nil
            backgroundInterior = nil
            header = nil
            euInLabel = nil
            euInText = nil
            euOutLabel = nil
            euOutText = nil
            wireless_stored_power_label = nil
            wireless_stored_power_number = nil
            stored_label = nil
            storedNumber = nil
            fillBarBackground = nil
            fillBarForeground = nil
            percentPower = nil
            print("power_overseer [Line 111] - Widget components removed")
        end,
        update = function(serializedTable)
            print("power_overseer [Line 113] - Unserializing table")
            local unserializedTable = s.unserialize(serializedTable)
            print("power_overseer [Line 114] - Updating widget components with new data")
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
            print("power_overseer [Line 125] - Widget components updated")
        end
    }
end

power_overseer.init = function(player)
    print("power_overseer [Line 131] - Initializing power_overseer for player: " .. player)
    local suc, err = pcall(function()
        component.glasses = require("displays.glasses_display").getGlassesProxy(player)
        players[player].availableModules.power_overseer = nil
        power_overseer.players[player] = {}
        print("power_overseer [Line 136] - Setting up power_overseer for player: " .. player)

        local popUp = widgetsAreUs.popUp(players[player].resolution.x -200, 1, 190, 100,
            "Left Click to Set Position",
            "Right Click to Set Position from ends",
            "Middle Click to Accept"
        )
        popUp.setColor(table.unpack(c.white))
        popUp.setColor(table.unpack(c.beige))
        popUp.setColor(table.unpack(c.white))
        popUp.setColor(table.unpack(c.beige))
        print("power_overseer [Line 144] - Created pop-up for player: " .. player)

        if players[player].popUp then
            players[player].popUp.onClick(1, 2, player)
            print("power_overseer [Line 148] - Removed existing pop-up for player: " .. player)
        end
        players[player].popUp = popUp

        if players[player].hudSetup.elements.window then
            players[player].hudSetup.elements.window.remove()
            players[player].hudSetup.elements.window = nil
        end

        if players[player].contextMenu and players[player].contextMenu.elements then
            contextMenu.remove(player)
        end

        while true do
            component.glasses = require("displays.glasses_display").getGlassesProxy(player)
            disableOnClick()
            print("power_overseer [Line 154] - Waiting for hud_click event for player: " .. player)
            local _, _, player_name, x, y, button = event.pull("hud_click")
        
            if button == 0 and player == player_name then
                print("power_overseer [Line 158] - Left click detected for player: " .. player)
                if power_overseer.players[player].widget then
                    power_overseer.remove(player)
                end
                power_overseer.players[player].widget = widget(x, y, 203, 183, player)
            elseif button == 1 then
                print("power_overseer [Line 164] - Right click detected for player: " .. player)
                if power_overseer.players[player].widget then
                    power_overseer.remove(player)
                end
                power_overseer.players[player].widget = widget(x-203, y-183, 203, 183, player)
            elseif button == 2 then
                print("power_overseer [Line 170] - Middle click detected for player: " .. player)
                if power_overseer.players[player].widget then
                    if players[player].popUp then
                        players[player].popUp.onClick(1, 2, player)
                    end
                    players[player].modules[players[player].current_hudPage].power_overseer = {}
                    players[player].modules[players[player].current_hudPage].power_overseer.elements = {} 
                    players[player].modules[players[player].current_hudPage].power_overseer.elements.backgroundBox = power_overseer.players[player].widget.backgroundBox
                    players[player].modules[players[player].current_hudPage].power_overseer.onClick = power_overseer.onClick
                    players[player].modules[players[player].current_hudPage].power_overseer.onClickRight = power_overseer.onClickRight
                    players[player].modules[players[player].current_hudPage].power_overseer.setVisible = power_overseer.setVisible
                    players[player].modules[players[player].current_hudPage].power_overseer.onModemMessage = power_overseer.onModemMessage
                    players[player].availableModules.power_overseer = nil
                end
                enableOnClick()
                break
            end
        end
    end)
    if not suc then
        print("Error in power_overseer.init: " .. err)
    end
    print("power_overseer [Line 192] - Finished initializing power_overseer for player: " .. player)
end

power_overseer.remove = function(player)
    print("power_overseer [Line 196] - Removing power_overseer for player: " .. player)
    component.glasses = require("displays.glasses_display").getGlassesProxy(player)
    power_overseer.players[player].widget.remove()
    power_overseer.players[player].widget = nil

    if players[player].modules[players[player].current_hudPage].power_overseer then
        players[player].modules[players[player].current_hudPage].power_overseer = nil
        power_overseer.players[player] = nil
        players[player].availableModules.power_overseer = power_overseer.init
        print("power_overseer [Line 205] - Fully removed power_overseer for player: " .. player)
    end
end

power_overseer.onClick = function(eventName, address, player, x, y, button)
    print("power_overseer [Line 210] - onClick event triggered for player: " .. player)
end

power_overseer.onClickRight = function(eventName, address, player, x, y, button)
    print("power_overseer [Line 214] - onClickRight event triggered for player: " .. player)
    local context = contextMenu.init(x, y, player, {
        [1] = {text = "Remove", func = function() power_overseer.remove(player) end, args = {}
        }
    })
end

power_overseer.setVisible = function(visible, player)
    print("power_overseer [Line 221] - Setting visibility of power_overseer for player: " .. player .. " to " .. tostring(visible))
    component.glasses = require("displays.glasses_display").getGlassesProxy(player)
    power_overseer.players[player].widget.setVisible(visible)
end

power_overseer.onModemMessage = function(serializedTable)
    for player, _ in pairs(players) do
        print("power_overseer [Line 226] - onModemMessage event received. processing player: ", tostring(player))
        component.glasses = require("displays.glasses_display").getGlassesProxy(player)
        power_overseer.players[player].widget.update(serializedTable, player)
    end
end

return power_overseer