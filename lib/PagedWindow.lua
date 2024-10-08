-- v.1.0.2
local PagedWindow = {}
PagedWindow.__index = PagedWindow

local verbosity = true
local print = print

if not verbosity then
    print = function()
        return false
    end
end

-- Constructor function
function PagedWindow.new(items, itemWidth, itemHeight, screenBounds, padding, renderItem, array)
    print("PagedWindow - Line 6: Initializing new PagedWindow.")
    local self = setmetatable({}, PagedWindow)
    self.items = items or {}  -- A table containing all items
    self.itemWidth = itemWidth  -- Width of each item
    self.itemHeight = itemHeight  -- Height of each item
    self.padding = padding or 5  -- Default padding of 5 pixels if not provided
    self.renderItem = renderItem or function() end  -- Function to render an individual item
    if array then
        self.args = array
    end

    -- Define screen bounds from the provided table
    self.screenX1 = screenBounds.x1
    self.screenY1 = screenBounds.y1
    self.screenX2 = screenBounds.x2
    self.screenY2 = screenBounds.y2

    -- Calculate available width and height
    local availableWidth = self.screenX2 - self.screenX1
    local availableHeight = self.screenY2 - self.screenY1

    -- Calculate the number of items per row and column, considering padding
    self.itemsPerRow = math.floor((availableWidth + self.padding) / (itemWidth + self.padding))
    self.itemsPerColumn = math.floor((availableHeight + self.padding) / (itemHeight + self.padding))
    self.itemsPerPage = self.itemsPerRow * self.itemsPerColumn  -- Total items per page

    self.currentPage = 1  -- Start on the first page
    self.currentlyDisplayed = {}  -- Keep track of currently displayed items
    print("PagedWindow - Line 29: PagedWindow initialized with itemsPerPage =", tostring(self.itemsPerPage))
    return self
end

-- Function to clear currently displayed items
function PagedWindow:clearDisplayedItems()
    print("PagedWindow - Line 34: Clearing displayed items.")
        for _, element in pairs(self.currentlyDisplayed) do
            print("PagedWindow - Line 39: Trying Removing element.")
            if element.remove then
                print("element has remove method")
                element.remove()  -- Call the remove method of each element if it exists
            else
                print("element has no remove method")
            end
        end
        self.currentlyDisplayed = {}
    print("") -- Blank line for readability
end

-- Function to display items for the current page
function PagedWindow:displayItems()
    print("PagedWindow - Line 47: Displaying items for current page.")
    local success, err = pcall(function()
        print("PagedWindow - Line 49: Starting displayItems.")
        self:clearDisplayedItems()  -- Clear previously displayed items
        print("PagedWindow - Line 51: Cleared displayed items.")

        local startIndex = (self.currentPage - 1) * self.itemsPerPage + 1
        local endIndex = math.min(self.currentPage * self.itemsPerPage, #self.items)
        print("PagedWindow - Line 55: Start index: " .. tostring(startIndex) .. ", End index: " .. tostring(endIndex))

        for i = startIndex, endIndex do
            print("PagedWindow - Line 59: Displaying item index: " .. tostring(i))

            -- Calculate row and column based on dynamic values
            local row = math.floor((i - startIndex) / self.itemsPerRow)
            local col = (i - startIndex) % self.itemsPerRow
            local x = self.screenX1 + col * (self.itemWidth + self.padding)
            local y = self.screenY1 + row * (self.itemHeight + self.padding)

            local item = self.items[i]
            if item then
                print("PagedWindow - Line 71: Item found: " .. tostring(item))
            else
                print("PagedWindow - Line 73: Item not found at index " .. tostring(i))
            end

            -- Ensure self.args is initialized correctly
            if self.args then
                print("PagedWindow - Line 77: Args exists, checking index: " .. tostring(i))
                if not self.args[i] and self.args[1] then
                    print("PagedWindow - Line 79: Arg index " .. tostring(i) .. " is nil, initializing.")
                    self.args[i] = self.args[1]
                elseif not self.args[i] then
                    print("PagedWindow - Line 82: Arg index " .. tostring(i) .. " is nil, creating and initializing.")
                    self.args[i] = i
                end
            else
                print("PagedWindow - Line 83: Args not initialized, creating and initializing at index " .. tostring(i))
                self.args = {}
                self.args[i] = i
            end

            if item then
                print("PagedWindow - Line 88: Rendering item at x=" .. tostring(x) .. ", y=" .. tostring(y))
                local displayedItem = self.renderItem(x, y, item, self.args[i])
                table.insert(self.currentlyDisplayed, displayedItem)
                print("PagedWindow - Line 91: Item rendered and stored.")
            end
        end
    end)
    if not success then
        print("PagedWindow - Line 95: Error in displayItems: " .. tostring(err))
    else
        print("PagedWindow - Line 97: displayItems completed successfully.")
    end
    print("") -- Blank line for readability
end

-- Function to go to the next page
function PagedWindow:nextPage()
    print("PagedWindow - Line 103: Going to the next page.")
    local success, err = pcall(function()
        local totalPages = math.ceil(#self.items / self.itemsPerPage)
        if self.currentPage < totalPages then
            self.currentPage = self.currentPage + 1
            self:displayItems()
        else
            print("PagedWindow - Line 109: Already on the last page.")
        end
    end)
    if not success then
        print("PagedWindow - Line 113: Error in nextPage: " .. tostring(err))
    end
    print("") -- Blank line for readability
end

-- Function to go to the previous page
function PagedWindow:prevPage()
    print("PagedWindow - Line 119: Going to the previous page.")
    local success, err = pcall(function()
        if self.currentPage > 1 then
            self.currentPage = self.currentPage - 1
            self:displayItems()
        else
            print("PagedWindow - Line 125: Already on the first page.")
        end
    end)
    if not success then
        print("PagedWindow - Line 129: Error in prevPage: " .. tostring(err))
    end
    print("") -- Blank line for readability
end

-- Function to update items and refresh the display
function PagedWindow:setItems(items)
    print("PagedWindow - Line 135: Setting new items and refreshing display.")
    local success, err = pcall(function()
        self.items = items
        self.currentPage = 1  -- Reset to the first page when items are updated
        self:displayItems()
    end)
    if not success then
        print("PagedWindow - Line 142: Error in setItems: " .. tostring(err))
    end
    print("") -- Blank line for readability
end

return PagedWindow