---
title: "Claude Code skills のクロスプラットフォーム管理"
date: 2026-04-16
tags:
  - claude-code
  - dotfiles
  - skills
  - cross-platform
  - macOS
  - linux
command: "/research-best-practices Claude Code skills のクロスプラットフォーム管理"
sources:
  - https://code.claude.com/docs/en/skills
  - https://code.claude.com/docs/en/settings
  - https://github.com/feiskyer/claude-code-settings
  - https://github.com/Povaz/claude-code-dotfiles
  - https://github.com/JeremiahChurch/dotfiles-template
  - https://perevillega.com/posts/2026-04-01-claude-code-skills-2-what-changed-what-works-what-to-watch-out-for/
  - https://medium.com/@joe.njenga/claude-code-merges-slash-commands-into-skills-dont-miss-your-update-8296f3989697
  - https://claudefa.st/blog/tools/hooks/cross-platform-hooks
  - https://drmowinckels.io/blog/2026/dotfiles-coding-agents/
  - https://arxiv.org/abs/2501.18555
  - https://arxiv.org/abs/2601.20404
  - https://arxiv.org/abs/2602.14690
  - https://doi.org/10.1016/j.jss.2026.112803
  - https://arxiv.org/abs/2603.16021
  - https://arxiv.org/abs/2512.18925
---

# Claude Code skills のクロスプラットフォーム管理

## サマリー

Claude Code の skills/commands/agents を macOS と Android Linux (AVF Debian) の2環境で dotfiles リポジトリを使って管理する方法を調査した。2026年現在、commands は skills に統合済み（後方互換あり）で新規作成は skills 形式が推奨。dotfiles での管理はディレクトリ symlink が最もシンプルで、settings.json の環境差分は `settings.local.json` で吸収するのが公式推奨パターン。

## 詳細

### commands → skills 統合

Claude Code v2.1.3 で custom commands と skills が統合された。`.claude/commands/deploy.md` と `.claude/skills/deploy/SKILL.md` はどちらも `/deploy` として動作する。既存の commands は引き続き動作するが、新規作成は skills 形式が推奨。

| 特性 | commands（旧） | skills（新） |
|------|---------------|-------------|
| 構造 | 単一 `.md` ファイル | フォルダ + `SKILL.md` |
| 自動発見 | なし（明示的 `/` 実行のみ） | description ベースで Claude が自動判断 |
| 補助ファイル | 不可 | スクリプト・テンプレート・参考資料を同梱可 |
| YAML frontmatter | サポート | フル対応（invocation 制御、ツール制限等） |
| 互換性 | 継続動作 | 完全上位互換 |

skills のディレクトリ構造:
```
~/.claude/skills/
├── commit/
│   └── SKILL.md           # 必須（YAML frontmatter + 指示）
├── research/
│   ├── SKILL.md
│   └── references/
│       └── api-docs.md    # 補助ファイル（任意）
└── deploy/
    ├── SKILL.md
    └── scripts/
        └── deploy.sh
```

注意点:
- 同名の skill と command がある場合 skill が優先される
- `$ARGUMENTS`, `${CLAUDE_SKILL_DIR}` 等の変数置換が使える
- `` !`command` `` で動的コンテキスト注入が可能
- スキル数の上限目安はプロジェクトあたり 5-8 個

### アプローチ比較

推奨度: ★=条件付き推奨 ★★=推奨 ★★★=強く推奨

#### skills の管理方式

| アプローチ | メリット | デメリット | 採用例 | 推奨度 |
|-----------|---------|-----------|--------|-------|
| ディレクトリ symlink (`ln -sfn`) | 一行で完結、commands/agents と統一 | 環境固有 skill を直接追加できない | Povaz/claude-code-dotfiles | ★★★ |
| 個別 skill ごと symlink (for loop) | 管理外 skill と混在可能 | スクリプトが複雑化 | — | ★★ |
| chezmoi テンプレート | OS 別テンプレート、暗号化対応 | 新ツール導入の学習コスト | JeremiahChurch/dotfiles-template | ★ |

