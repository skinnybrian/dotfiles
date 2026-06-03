# Repository Guidelines

## Language & Documentation
既定では日本語で応答する。ユーザーが英語や別言語を明示した場合のみ、その指定に従う。

Codex が新規作成または更新する Markdown ドキュメント、設計書、調査メモ、README、PR/issue 草案は、ユーザーが別言語を指定しない限り日本語で書く。

コード、コマンド、設定キー、固有名詞、引用、エラーメッセージは原文または英語のままでよい。既存ドキュメントが英語の場合でも、周辺スタイルとの整合が必要な箇所を除き、新規・追記部分は日本語を優先する。

## Project Structure & Module Organization
This repository is a local Codex home directory, not an application source tree. Treat [`config.toml`](/Users/brian/.codex/config.toml) as the primary maintained file. Runtime and cache artifacts include `auth.json`, `history.jsonl`, `models_cache.json`, `version.json`, `state_5.sqlite*`, and `logs_2.sqlite*`. Keep generated content under `sessions/`, `shell_snapshots/`, `log/`, `sqlite/`, and `cache/` out of manual edits unless you are debugging Codex internals. Plugin bundles live in `plugins/cache/`, and imported skill content lives in `vendor_imports/`.

## Build, Test, and Development Commands
There is no build pipeline for this repository. Use inspection commands instead:

- `codex --version`: verify the installed CLI version.
- `sed -n '1,200p' config.toml`: review active configuration.
- `rg -n "trust_level|mcp_servers|plugins" config.toml`: audit key settings quickly.
- `find sessions -maxdepth 3 -type f | head`: inspect recorded session files.

After changing `config.toml`, restart Codex or open a fresh session so the new settings are picked up.

## Coding Style & Naming Conventions
Use ASCII by default. Keep Markdown concise, with short sections and actionable wording. In TOML, preserve the existing layout: global keys first, then grouped tables such as `[mcp_servers.*]`, `[projects.*]`, and `[plugins.*]`. Use absolute paths for local tools and project entries. Do not reformat unrelated settings while making a targeted change.

## Testing Guidelines
There is no automated test suite or coverage target here. Validate configuration changes by checking that Codex starts cleanly and the expected tool, plugin, or project trust entry appears in behavior. When changing docs, verify file names exactly match the configured fallback order, especially `CLAUDE.md` before `README.md`.

## Commit & Pull Request Guidelines
This directory is currently not a Git repository, so there is no local commit history to infer from. If you place it under version control, use short imperative commit titles such as `Add pencil MCP config` or `Document project doc fallback`. PRs should describe the user-visible effect, list edited paths, and call out any sensitive files intentionally excluded, especially `auth.json` and session logs.

## Security & Configuration Tips
Never paste secrets into documentation. Avoid committing `auth.json`, token-bearing caches, SQLite state, or raw session transcripts. Prefer editing `config.toml` and durable docs only; treat `plugins/cache/` and `vendor_imports/` as managed content unless you are intentionally updating installed assets.
