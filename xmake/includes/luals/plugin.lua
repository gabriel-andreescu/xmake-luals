-- LuaLS plugin for xmake scripts.
--
-- Applies to every xmake.lua and to Lua files under the workspace-relative directories listed in
-- `runtime.pluginArgs`, so other Lua in the workspace keeps plain Lua semantics.

local _, workspace_uri, args = ...

local directories = {}
for _, directory in ipairs(workspace_uri and type(args) == "table" and args or {}) do
    local relative = directory:gsub("\\", "/"):gsub("^%.$", ""):gsub("^%./", ""):gsub("/$", "")
    table.insert(directories, workspace_uri .. "/" .. (relative == "" and "" or relative .. "/"))
end

local function is_xmake_script(uri)
    if uri:match("/xmake%.lua$") then
        return true
    end
    for _, prefix in ipairs(directories) do
        if uri:sub(1, #prefix) == prefix then
            return true
        end
    end
    return false
end

local function imported_name(call)
    local alias = call:match("alias%s*=%s*[\"']([%a_][%w_]*)[\"']")
    if alias then
        return alias
    end
    local module = call:match("^import%s*%(%s*[\"']([^\"']+)[\"']")
    return module and module:match("([%a_][%w_]*)$")
end

-- A bare `import("core.project.config")` defines `config` in the importing module. Declaring it as
-- `local config = import(...)` makes the name defined, and typed when `runtime.special` maps `import` to `require`.
local function declare_import(diffs, line, position)
    local indent, call, rest = line:match("^(%s*)(import%s*%b())(.*)$")
    if call and (rest:match("^%s*$") or rest:match("^%s*%-%-")) then
        local name = imported_name(call)
        if name then
            local start = position + #indent
            table.insert(diffs, { start = start, finish = start - 1, text = "local " .. name .. " = " })
        end
    end
end

-- The object each scope's hook scripts receive first. Rule scripts run for the targets that use the rule.
local hook_objects = {
    option = "xmake.option",
    package = "xmake.package",
    rule = "xmake.target",
    target = "xmake.target",
    toolchain = "xmake.toolchain",
}

-- Parameter types of a hook script, by the naming xmake uses for build stages such as `on_buildcmd_file`.
local function hook_params(scope, hook)
    local object = hook_objects[scope]
    if not object then
        return nil
    elseif scope ~= "target" and scope ~= "rule" then
        return { object }
    end
    local stage = hook:gsub("^%a+_", "")
    if stage:match("cmd_files$") then
        return { object, "xmake.batchcmds", "table", "table" }
    elseif stage:match("cmd_file$") then
        return { object, "xmake.batchcmds", "string", "table" }
    elseif stage:match("cmd$") then
        return { object, "xmake.batchcmds", "table" }
    elseif stage:match("_files$") then
        return { object, "table", "table" }
    elseif stage:match("_file$") then
        return { object, "string", "table" }
    end
    return { object, "table" }
end

local function scope_change(line, scope)
    local name = line:match("^%s*([%a_][%w_]*)%s*%(")
    if name and hook_objects[name] or name == "task" or name == "addon" then
        return name
    elseif name and name:match("_end$") then
        return nil
    end
    return scope
end

-- Types the parameters of `on_build(function (target) ... end)` and similar hook scripts in description scope.
local function type_hook_script(diffs, line, position, scope)
    local hook, first = line:match("^%s*((%a+)_[%w_]+)%s*%(")
    if not hook or (first ~= "on" and first ~= "before" and first ~= "after") then
        return
    end
    local start, params = line:match("()function%s*%(([^)]*)%)")
    local types = start and hook_params(scope, hook)
    if not types then
        return
    end
    local docs = {}
    local index = 0
    for name in params:gmatch("[%a_][%w_]*") do
        index = index + 1
        if types[index] then
            table.insert(docs, "---@param " .. name .. " " .. types[index])
        end
    end
    if #docs > 0 then
        local at = position + start - 1
        table.insert(diffs, { start = at, finish = at - 1, text = "\n" .. table.concat(docs, "\n") .. "\n" })
    end
end

-- Top-level functions in xmake scripts are module exports, not accidental globals.
local function allow_export(diffs, line, position)
    if line:match("^function%s+[%a_][%w_]*%s*%(") then
        table.insert(diffs, {
            start = position,
            finish = position - 1,
            text = "---@diagnostic disable-next-line: lowercase-global\n",
        })
    end
end

---@param uri string
---@param text string
---@return { start: integer, finish: integer, text: string }[]?
function OnSetText(uri, text)
    if not is_xmake_script(uri) then
        return nil
    end
    local diffs = {}
    local position = 1
    local scope = nil
    for line in text:gmatch("([^\n]*)\n?") do
        scope = scope_change(line, scope)
        declare_import(diffs, line, position)
        allow_export(diffs, line, position)
        type_hook_script(diffs, line, position, scope)
        position = position + #line + 1
        if position > #text then
            break
        end
    end
    return #diffs > 0 and diffs or nil
end
