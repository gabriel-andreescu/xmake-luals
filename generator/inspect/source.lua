local cache = {}

-- Returns the lines of a source file, or nil when it doesn't exist.
function lines(file)
    if cache[file] == nil then
        cache[file] = os.isfile(file) and io.readfile(file):split("\n", { strict = true }) or false
    end
    return cache[file] or nil
end
