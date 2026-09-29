import("inspect.function", { alias = "fn", rootdir = path.join(os.scriptdir(), "..") })
import("inspect.comment", { rootdir = path.join(os.scriptdir(), "..") })

-- Module directories shipped with xmake. Private, tool-detection and xmake.lua files are internal.
local function directories()
    return {
        path.join(os.programdir(), "core", "sandbox", "modules", "import"),
        path.join(os.programdir(), "modules"),
    }
end

local excluded = "**.lua|**/xmake.lua|private/**.lua|core/tools/**.lua|detect/tools/**.lua"

local function entry(name, value)
    local signature = fn.describe(value)
    return { name = name, signature = signature, doc = comment.above(signature.file, signature.line) }
end

local function module_name(directory, file)
    local name = path.relative(file, directory)
    if path.filename(name) == "main.lua" then
        name = path.directory(name)
    end
    return (name:gsub("[\\/]", "."):gsub("%.lua$", ""))
end

local function describe_module(name, instance)
    local meta = debug.getmetatable(instance)
    if type(instance.main) == "function" and meta and meta.__call then
        return { name = name, call = entry(name, instance.main) }
    end
    local functions = {}
    for member, value in pairs(instance) do
        if type(member) == "string" and not member:startswith("_") and type(value) == "function" then
            functions[member] = entry(member, value)
        end
    end
    return { name = name, functions = functions }
end

-- Returns the importable modules keyed by name, as callables or tables of functions.
function collect()
    local modules = {}
    for _, directory in ipairs(directories()) do
        for _, file in ipairs(os.files(path.join(directory, excluded))) do
            local name = module_name(directory, file)
            if not modules[name] and not (not xmake.luajit() and name:find("luajit%.")) then
                local instance = import(name, { try = true, anonymous = true })
                if type(instance) == "table" then
                    modules[name] = describe_module(name, instance)
                end
            end
        end
    end
    return modules
end