#### settings.json の環境分岐

| アプローチ | メリット | デメリット | 推奨度 |
|-----------|---------|-----------|-------|
| 単一ファイル共有 + `settings.local.json` で差分吸収 | 公式マージ機構を活用、DRY | 各環境で local ファイルの初期設定が必要 | ★★★ |
| setup.sh で OS 判定 → 環境別 local ファイルを symlink | 追加ツール不要、dotfiles 内で完結 | ファイル数が増える | ★★★ |
| chezmoi テンプレート | 1ソースから全環境生成 | chezmoi 導入前提 | ★★ |
| jq マージ | 共通部分の重複回避 | jq 依存、マージ順序に注意 | ★ |

### 参考 OSS リポジトリ

| リポジトリ | Stars | 特徴 |
|-----------|-------|------|
| [feiskyer/claude-code-settings](https://github.com/feiskyer/claude-code-settings) | 1,441 | skills/agents の豊富な実例、プロバイダ別 settings テンプレート |
| [fcakyon/claude-codex-settings](https://github.com/fcakyon/claude-codex-settings) | 603 | Claude + Codex 両対応、plugin エコシステム統合 |
| [Povaz/claude-code-dotfiles](https://github.com/Povaz/claude-code-dotfiles) | 0 | symlink ベース、setup.sh/teardown.sh 付き |
| [JeremiahChurch/dotfiles-template](https://github.com/JeremiahChurch/dotfiles-template) | — | chezmoi + Claude Code + WSL テンプレート |

### 推奨事項

1. **skills/ ディレクトリを dotfiles に追加し symlink で管理**（`ln -sfn ~/dotfiles/claude/skills ~/.claude/skills`）
2. **新規は skills 形式で作成、既存 commands は段階的に移行**（同名 skill が優先されるので注意）
3. **settings.json は共通設定のみ、環境差分は settings.local.json で吸収**（setup.sh で OS 判定して環境別ファイルを symlink）
4. **CLAUDE.md は1ファイル管理、OS 別セクションで見出し分離**
5. **2環境なら chezmoi は不要**、setup.sh + `uname` 分岐で十分

### 具体的なアクション

- **すぐできること**: `claude/skills/` ディレクトリ作成、`setup.sh` に `ln -sfn` 追加
- **段階的に**: commands → skills への移行（`SKILL.md` + フォルダ構造）
- **環境差分が出てきたら**: `settings.local.darwin.json` / `settings.local.linux.json` を作成し、`setup.sh` で OS 判定 symlink

### クロスプラットフォーム dotfiles 管理ツール比較

| 項目 | chezmoi | GNU Stow | YADM | 手動 symlink |
|---|---|---|---|---|
| OS 別テンプレート | Go template | なし | alternate files | スクリプトで分岐 |
| シークレット管理 | パスワードマネージャ統合 | なし | 暗号化対応 | なし |
| 依存関係 | Go バイナリ1つ | Perl | Git wrapper | なし |
| 学習コスト | 中〜高 | 低 | 低〜中 | 最低 |
| Claude Code との相性 | テンプレートで settings.json を環境別生成 | symlink のみ | alternate files で分岐可能 | 現在の方式 |

## 学術的知見

この分野は2025-2026年に研究が急増しており、以下の重要な知見がある：

- **AGENTS.md/CLAUDE.md の効果**: 指示ファイルがあると AI エージェントの実行時間が中央値で **28.64% 短縮**、出力トークン消費が 16.58% 減少（Lulla et al., 2026, [arXiv:2601.20404](https://arxiv.org/abs/2601.20404)）
- **AI コーディングツールの設定メカニズム**: Claude Code ユーザーが最も広範な設定メカニズムを活用。8つの設定メカニズムを同定（Galster et al., 2026, [arXiv:2602.14690](https://arxiv.org/abs/2602.14690)）
- **Development Environment as Code (DEaC)**: ローカル開発環境の設定自動化が開発者満足度と生産性に直結。4つの設計原則を提示（Ghanbari et al., 2026, [JSS Vol.236](https://doi.org/10.1016/j.jss.2026.112803)）
- **フォルダ構造 = エージェントアーキテクチャ**: ディレクトリ構成自体がエージェントの動作設計になる Model Workspace Protocol（Van Clief & McDermott, 2026, [arXiv:2603.16021](https://arxiv.org/abs/2603.16021)）
- **dotfiles 実態調査**: トップ500 GitHub ユーザーの 25.8% が公開 dotfiles を保有。vimrc (63.9%), gitconfig (63.1%), tmux.conf (59.0%), zshrc (56.2%) が最多（Zhu & Godfrey, 2025, [arXiv:2501.18555](https://arxiv.org/abs/2501.18555)）
- **Cursor Rules の分類体系**: 5テーマ（Conventions, Guidelines, Project Information, LLM Directives, Examples）に分類。CLAUDE.md の構造設計に応用可能（Jiang & Nam, 2025, [arXiv:2512.18925](https://arxiv.org/abs/2512.18925)）
- **コーディングエージェント採用率**: 22.20〜28.66%。設定管理の重要性が増大（Robbes et al., 2026, [arXiv:2601.18341](https://arxiv.org/abs/2601.18341)）

## 参考リンク

### 実践リソース
- [Extend Claude with skills - 公式ドキュメント](https://code.claude.com/docs/en/skills) — skills の公式ガイド
- [Claude Code settings - 公式ドキュメント](https://code.claude.com/docs/en/settings) — settings マージ挙動の詳細
- [feiskyer/claude-code-settings](https://github.com/feiskyer/claude-code-settings) — skills/agents の豊富な実例集
- [Povaz/claude-code-dotfiles](https://github.com/Povaz/claude-code-dotfiles) — symlink ベースの管理テンプレート
- [JeremiahChurch/dotfiles-template](https://github.com/JeremiahChurch/dotfiles-template) — chezmoi + Claude Code テンプレート
- [Skills 2.0: What Changed](https://perevillega.com/posts/2026-04-01-claude-code-skills-2-what-changed-what-works-what-to-watch-out-for/) — skills 統合後の変更点まとめ
- [Claude Code Merges Slash Commands Into Skills](https://medium.com/@joe.njenga/claude-code-merges-slash-commands-into-skills-dont-miss-your-update-8296f3989697) — commands → skills 移行ガイド
- [Cross-Platform Hooks](https://claudefa.st/blog/tools/hooks/cross-platform-hooks) — hooks のクロスプラットフォーム対応
- [Dotfiles: Taming Your Dev Environment](https://drmowinckels.io/blog/2026/dotfiles-coding-agents/) — AI 時代の dotfiles 管理

### 学術論文
- [An Empirical Study of Dotfiles Repositories](https://arxiv.org/abs/2501.18555) — dotfiles リポジトリの大規模実態調査（Zhu & Godfrey, 2025）
- [On the Impact of AGENTS.md Files](https://arxiv.org/abs/2601.20404) — AGENTS.md による効率28.64%向上を実証（Lulla et al., 2026）
- [Configuring Agentic AI Coding Tools](https://arxiv.org/abs/2602.14690) — AI コーディングツールの設定メカニズム体系分析（Galster et al., 2026）
- [Using DEaC for Enhancing Developer Experience](https://doi.org/10.1016/j.jss.2026.112803) — Development Environment as Code の提唱（Ghanbari et al., 2026）
- [Interpretable Context Methodology](https://arxiv.org/abs/2603.16021) — フォルダ構造 = エージェントアーキテクチャ（Van Clief & McDermott, 2026）
- [Beyond the Prompt: Cursor Rules](https://arxiv.org/abs/2512.18925) — AI 設定ファイルの5テーマ分類体系（Jiang & Nam, 2025）
- [Mitigating Configuration Differences](https://arxiv.org/abs/2505.09392) — 環境間設定差異の緩和戦略カタログ（Nazario et al., 2025）
- [Context Engineering for AI Agents](https://arxiv.org/abs/2510.21413) — AIコンテキストファイルの記述スタイル分析（Mohsenimofidi et al., 2025）
