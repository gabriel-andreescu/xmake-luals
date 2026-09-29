-- Lua 5.4 standard library names. LuaLS already declares these, and redeclaring them would replace its types.
local names = {
    _G = {
        "assert",
        "collectgarbage",
        "dofile",
        "error",
        "getmetatable",
        "ipairs",
        "load",
        "loadfile",
        "next",
        "pairs",
        "pcall",
        "print",
        "rawequal",
        "rawget",
        "rawlen",
        "rawset",
        "require",
        "select",
        "setmetatable",
        "tonumber",
        "tostring",
        "type",
        "unpack",
        "xpcall",
    },
    coroutine = { "close", "create", "isyieldable", "resume", "running", "status", "wrap", "yield" },
    debug = {
        "debug",
        "gethook",
        "getinfo",
        "getlocal",
        "getmetatable",
        "getregistry",
        "getupvalue",
        "getuservalue",
        "sethook",
        "setlocal",
        "setmetatable",
        "setupvalue",
        "setuservalue",
        "traceback",
        "upvalueid",
        "upvaluejoin",
    },
    io = { "close", "flush", "input", "lines", "open", "output", "popen", "read", "tmpfile", "type", "write" },
    math = {
        "abs",
        "acos",
        "asin",
        "atan",
        "ceil",
        "cos",
        "deg",
        "exp",
        "floor",
        "fmod",
        "log",
        "max",
        "min",
        "modf",
        "rad",
        "random",
        "randomseed",
        "sin",
        "sqrt",
        "tan",
        "tointeger",
        "type",
        "ult",
    },
    os = {
        "clock",
        "date",
        "difftime",
        "execute",
        "exit",
        "getenv",
        "remove",
        "rename",
        "setlocale",
        "time",
        "tmpname",
    },
    string = {
        "byte",
        "char",
        "dump",
        "find",
        "format",
        "gmatch",
        "gsub",
        "len",
        "lower",
        "match",
        "pack",
        "packsize",
        "rep",
        "reverse",
        "sub",
        "unpack",
        "upper",
    },
    table = { "concat", "insert", "move", "pack", "remove", "sort", "unpack" },
    utf8 = { "char", "codes", "codepoint", "len", "offset" },
}

local sets = {}
for library, functions in pairs(names) do
    sets[library] = {}
    for _, name in ipairs(functions) do
        sets[library][name] = true
    end
end

-- True when LuaLS declares the table itself.
function is_library(name)
    return name ~= "_G" and sets[name] ~= nil
end

-- True when LuaLS declares the function, given its table ("_G" for globals).
function declares(library, name)
    return sets[library] ~= nil and sets[library][name] ~= nil
end
