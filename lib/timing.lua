local function time(multiplier)
    timing = {}
    timing.three = 3 * (multiplier or 1)
    timing.five = 5 * (multiplier or 1)
    timing.seven = 7 * (multiplier or 1)
    timing.fifteen = 15 * (multiplier or 1)
    timing.twenty = 20 * (multiplier or 1)
    timing.thirty = 30 * (multiplier or 1)
end

return time