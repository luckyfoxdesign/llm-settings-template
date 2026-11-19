#!/usr/bin/env bash
# PreToolUse guard for Bash and file tools. Never read target file contents.
# Python handles JSON/shlex; this wrapper also works on macOS Bash 3.2.
set -eu
guard_dir="$(cd "$(dirname "$0")" && pwd)" || exit 2
python3 -B -c '
import json
import os
import re
import shlex
import sys
from pathlib import Path, PurePosixPath

sys.path.insert(0, sys.argv[1])
from workspace_rules import private_path


def block(reason):
    print("Bash guard: " + reason, file=sys.stderr)
    sys.exit(2)


def ask(reason):
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse", "permissionDecision": "ask",
        "permissionDecisionReason": "Bash guard: " + reason}}))


def check_path(path, cwd):
    if private_path(path):
        block("private path reference")
    try:
        target = Path(path).expanduser()
        if not target.is_absolute():
            target = Path(cwd) / target
        # Path spelling/symlink metadata only: never open the target.
        if private_path(target) or private_path(target.resolve()):
            block("private path reference")
        return target
    except (ValueError, OSError, RuntimeError):
        block("cannot validate path")


try:
    event = json.load(sys.stdin)
    tool = event["tool_name"]
    inputs = event["tool_input"]
    if not isinstance(inputs, dict):
        block("invalid tool input")
    cwd = event.get("cwd", os.getcwd())
    if not isinstance(cwd, str):
        block("invalid working directory")
    if tool in {"Read", "Grep", "Glob", "Edit", "Write", "NotebookEdit"}:
        search = tool in {"Grep", "Glob"}
        key = "path" if search else "notebook_path" if tool == "NotebookEdit" else "file_path"
        path = inputs.get(key, event.get("cwd", os.getcwd()) if search else None)
        if not isinstance(path, str) or not path:
            block("invalid file path")
        target = check_path(path, cwd)
        if search:
            glob = inputs.get("glob" if tool == "Grep" else "pattern", "")
            if not isinstance(glob, str):
                block("invalid search glob")
            if private_path(glob):
                block("private search glob")
            if tool == "Glob" or not target.is_file():
                # Relative native denies filter scans within cwd, but cannot
                # filter an external tree with the same placeholder exception.
                if not target.resolve().is_relative_to(Path(cwd).resolve()):
                    block("directory search outside the current workspace")
                ask("directory searches require confirmation; private files remain off limits")
        sys.exit(0)
    command = inputs["command"]
    if tool != "Bash" or not isinstance(command, str) or not command.strip():
        block("invalid Bash hook input")
    lexer = shlex.shlex(command, posix=True, punctuation_chars=True)
    lexer.whitespace_split = True
    lexer.commenters = ""
    tokens = list(lexer)
except (ValueError, KeyError, TypeError, AttributeError, OSError, RuntimeError):
    block("invalid Bash hook input")

# Scan both raw text (including interpreter source) and shell-unquoted words.
# Splitting punctuation finds paths inside open(...), redirects and assignments.
for token in tokens:
    check_path(token, cwd)
for text in [command] + tokens:
    for path in re.split(r"[^\w./~*?{}@+%:-]+", text):
        if path:
            check_path(path, cwd)

# Match executable basenames as well as commands behind env/command/sudo and
# inside pipelines or compound commands. Conservative matches are intentional.
words = [PurePosixPath(t).name for t in tokens]
for i, word in enumerate(words):
    args = []
    for token in words[i + 1:]:
        if re.fullmatch(r"[;&|()<>]+", token):
            break
        args.append(token)
    if word == "rm" and any(a == "--recursive" or
            (a.startswith("-") and not a.startswith("--") and re.search("[rR]", a)) for a in args):
        block("recursive removal")
    if word == "find" and "-delete" in args:
        block("find deletion")
    if word == "git":
        if "clean" in args:
            block("git clean")
        if "push" in args and any(a in {"-f", "--force", "--force-with-lease", "--force-if-includes"}
                or a.startswith(("--force=", "--force-with-lease="))
                or (a.startswith("-") and not a.startswith("--") and "f" in a)
                or a.startswith("+") for a in args):
            block("forced git push")
        if "reset" in args and "--hard" in args:
            block("hard git reset")
        if "branch" in args and "-D" in args:
            block("forced branch deletion")
    if word == "docker" and ("system" in args and "prune" in args
            or "volume" in args and any(a in {"prune", "rm"} for a in args)):
        block("Docker system or volume removal")
    if word == "sudo" and any(a in {"--login", "su", "rm"} or
            (a.startswith("-") and not a.startswith("--") and "i" in a) for a in args):
        block("privileged destructive command or login shell")
    if word == "chmod" and any(re.fullmatch(r"0*777", a) or any(set(mode) >= set("rwx") for mode in re.findall(r"(?:^|,)a\+([rwx]+)", a)) for a in args):
        block("world-writable executable permissions")

shells = {"sh", "bash", "zsh", "dash", "ksh", "fish"}
if any(w in {"curl", "wget"} for w in words) and any(w in shells for w in words):
    block("download piped or substituted into a shell")

# Never emit allow: ordinary tool permission rules still apply after exit 0.
if "ssh" in words:
    ask("SSH requires confirmation; inspect read-only first")
elif any(w in shells | {"eval", "source", ".", "exec", "xargs", "cd", "pushd", "popd", "python", "python3", "node", "ruby", "perl", "osascript"} for w in words) or any(re.fullmatch(r"(?:python|pypy)(?:[0-9]+(?:\.[0-9]+)*)?", w) for w in words) or re.search(r"[$`\\*?{}\[]", command) or any(w in {"rg", "ag", "grep", "env", "printenv"} for w in words):
    ask("dynamic or interpreted commands require confirmation")
' "$guard_dir" || exit 2
