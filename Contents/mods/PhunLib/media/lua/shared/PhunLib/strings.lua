local luautils = luautils
local tools = {}

function tools.formatWholeNumber(number)
    number = number or 0
    -- Round the number to remove the decimal part
    local roundedNumber = math.floor(number + 0.5)
    -- Convert to string and format with commas
    local formattedNumber = tostring(roundedNumber):reverse():gsub("(%d%d%d)", "%1,")
    formattedNumber = formattedNumber:reverse():gsub("^,", "")
    return formattedNumber
end

function tools.timeAgo(time1, time2, defaultText)

    local years, months, days, hours, minutes, seconds = tools.timeDifference(time1, time2)
    local result = {}

    if years > 0 then
        table.insert(result, years == 1 and getText("UI_PhunLib_X_Year", years) or getText("UI_PhunLib_X_Years", years))
    end

    if months > 0 then
        table.insert(result, getText("UI_PhunLib_X_Month", months) or getText("UI_PhunLib_X_Months", months))
    end

    if days > 0 then
        table.insert(result, getText("UI_PhunLib_X_Day", days) or getText("UI_PhunLib_X_Days", days))
    end

    if hours > 0 then
        table.insert(result, getText("UI_PhunLib_X_Hour", hours) or getText("UI_PhunLib_X_Hours", hours))
    end

    if minutes > 0 then
        table.insert(result, getText("UI_PhunLib_X_Minute", minutes) or getText("UI_PhunLib_X_Minutes", minutes))
    end

    if #result > 0 then
        return getText("UI_PhunLib_X_ago", table.concat(result, " "))
    else
        return defaultText or getText("UI_PhunLib_JustNow")
    end

end

-- Define time intervals in seconds
local secondsInMinute = 60
local secondsInHour = 3600
local secondsInDay = 86400
local secondsInMonth = 2592000 -- Approximate (30 days)
local secondsInYear = 31536000 -- Approximate (365 days)

function tools.timeDifference(time1, time2)
    time2 = time2 or os.time()
    local diff = (time1 or 0) - (time2 or 0)

    if diff < 0 then
        return 0, 0, 0, 0, 0, 0
    end
    -- Calculate time components
    local years = math.floor(diff / secondsInYear)
    diff = diff % secondsInYear
    local months = math.floor(diff / secondsInMonth)
    diff = diff % secondsInMonth
    local days = math.floor(diff / secondsInDay)
    diff = diff % secondsInDay
    local hours = math.floor(diff / secondsInHour)
    diff = diff % secondsInHour
    local minutes = math.floor(diff / secondsInMinute)
    local seconds = diff % secondsInMinute

    return years, months, days, hours, minutes, seconds
end

return tools
