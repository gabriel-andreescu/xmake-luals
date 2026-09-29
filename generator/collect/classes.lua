import("core.project.target")
import("core.project.option")
import("core.project.rule")
import("core.package.package")
import("core.tool.toolchain")
import("inspect.function", { alias = "fn", rootdir = path.join(os.scriptdir(), "..") })
import("inspect.comment", { rootdir = path.join(os.scriptdir(), "..") })

-- The objects script-scope callbacks receive. Script instances are created the way `xmake show -l apis` lists their
-- methods, and rule command scripts receive batchcmds.
local instances = {
    target = function()
        return target.new()
    end,
    option = function()
        return option.new()
    end,
    rule = function()
        return rule.new()
    end,
    package = function()
        return package.new()
    end,
    toolchain = function()
        return toolchain.load("clang")
    end,
    batchcmds = function()
        return import("private.utils.batchcmds", { anonymous = true }).new()
    end,
}

local function methods(instance)
    local result = {}
    for name, value in pairs(instance) do
        if type(name) == "string" and not name:startswith("_") and type(value) == "function" then
            local signature = fn.without_first(fn.describe(value))
            result[name] = { name = name, signature = signature, doc = comment.above(signature.file, signature.line) }
        end
    end
    return result
end

-- Returns the instance classes keyed by kind, each with its methods keyed by name.
function collect()
    local classes = {}
    for kind, create in pairs(instances) do
        classes[kind] = { name = kind, methods = methods(create()) }
    end
    return classes
end
