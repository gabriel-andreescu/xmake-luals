import("inspect.source", { rootdir = path.join(os.scriptdir(), "..") })

-- Xmake records its own files as "@@programdir/...".
local function source_path(source)
    local file = source:gsub("^@", "")
    return (file:gsub("^@programdir", (os.programdir():gsub("%%", "%%%%"))))
end

-- A function returns values when its body has a `return` with an expression, including nested functions.
local function returns_values(file, first, last)
    local lines = source.lines(file)
    if not lines then
        return true
    end
    for index = first, math.min(last, #lines) do
        local code = lines[index]:gsub("%-%-.*$", "")
        if code:match("%f[%w_]return%f[^%w_]%s*[^%s;]") and not code:match("%f[%w_]return%s+end%f[^%w_]") then
            return true
        end
    end
    return false
end

-- Returns the parameter names, source location and whether it returns values, for a Lua function.
function describe(fn)
    local info = debug.getinfo(fn, "uS")
    local params = {}
    for index = 1, info.nparams do
        table.insert(params, (debug.getlocal(fn, index)))
    end
    local result = { params = params, vararg = info.isvararg, returns = true }
    if info.what == "Lua" and info.linedefined > 0 then
        result.file = source_path(info.source)
        result.line = info.linedefined
        result.returns = returns_values(result.file, info.linedefined, info.lastlinedefined)
    end
    return result
end

-- Drops a leading receiver parameter that callers never pass.
function without_first(signature)
    return {
        params = table.slice(signature.params, 2),
        vararg = signature.vararg,
        returns = signature.returns,
        file = signature.file,
        line = signature.line,
    }
end
