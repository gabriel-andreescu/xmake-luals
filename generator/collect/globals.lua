import("core.base.interpreter")
import("core.sandbox.sandbox")
import("inspect.function", { alias = "fn", rootdir = path.join(os.scriptdir(), "..") })
import("inspect.comment", { rootdir = path.join(os.scriptdir(), "..") })
import("collect.stdlib", { rootdir = path.join(os.scriptdir(), "..") })

local function entry(name, value)
    local signature = fn.describe(value)
    return { name = name, signature = signature, doc = comment.above(signature.file, signature.line) }
end

-- The sandbox's pairs() never returns on the builtin module tables, so iterate them in key order.
local function merge(functions, tables, builtins)
    for name, value in table.orderpairs(builtins) do
        if type(value) == "function" then
            if not stdlib.declares("_G", name) and not functions[name] then
                functions[name] = entry(name, value)
            end
        elseif type(value) == "table" then
            local members = tables[name] or {}
            tables[name] = members
            for member, member_value in table.orderpairs(value) do
                if
                    type(member) == "string"
                    and not member:startswith("_")
                    and type(member_value) == "function"
                    and not stdlib.declares(name, member)
                    and not members[member]
                then
                    members[member] = entry(member, member_value)
                end
            end
        end
    end
end

-- Returns the global functions and module tables of script scope, merged with description scope.
function collect()
    local functions, tables = {}, {}
    merge(functions, tables, sandbox.builtin_modules())
    merge(functions, tables, interpreter.builtin_modules())
    return { functions = functions, tables = tables }
end
