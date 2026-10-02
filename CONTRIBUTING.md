# Contributing

## Repository layout

| Path                    | Responsibility                                                         |
| ----------------------- | ---------------------------------------------------------------------- |
| `generator/`            | Reads XMake's APIs at runtime, writes the library.                     |
| `xmake/includes/luals/` | The addon's include: generated `library/`, `plugin.lua` and installer. |
| `addons/`               | Addon distribution recipe.                                             |
| `tests/`                | Diagnostics tests and fixture projects.                                |

## Development

Requires [uv](https://docs.astral.sh/uv/), the
[XMake build](https://github.com/gabriel-andreescu/xmake) pinned as
`XMAKE_COMMIT` in the [CI workflow](.github/workflows/ci.yml) and the
[Lua language server](https://github.com/LuaLS/lua-language-server). From the
repository root:

```powershell
uv sync --locked
uv run pre-commit install
```

## Regenerate the library

Don't edit `xmake/includes/luals/library/`. Change the generator, then run it
with that XMake build:

```powershell
xmake lua generator/main.lua
```

CI fails when the committed library differs from the generated one.

## Tests

Set `LUALS` to the `lua-language-server` executable, or add it to `PATH`, then
run:

```powershell
uv run pytest
```

Each directory under `tests/fixtures/` is a project checked with the library and
plugin. End a line with `--! <code>` when it must report that diagnostic. Other
lines must report none.

## Validate addon changes

Install the local checkout as a consumer's addon with XMake's `--debugdir`
option in an isolated global directory, and register it as the consumer's
repository:

```powershell
$env:XMAKE_GLOBALDIR = Join-Path $PWD ".xmake/development"
xmake repo --add --global xmake-luals C:/path/to/xmake-luals
xrepo install --addon -y --debugdir=C:/path/to/xmake-luals "xmake-luals X.Y.Z"
xmake repo --add xmake-luals C:/path/to/xmake-luals
xmake f -y
```

Check that `.xmake/luals` holds the new library and plugin.

## Releases

Unreleased work lands on `dev`. `main` tracks the latest release.

For a release, add the version to `addons/x/xmake-luals/xmake.lua`, update the
`add_addons` version in the README and date the changelog entry. Merge `dev`
into `main` through a pull request without squashing, then publish a matching
`vX.Y.Z` tag on `main`. Do not move published release tags.
