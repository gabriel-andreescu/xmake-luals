import("inspect.source", { alias = "sources", rootdir = path.join(os.scriptdir(), "..") })

-- Returns the comment block directly above a line, without tag lines such as "@param".
function above(file, line)
    local source = file and sources.lines(file)
    if not source then
        return nil
    end
    local block = {}
    for index = line - 1, 1, -1 do
        local text = source[index]:match("^%s*%-%-%s?(.-)%s*$")
        if text == nil or text:startswith("!") or text:startswith("-") then
            break
        end
        table.insert(block, 1, text)
    end
    local result = {}
    for _, text in ipairs(block) do
        if text:startswith("@") then
            break
        end
        table.insert(result, text)
    end
    while #result > 0 and result[#result] == "" do
        table.remove(result)
    end
    while #result > 0 and result[1] == "" do
        table.remove(result, 1)
    end
    return #result > 0 and result or nil
end
