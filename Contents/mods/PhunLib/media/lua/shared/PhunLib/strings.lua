-- PhunLib/tools.lua (helper utilities)
local luautils = luautils
local tools = {}

-- ------------------------------------------------------------
-- numbers
-- ------------------------------------------------------------

function tools.formatWholeNumber(n)
    n = tonumber(n) or 0
    -- Round half-up (works for positives; good enough for UI values)
    local rounded = math.floor(n + 0.5)

    local s = tostring(rounded)
    local sign = ""

    if s:sub(1, 1) == "-" then
        sign = "-"
        s = s:sub(2)
    end

    -- Insert commas
    local rev = s:reverse()
    rev = rev:gsub("(%d%d%d)", "%1,")
    s = rev:reverse():gsub("^,", "")

    return sign .. s
end

-- ------------------------------------------------------------
-- time helpers
-- ------------------------------------------------------------

-- Define time intervals in seconds
local SECONDS_IN_MINUTE = 60
local SECONDS_IN_HOUR = 60 * 60
local SECONDS_IN_DAY = 24 * 60 * 60
local SECONDS_IN_MONTH = 30 * SECONDS_IN_DAY -- approximate
local SECONDS_IN_YEAR = 365 * SECONDS_IN_DAY -- approximate

-- serverside translations
local serverText = {}
if isServer() then
    -- there aren't server translation files, so if we are a server, use these
    serverText["UI_PhunLib_Hour"] = "Hour"
    serverText["UI_PhunLib_HoursAgo"] = "%1 Hours ago"
    serverText["UI_PhunLib_Hours"] = "Hours"
    serverText["UI_PhunLib_Day"] = "Day"
    serverText["UI_PhunLib_Days"] = "Days"
    serverText["UI_PhunLib_DaysAgo"] = "%1 Days"
    serverText["UI_PhunLib_Minutes"] = "Minutes"
    serverText["UI_PhunLib_Minute"] = "Minute"

    serverText["UI_PhunLib_JustNow"] = "Just now"
    serverText["UI_PhunLib_X_ago"] = "%1 ago"

    serverText["UI_PhunLib_X_Second"] = "%1 second"
    serverText["UI_PhunLib_X_Seconds"] = "%1 seconds"
    serverText["UI_PhunLib_X_Minute"] = "%1 minute"
    serverText["UI_PhunLib_X_Minutes"] = "%1 minutes"
    serverText["UI_PhunLib_X_Hour"] = "%1 hour"
    serverText["UI_PhunLib_X_Hours"] = "%1 hours"
    serverText["UI_PhunLib_X_Day"] = "day"
    serverText["UI_PhunLib_X_Days"] = "days"
    serverText["UI_PhunLib_X_Month"] = "%1 month"
    serverText["UI_PhunLib_X_Months"] = "%1 months"
    serverText["UI_PhunLib_X_Year"] = "%1 year"
    serverText["UI_PhunLib_X_Years"] = "%1 years"
    serverText["UI_PhunLib_DaysAndHours"] = "%1 %2, %3 %4"
    serverText["UI_PhunLib_LessThanHour"] = "Less than an hour"
    serverText["UI_PhunLib_LessThanMinute"] = "Less than a minute"
end

-- Prefer a plural key when value ~= 1
local function tSingPlural(baseKey, pluralKey, value)
    if value == 1 then
        return getText(serverText[baseKey] or baseKey, value)
    end
    return getText(serverText[pluralKey] or pluralKey, value)
end

-- Convert a seconds duration into components (largest -> smallest).
-- Returns years, months, days, hours, minutes, seconds (all >= 0).
function tools.secondsToComponents(totalSeconds)
    local diff = math.floor(tonumber(totalSeconds) or 0)
    if diff <= 0 then
        return 0, 0, 0, 0, 0, 0
    end

    local years = math.floor(diff / SECONDS_IN_YEAR)
    diff = diff % SECONDS_IN_YEAR

    local months = math.floor(diff / SECONDS_IN_MONTH)
    diff = diff % SECONDS_IN_MONTH

    local days = math.floor(diff / SECONDS_IN_DAY)
    diff = diff % SECONDS_IN_DAY

    local hours = math.floor(diff / SECONDS_IN_HOUR)
    diff = diff % SECONDS_IN_HOUR

    local minutes = math.floor(diff / SECONDS_IN_MINUTE)
    local seconds = diff % SECONDS_IN_MINUTE

    return years, months, days, hours, minutes, seconds
