#!/usr/bin/env python3
"""memory-index-guard.py — PostToolUse hook（Write|Edit|Bash）

auto memory の目次（~/.claude/projects/*/memory/MEMORY.md）が書き換えられたら、
「目次の 1 行は 150 字以内」と全体の大きさを数え、超えていればモデルに知らせる（止めはしない）。

- Write・Edit: tool_input.file_path が .../.claude/projects/*/memory/MEMORY.md のときだけ
- Bash: コマンドに「MEMORY.md」が入っていて、直近 RECENT 秒に書き換えられた目次があるときだけ
  （python などで書き換えると、どのファイルかがコマンドから読めないため）
- 字数は文字数で数える（読み込みの上限も文字数）。入力が読めないときは何もしない（exit 0）
"""
import glob
import json
import os
import sys
import time

LINE_MAX = 150
TOTAL_WARN = 17000  # Claude Code が保存時に出す警告（約 17,510 字）の少し手前
RECENT = 120


def targets(data):
    tool_input = data.get("tool_input") or {}
    path = tool_input.get("file_path") or ""
    if "/.claude/projects/" in path and path.endswith("/memory/MEMORY.md"):
        return [path]
    if data.get("tool_name") == "Bash" and "MEMORY.md" in (tool_input.get("command") or ""):
        now = time.time()
        found = []
        for p in glob.glob(os.path.expanduser("~/.claude/projects/*/memory/MEMORY.md")):
            try:
                if now - os.path.getmtime(p) <= RECENT:
                    found.append(p)
            except OSError:
                pass
        return found
    return []


def check(path):
    with open(path, encoding="utf-8") as f:
        text = f.read()
    lines = text.split("\n")
    long_lines = [(i + 1, len(l)) for i, l in enumerate(lines) if len(l) > LINE_MAX]
    if not long_lines and len(text) <= TOTAL_WARN:
        return None
    count = len(lines) - (1 if text.endswith("\n") else 0)
    parts = [f"{path}: {len(text):,} 字・{count} 行。"]
    if long_lines:
        shown = "、".join(f"{n} 行目（{c} 字）" for n, c in long_lines[:10])
        more = f" ほか {len(long_lines) - 10} 行" if len(long_lines) > 10 else ""
        parts.append(f"{LINE_MAX} 字を超える行: {shown}{more}。")
    if len(text) > TOTAL_WARN:
        parts.append(f"全体が {TOTAL_WARN:,} 字を超えた（起動時に読まれるのは約 25,000 字まで）。")
    parts.append("目次の行は 150 字以内に縮め、詳しいことは本体のファイルへ移す。必ず守る決まりは目次に置かず CLAUDE.md・Hook へ。")
    return "".join(parts)


def main():
    data = json.load(sys.stdin)
    notes = [n for n in (check(p) for p in targets(data)) if n]
    if notes:
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": "\n".join(notes)}}, ensure_ascii=False))


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
    sys.exit(0)
