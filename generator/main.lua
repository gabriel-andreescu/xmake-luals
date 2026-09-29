-- Generates the LuaLS library from the running xmake: xmake lua generator/main.lua [outputdir]
function main(outputdir)
    local rootdir = os.scriptdir()
    local model = {
        description = import("collect.description", { rootdir = rootdir }).collect(),
        globals = import("collect.globals", { rootdir = rootdir }).collect(),
        classes = import("collect.classes", { rootdir = rootdir }).collect(),
        modules = import("collect.modules", { rootdir = rootdir }).collect(),
    }
    for _, modulename in ipairs(model.description.missing) do
        print("warning: found no apis() for %s", modulename)
    end
    outputdir = path.absolute(outputdir or path.join(rootdir, "..", "xmake", "includes", "luals", "library"))
    import("emit.library", { rootdir = rootdir }).write(
        model,
        outputdir,
        import("collect.stdlib", { rootdir = rootdir })
    )
    print("wrote %s", outputdir)
end
