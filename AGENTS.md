# AGENTS.md

xmake-luals generates Lua language server declarations for xmake and ships a
LuaLS plugin for the parts of xmake's module system that declarations can't
describe. Read [CONTRIBUTING.md](CONTRIBUTING.md) before changing the generator,
plugin or tests.

## Code

- `xmake/includes/luals/library/` is generated. Change the generator and
  regenerate instead of editing it.
- Derive declarations from the running xmake and its Apache-2.0 source. Don't
  copy prose from xmake's documentation site, which has no license.
- Keep changes scoped. Follow existing patterns before introducing helpers or
  abstractions.
- Comments explain non-obvious constraints, invariants or workarounds. Do not
  restate the code or describe earlier implementations.
- Pass untrusted GitHub Actions inputs to shell steps through environment
  variables, never direct expression interpolation into command text.

## Validation

- Regenerate the library and run the tests before calling a change complete.
- A declaration or plugin change needs a fixture line that shows the diagnostic
  it adds or removes. Valid xmake code in fixtures must stay free of
  diagnostics.

## Commits

- Use Conventional Commits. Describe the problem and resulting behavior for a
  reviewer evaluating the current diff. Omit session history and Git mechanics.
- Fix failures from the pre-commit checks instead of skipping them.
