set_project("fixture")
set_xmakever("3.1.1")
add_rules("mode.debug", "mode.release")
includes("@builtin/check")

option("feature")
set_default(false)
set_showmenu(true)
on_check(function(option)
    option:enable(option:dep("other") ~= nil)
    option:enabel(true) --! undefined-field
end)
option_end()

rule("stage")
set_extensions(".txt")
on_buildcmd_file(function(target, batchcmds, sourcefile, opt)
    batchcmds:show_progress(opt.progress, "${color.build.object}staging %s", sourcefile)
    batchcmds:show_progres(opt.progress, "staging %s", sourcefile) --! undefined-field
    target:add("files", sourcefile)
end)
rule_end()

target("fixture")
set_kind("binary")
add_files("main.cpp")
add_file("main.cpp") --! undefined-global
on_build(function(target)
    print(target:targetfile())
    print(target:targetfle()) --! undefined-field
end)

package("dependency")
add_urls("https://example.com/dependency.git")
on_install(function(package)
    os.cp(package:installdir(), "out")
    os.cp(package:instaldir(), "out") --! undefined-field
end)
