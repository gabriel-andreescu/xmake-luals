import("core.base.interpreter")
import("inspect.function", { alias = "fn", rootdir = path.join(os.scriptdir(), "..") })
import("inspect.comment", { rootdir = path.join(os.scriptdir(), "..") })

-- Modules whose apis() define the functions available in xmake.lua and its scope blocks, with their source files.
local definers = {
    { module = "core.project.project", file = "core/project/project.lua" },
    { module = "core.project.target", file = "core/project/target.lua" },
    { module = "core.project.option", file = "core/project/option.lua" },
    { module = "core.project.rule", file = "core/project/rule.lua" },
    { module = "core.base.task", file = "core/base/task.lua" },
    { module = "core.package.package", file = "core/package/package.lua" },
    { module = "core.package.repository", file = "core/package/repository.lua" },
    { module = "core.package.addon", file = "core/package/addon.lua" },
    { module = "core.language.language", file = "core/language/language.lua" },
    { module = "core.tool.toolchain", file = "core/tool/toolchain.lua" },
}

-- The sandbox doesn't expose every apis(), but those it hides return literal lists of names by kind.
local function apis_from_source(file)
    local lines = io.readfile(path.join(os.programdir(), file)):split("\n", { strict = true })
    local body
    for _, line in ipairs(lines) do
        if body then
            if line == "end" then
                break
            end
            table.insert(body, (line:gsub("%-%-.*$", "")))
        elseif line:match("^function [%w_]+%.apis%(%)") then
            body = {}
        end
    end
    if not body then
        return nil
    end
    local apis = {}
    for kind, block in table.concat(body, "\n"):gmatch("([%w_]+)%s*=%s*(%b{})") do
        apis[kind] = {}
        for name in block:gmatch('"([%w_%.]+)"') do
            table.insert(apis[kind], name)
        end
    end
    return apis
end

local function apis_of(definer)
    local module = import(definer.module, { try = true, anonymous = true })
    if module and module.apis then
        return module.apis()
    end
    return apis_from_source(definer.file)
end

local function split_scope(name)
    local scope, funcname = name:match("^([%w_]+)%.([%w_]+)$")
    if scope then
        return scope, funcname
    end
    return nil, name
end

local function add(functions, scopes, name, kind, signature)
    local scope, funcname = split_scope(name)
    if scope then
        scopes[scope] = true
    end
    local entry = functions[funcname]
    if not entry then
        entry = { name = funcname, kinds = {}, scopes = {} }
        functions[funcname] = entry
    end
    entry.kinds[kind] = true
    entry.scopes[scope or "root"] = true
    entry.signature = entry.signature or signature
end

local function collect_definitions(functions, scopes, missing)
    for _, definer in ipairs(definers) do
        local apis = apis_of(definer)
        if apis then
            for kind, names in pairs(apis) do
                for _, name in ipairs(names) do
                    if type(name) == "table" then
                        add(functions, scopes, name[1], kind, fn.without_first(fn.describe(name[2])))
                    else
                        add(functions, scopes, name, kind)
                    end
                end
            end
        else
            table.insert(missing, definer.module)
        end
    end
end

local function definitions_in(file)
    local result = {}
    for index, text in ipairs(io.readfile(file):split("\n", { strict = true })) do
        local method, list = text:match("^function interpreter[:.]([%w_]+)%((.-)%)")
        if method then
            local signature = { params = {}, vararg = false, file = file, line = index }
            for _, param in ipairs(list:split(",%s*")) do
                if param == "..." then
                    signature.vararg = true
                elseif param ~= "self" then
                    table.insert(signature.params, param)
                end
            end
            result[method] = signature
        end
    end
    return result
end

-- The interpreter registers these on every instance, outside any apis() table.
local function collect_root_builtins(functions)
    local file = path.join(os.programdir(), "core", "base", "interpreter.lua")
    local signatures = definitions_in(file)
    for name, method in io.readfile(file):gmatch('api_register%(nil,%s*"([%w_]+)",%s*interpreter%.([%w_]+)%)') do
        if not name:startswith("interp_") then
            functions[name] = {
                name = name,
                kinds = { builtin = true },
                scopes = { root = true },
                signature = signatures[method],
            }
        end
    end
end

-- Returns the functions available in description scope, keyed by name.
function collect()
    local functions, scopes, missing = {}, {}, {}
    collect_definitions(functions, scopes, missing)
    collect_root_builtins(functions)
    for scope in pairs(scopes) do
        functions[scope] = { name = scope, kinds = { scope = true }, scopes = { root = true } }
        functions[scope .. "_end"] = { name = scope .. "_end", kinds = { scope_end = true }, scopes = { root = true } }
    end
    for _, entry in pairs(functions) do
        if entry.signature and entry.signature.file then
            entry.doc = comment.above(entry.signature.file, entry.signature.line)
        end
    end
    return { functions = functions, scopes = scopes, modules = interpreter.builtin_modules(), missing = missing }
end
