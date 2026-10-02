# xmake-luals

Declarations and a plugin for the
[Lua language server](https://github.com/LuaLS/lua-language-server) (LuaLS) in
XMake projects, generated from the
[XMake build](https://github.com/gabriel-andreescu/xmake) pinned as
`XMAKE_COMMIT` in the [CI workflow](.github/workflows/ci.yml).

## Setup

Add the addon to the project's `xmake.lua`:

```lua
add_repositories("xmake-luals https://github.com/gabriel-andreescu/xmake-luals.git")
add_addons("xmake-luals 0.1.0")
includes("@addon/xmake-luals/luals")
```

`xmake f` installs the declarations and plugin into `.xmake/luals`. Point the
project's `.luarc.json` at them:

```json
{
  "runtime.version": "Lua 5.5",
  "runtime.special": { "import": "require" },
  "runtime.plugin": ".xmake/luals/plugin.lua",
  "workspace.library": [".xmake/luals/library"]
}
```

LuaLS asks whether to trust the plugin the first time it loads it.

## Plugin

The plugin handles `xmake.lua` files and the directories listed in
`runtime.pluginArgs`, relative to the workspace root. Use `"."` for every Lua
file. Other Lua files keep plain Lua diagnostics.

In those files, the plugin:

- Declares the variable a bare `import("core.project.config")` statement
  defines.
- Types the parameters of hook scripts such as `on_build` from their scope and
  hook name.
- Accepts top-level functions as module exports.

## Development

See [contribution guidelines](CONTRIBUTING.md).

## License

[Apache-2.0](LICENSE). See [NOTICE](NOTICE) for XMake attribution.
