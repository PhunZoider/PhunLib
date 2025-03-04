local luautils = luautils
local loadstring = loadstring
local tools = {}

--- transforms and returns an array of strings into a table
--- @param tableOfStrings table<string>
--- @return table
function tools.tableOfStringsToTable(tableOfStrings)
    -- Error handling for invalid input
    if not tableOfStrings or type(tableOfStrings) ~= "table" or #tableOfStrings == 0 then
        return nil, " - Invalid input: file contents are not a valid table"
    end

    local concatenatedString
    local startsWithReturn = string.sub(tableOfStrings[1], 1, string.len("return")) == "return"
    if startsWithReturn then
        -- Input already includes "return", concatenate as is
        concatenatedString = table.concat(tableOfStrings, "\n")
    else
        -- Wrap the input in a "return" statement
        concatenatedString = "return {\n" .. table.concat(tableOfStrings, "\n") .. "\n}"
    end

    -- Safely execute the concatenated string
    local status, loadstringResult = pcall(loadstring, concatenatedString)
    if not status then
        return nil, " - Error in loadstring: " .. loadstringResult
    end

    local res
    status, res = pcall(loadstringResult)
    if not status then
        return nil, " - Error executing loadstring result: " .. res
    end

    return res, nil
end

--- loads a table from a file
--- @param filename string path to the file contained in Lua folder of server
--- @return table
function tools.loadTable(filename, createIfNotExists)
    local res
    local data = {}
    local fileReaderObj = getFileReader(filename, createIfNotExists == true)
    if not fileReaderObj then
        return nil
    end
    local line = fileReaderObj:readLine()
    local startsWithReturn = nil
    while line do
        if startsWithReturn == nil then
            startsWithReturn = luautils.stringStarts(line, "return")
        end
        data[#data + 1] = line
        line = fileReaderObj:readLine()
    end
    fileReaderObj:close()

    local result, err = tools.tableOfStringsToTable(data)

    if err then
        print("Error loading file " .. filename .. ": " .. err)
    else
        return result
    end

end

--- saves a table to a file
--- @param fname string path to the file contained in Lua folder of server
--- @param data table
function tools.saveTable(fname, data)
    if not data then
        return
    end
    local fileWriterObj = getFileWriter(fname, true, false)
    local serialized = tools.tableToString(data)
    fileWriterObj:write("return " .. serialized .. "")
    fileWriterObj:close()
end

--- returns a string representation of a table
--- @param tbl table
--- @param nokeys boolean
--- @param depth number
function tools.tableToString(tbl, indent)
    indent = indent or 0
    local formatted = "{\n"
    local prefix = string.rep("  ", indent + 1) -- Increase indentation

    for key, value in pairs(tbl) do
        -- Format the key properly (handle string and numeric keys)
        local keyStr = key .. " = "
        if type(key) == "string" and string.find(key, " ") then
            keyStr = string.format("[%q]", key) .. " = "
        elseif type(key) == "number" then
            keyStr = ""
        end

        if type(value) == "table" then
            formatted = formatted .. string.format("%s%s%s", prefix, keyStr, tools.tableToString(value, indent + 1))
        elseif type(value) == "string" then
            formatted = formatted .. string.format("%s%s%q,\n", prefix, keyStr, value) -- Add quotes for strings
        else
            formatted = formatted .. string.format("%s%s%s,\n", prefix, keyStr, tostring(value)) -- Handle numbers, booleans, etc.
        end
    end

    if indent > 0 then
        formatted = formatted .. string.rep("  ", indent) .. "},\n"
    else
        formatted = formatted .. "}\n"
    end
    return formatted
end

local logQueue = {}

function tools.log(...)
    tools.logTo("Phun.log", ...)
end

function tools.logTo(filename, ...)
    Events.EveryOneMinute.Remove(tools.doLogs)
    if not logQueue[filename] then
        logQueue[filename] = {}
    end
    local entry = os.date("%Y-%m-%d %H:%M:%S") .. "\t" .. table.concat({...}, "\t")
    table.insert(logQueue[filename], entry)
    Events.EveryOneMinute.Add(tools.doLogs)
end

function tools.doLogs()
    Events.EveryOneMinute.Remove(tools.doLogs)
    for filename, entries in pairs(logQueue) do
        if #entries > 0 then
            tools.appendToFile(filename, entries, true)
            logQueue[filename] = {}
        end
    end
end

function tools.appendToFile(filename, line, createIfNotExist)
    if not line then
        return
    end
    local ls = {}
    if type(line) == "table" then
        ls = line
    else
        ls[1] = line
    end
    local fileWriterObj = getFileWriter(filename, createIfNotExist ~= false, true)
    for _, l in ipairs(ls) do
        if l and l ~= "" then
            fileWriterObj:write(l .. "\r\n")
        end
    end
    fileWriterObj:close()
end

-- if not tools.inied then
--     tools.inied = true
--     -- try to onlu do this once in case file is required elsewhere
--     Events.EveryTenMinutes.Add(function()
--         tools.doLogs()
--     end)
-- end

return tools