end

--  - diff is clamped to 0 if time1 <= time2 (no negative “ago”)
--  - returns components of (time1 - time2) if time1 is in the future
function tools.timeDifference(time1, time2)
    time2 = tonumber(time2) or os.time()
    time1 = tonumber(time1) or 0

    local diff = time1 - time2
    if diff <= 0 then
        return 0, 0, 0, 0, 0, 0
    end

    return tools.secondsToComponents(diff)
end

-- return the textual difference bewtween two timestamps
function tools.absDifference(time1, time2, opts)
    time2 = tonumber(time2) or os.time()
    time1 = tonumber(time1) or 0

    local diff = time1 - time2
    if diff <= 0 then
        diff = time2 - time1
    end

    return tools.secondsToText(diff, opts)
end

-- Build a translated duration string from components.
-- opts:
--   maxParts (number) default 1 for compact UI (e.g. "3 days"), set 2+ for "3 days 4 hours"
--   includeSeconds (bool) default false (include seconds only when no larger units, unless true)
--   zeroText (string) default getText("UI_PhunLib_JustNow")
function tools.secondsToText(totalSeconds, opts)
    opts = opts or {}
    local maxParts = tonumber(opts.maxParts) or 1
    if maxParts < 1 then
        maxParts = 1
    end

    local includeSeconds = opts.includeSeconds == true
    local zeroText = opts.zeroText or getText(serverText["UI_PhunLib_JustNow"] or "UI_PhunLib_JustNow")

    local years, months, days, hours, minutes, seconds = tools.secondsToComponents(totalSeconds)

    if (years + months + days + hours + minutes + seconds) == 0 then
        return zeroText
    end

    local parts = {}

    local function addPart(value, singularKey, pluralKey)
        if value > 0 and #parts < maxParts then
            table.insert(parts, tSingPlural(singularKey, pluralKey, value))
        end
    end

    addPart(years, "UI_PhunLib_X_Year", "UI_PhunLib_X_Years")
    addPart(months, "UI_PhunLib_X_Month", "UI_PhunLib_X_Months")
    addPart(days, "UI_PhunLib_X_Day", "UI_PhunLib_X_Days")
    addPart(hours, "UI_PhunLib_X_Hour", "UI_PhunLib_X_Hours")
    addPart(minutes, "UI_PhunLib_X_Minute", "UI_PhunLib_X_Minutes")
    -- Only include seconds if:
    --  - caller wants it, OR
    --  - we have no larger units yet (so "12 seconds" is possible)
    if #parts < maxParts and seconds > 0 and (includeSeconds or #parts == 0) then
        addPart(seconds, "UI_PhunLib_X_Second", "UI_PhunLib_X_Seconds")
    end

    -- If we still have nothing (e.g. 0m 0s but diff >0 shouldn't happen), fallback
    if #parts == 0 then
        return zeroText
    end

    return table.concat(parts, " ")
end

-- “time ago” for timestamps (expects time1 >= time2 to show something)
-- Produces: "X ago" or defaultText / "Just now"
function tools.timeAgo(time1, time2, defaultText)
    time2 = tonumber(time2) or os.time()
    time1 = tonumber(time1) or 0

    local diff = time1 - time2
    if diff <= 0 then
        return defaultText or getText(serverText["UI_PhunLib_JustNow"] or "UI_PhunLib_JustNow")
    end

    -- For “ago”, you probably want the compact form most of the time:
    -- e.g. "3 minutes ago" not "3 minutes 12 seconds ago"
    local durationText = tools.secondsToText(diff, {
        maxParts = 1,
        includeSeconds = false
    })
    return getText(serverText["UI_PhunLib_X_ago"] or "UI_PhunLib_X_ago", durationText)
end

return tools
