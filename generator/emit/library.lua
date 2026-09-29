import("emit.luacats", { rootdir = path.join(os.scriptdir(), "..") })

local function sorted_values(map)
    local values = table.values(map)
    table.sort(values, function(left, right)
        return left.name < right.name
    end)
    return values
end

-- Binary mode keeps LF line endings on Windows, where text mode writes CRLF.
local function write_file(outputdir, relative, name, blocks)
    local file = path.join(outputdir, relative)
    os.mkdir(path.directory(file))
    local handle = io.open(file, "wb")
    handle:write(luacats.header(name) .. "\n\n" .. table.concat(blocks, "\n\n") .. "\n")
    handle:close()
end

local function scope_list(entry)
    local scopes = table.keys(entry.scopes)
    table.sort(scopes)
    return table.concat(scopes, ", ")
end

local function description_block(entry)
    if entry.kinds.scope then
        local doc = {
            "Starts a `"
                .. entry.name
                .. "` scope. Its functions configure it until another scope starts or `"
                .. entry.name
                .. "_end()` closes it.",
        }
        return luacats.stub(entry.name, { params = { "name", "opt" }, vararg = false }, doc)
    elseif entry.kinds.scope_end then
        local doc = { "Ends the current `" .. entry.name:gsub("_end$", "") .. "` scope." }
        return luacats.stub(entry.name, { params = {}, vararg = false }, doc)
    end
    local doc = table.join(entry.doc or {}, entry.doc and { "" } or {}, { "Scopes: " .. scope_list(entry) .. "." })
    return luacats.stub(entry.name, entry.signature or { params = {}, vararg = true, returns = false }, doc)
end

local function write_description(outputdir, description, globals)
    local blocks = {}
    for _, entry in ipairs(sorted_values(description.functions)) do
        if not globals.functions[entry.name] then
            table.insert(blocks, description_block(entry))
        end
    end
    write_file(outputdir, "xmake/description.lua", "xmake.description", blocks)
end

local function write_globals(outputdir, globals, stdlib)
    local blocks = {}
    for _, entry in ipairs(sorted_values(globals.functions)) do
        table.insert(blocks, luacats.stub(entry.name, entry.signature, entry.doc))
    end
    local tables = table.keys(globals.tables)
    table.sort(tables)
    for _, name in ipairs(tables) do
        if not stdlib.is_library(name) then
            table.insert(blocks, "---@class xmake." .. name .. "\n" .. name .. " = {}")
        end
        for _, entry in ipairs(sorted_values(globals.tables[name])) do
            table.insert(blocks, luacats.stub(name .. "." .. entry.name, entry.signature, entry.doc))
        end
    end
    write_file(outputdir, "xmake/globals.lua", "xmake.globals", blocks)
end

local function write_classes(outputdir, classes)
    local blocks = {}
    for _, class in ipairs(sorted_values(classes)) do
        table.insert(blocks, "---@class xmake." .. class.name .. "\nlocal " .. class.name .. " = {}")
        for _, method in ipairs(sorted_values(class.methods)) do
            table.insert(blocks, luacats.stub(class.name .. ":" .. method.name, method.signature, method.doc))
        end
    end
    write_file(outputdir, "xmake/classes.lua", "xmake.classes", blocks)
end

local function write_module(outputdir, module)
    local relative = module.name:gsub("%.", "/") .. ".lua"
    local short = luacats.identifier(module.name:match("([^%.]+)$"))
    local blocks = {}
    if module.call then
        table.insert(blocks, luacats.stub(short, module.call.signature, module.call.doc, "local function"))
    else
        table.insert(blocks, "---@class xmake.module." .. module.name .. "\nlocal " .. short .. " = {}")
        for _, entry in ipairs(sorted_values(module.functions)) do
            table.insert(blocks, luacats.stub(short .. "." .. entry.name, entry.signature, entry.doc))
        end
    end
    table.insert(blocks, "return " .. short)
    write_file(outputdir, relative, module.name, blocks)
end

-- Replaces the library directory with declarations for the collected model.
function write(model, outputdir, stdlib)
    os.tryrm(outputdir)
    write_description(outputdir, model.description, model.globals)
    write_globals(outputdir, model.globals, stdlib)
    write_classes(outputdir, model.classes)
    for _, module in pairs(model.modules) do
        write_module(outputdir, module)
    end
end
