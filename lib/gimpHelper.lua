

local gimpHelper = {}

function gimpHelper.saveTable(tblToSave, filename)
    local function serialize(tbl)
        local result = "{"
        local first = true
        for k, v in pairs(tbl) do
            if not first then 
                result = result .. ","
            else 
                first = false 
            end

            local key = type(k) == "string" and k or "["..k.."]"
            local value
            if type(v) == "table" then
                value = serialize(v)
            elseif type(v) == "string" then
                value = string.format("%q", v)
            else
                value = tostring(v)
            end
            result = result .. key .. "=" .. value
        end
        return result .. "}"
    end

    local file, err = io.open(filename, "w")
    if not file then
        return false, "Unable to open file for writing"
    end

    file:write("return " .. serialize(tblToSave))
    file:close()
    return true
end

function gimpHelper.loadTable(filename)
    local file, err = io.open(filename, "r")
    if not file then
        return nil, "Unable to open file for reading"
    end

    local content = file:read("*a")
    file:close()
    local func = load(content)
    if not func or type(func) ~= "function" then
        return nil, "Unable to load file content"
    end
    local tbl = func()
    return tbl
end

function gimpHelper.cleanBatteryStorageString(numberStr)
    local cleanStr = tostring(numberStr):gsub(",", ""):gsub("EU Stored: ", ""):gsub("EU", "")
    local result = tonumber(cleanStr)
    return result
end

function gimpHelper.calculatePercentage(currentAmountStr, maxAmount)
    local currentAmount = gimpHelper.cleanBatteryStorageString(currentAmountStr)
    local maxAmountNum = tonumber(maxAmount)

    if currentAmount >= maxAmountNum then
        currentAmount = math.floor(currentAmount / 1e8)
        maxAmountNum = math.floor(maxAmountNum / 1e8)
    end

    local percentage = (currentAmount / maxAmountNum) * 100
    return percentage
end

function gimpHelper.correctCoordinates(xyzTable, glassesControllerXYZtable)
    if not glassesControllerXYZtable then
        return xyzTable
    end
    local correctedTable = {}
    correctedTable.x = xyzTable.x - glassesControllerXYZtable.x
    correctedTable.y = xyzTable.y - glassesControllerXYZtable.y
    correctedTable.z = xyzTable.z - glassesControllerXYZtable.z
    return correctedTable
end

return gimpHelper