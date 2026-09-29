import json
import os
import re
import shutil
import subprocess
from pathlib import Path
from urllib.parse import unquote, urlparse
from urllib.request import url2pathname

import pytest

ROOT = Path(__file__).resolve().parents[1]
LUALS = ROOT / "xmake" / "includes" / "luals"
FIXTURES = ROOT / "tests" / "fixtures"
MARKER = re.compile(r"--!\s*([\w-]+)\s*$")


def language_server():
    program = os.environ.get("LUALS") or shutil.which("lua-language-server")
    assert program, "Set LUALS to the lua-language-server executable."
    return program


def expected(project):
    result = set()
    for file in sorted(project.rglob("*.lua")):
        lines = file.read_text(encoding="utf-8").splitlines()
        for number, line in enumerate(lines, start=1):
            if match := MARKER.search(line):
                relative = file.relative_to(project).as_posix()
                result.add((relative, number, match.group(1)))
    return result


def reported(project, tmp_path):
    config = tmp_path / "luarc.json"
    settings = {
        "runtime.version": "Lua 5.5",
        "runtime.special": {"import": "require"},
        "runtime.plugin": (LUALS / "plugin.lua").as_posix(),
        "runtime.pluginArgs": ["."],
        "workspace.library": [(LUALS / "library").as_posix()],
    }
    config.write_text(json.dumps(settings), encoding="utf-8")
    logs = tmp_path / "logs"
    subprocess.run(
        [
            language_server(),
            f"--check={project}",
            f"--configpath={config}",
            "--checklevel=Hint",
            f"--logpath={logs}",
            "--check_format=json",
        ],
        capture_output=True,
        check=False,
    )
    report = logs / "check.json"
    assert report.is_file(), f"lua-language-server wrote no report to {logs}"
    result = set()
    for uri, diagnostics in json.loads(report.read_text(encoding="utf-8")).items():
        file = Path(url2pathname(unquote(urlparse(uri).path)))
        relative = file.resolve().relative_to(project.resolve()).as_posix()
        for diagnostic in diagnostics:
            line = diagnostic["range"]["start"]["line"] + 1
            result.add((relative, line, diagnostic["code"]))
    return result


@pytest.mark.parametrize(
    "project", sorted(path.name for path in FIXTURES.iterdir() if path.is_dir())
)
def test_diagnostics_match_markers(project, tmp_path):
    directory = FIXTURES / project
    assert reported(directory, tmp_path) == expected(directory)
