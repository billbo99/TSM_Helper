local Func = {}

function Func.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

function Func.ends_with(str, ending)
    return ending == "" or str:sub(-(#ending)) == ending
end

function Func.starts_with(str, start)
    return str:sub(1, #start) == start
end

function Func.splitString(s, regex)
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

function Func.getPlayerByName(playerName)
    for _, player in pairs(game.players) do
        if (player.name == playerName) then
            return player
        end
    end
end

function Func.isAdmin(player)
    if (player.admin) then
        return true
    else
        return false
    end
end

function Func.is_empty(t)
    for _, _ in pairs(t) do
        return false
    end
    return true
end

return Func
