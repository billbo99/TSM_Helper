local lib = {}

---@param str string
---@param args table
---@return string
lib.parse_string = function(str, args)
    local count = 1
    for _, arg in pairs(args) do
        local var = '@' .. count
        local s, e = string.find(str, var)
        while s ~= nil and e ~= nil do
            if arg == '**SKIP**' then
                str = string.gsub(str, " " .. var, "")
            else
                str = string.gsub(str, var, arg)
            end
            s, e = string.find(str, var)
        end
        count = count + 1
    end
    return str
end

---Find a name in flib's locales dictonary
---@param item_name string
---@param item_type string
---@return string|nil
lib.find_name_in_flib_dictonary = function(item_name, item_type)
    for _, _dict in pairs(global.player_dictionaries) do
        if _dict[item_type] and _dict[item_type][item_name] then
            return _dict[item_type][item_name]
        end
    end
    return nil
end

---Return richtext icon of a signal
---@param signal_data SignalID
---@return string
lib.parse_signal_to_rich_text = function(signal_data)
    local text_type = signal_data.type
    if text_type == "virtual" then
        text_type = "virtual-signal"
    end

    return string.format("[img=%s/%s]", text_type, signal_data.name)
end

---Check table for element
---@param t table
---@param element any
---@return boolean
lib.contains = function(t, element)
    for _, value in pairs(t) do
        if value == element then
            return true
        end
    end
    return false
end

---Check strings ends with phrase
---@param str string
---@param ending string
---@return boolean
lib.ends_with = function(str, ending)
    return ending == "" or str:sub(-(#ending)) == ending
end

---Check strings starts with phrase
---@param str string
---@param start string
---@return boolean
lib.starts_with = function(str, start)
    return str:sub(1, #start) == start
end

---Split strings
---@param s string
---@param regex string|nil
---@return table
lib.splitString = function(s, regex)
    local chunks = {}
    local count = 0
    if regex == nil then
        regex = "%S+"
    end

    for substring in s:gmatch(regex) do
        count = count + 1
        chunks[count] = substring
    end
    return chunks
end

---Lookup a player by name
---@param playerName string
---@return LuaPlayer|nil
lib.getPlayerByName = function(playerName)
    for _, player in pairs(game.players) do
        if (player.name == playerName) then
            return player
        end
    end
end

---checks if a player is an admin
---@param player LuaPlayer
---@return boolean
lib.isAdmin = function(player)
    if (player.admin) then
        return true
    else
        return false
    end
end

---checks if a table is empty
---@param t table
---@return boolean
lib.is_empty = function(t)
    for _, _ in pairs(t) do
        return false
    end
    return true
end

return lib
