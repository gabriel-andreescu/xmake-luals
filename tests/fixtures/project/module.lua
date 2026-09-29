import("core.project.config")
import("core.project.depend")
import("lib.detect.find_tool")
import("core.base.option", { alias = "options" })

function main()
    os.cpp("a", "b") --! undefined-field
    config.missing() --! undefined-field
    confg.get("arch") --! undefined-global
    local tool = find_tool("git")
    local verbose = options.get("verbose")
    local files = os.files(path.join(config.builddir(), "**.o"))
    depend.on_changed(function()
        for _, file in ipairs(files) do
            io.writefile(file .. ".d", ("%s"):format(tool and tool.program or ""):trim())
        end
    end, { files = table.join(files, { "extra.o" }) })
    return verbose, path.jion("a", "b") --! undefined-field
end

function helper()
    counter = 1 --! lowercase-global
end
