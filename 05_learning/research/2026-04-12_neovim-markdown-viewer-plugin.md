---
title: "Neovim Markdownビューワプラグイン調査 2026"
date: 2026-04-12
tags:
  - neovim
  - markdown
  - plugin
  - lazy.nvim
  - treesitter
command: "/research-best-practices neovimに導入できる2026年現在でよく使われているmarkdown形式のビューワplugin"
sources:
  - https://github.com/MeanderingProgrammer/render-markdown.nvim
  - https://github.com/OXY2DEV/markview.nvim
  - https://github.com/iamcco/markdown-preview.nvim
  - https://github.com/toppair/peek.nvim
  - https://github.com/MeanderingProgrammer/render-markdown.nvim/blob/main/doc/markdown-ecosystem.md
  - http://www.lazyvim.org/extras/lang/markdown
  - https://linkarzu.com/posts/neovim/markdown-setup-2025/
  - https://mambusskruj.github.io/posts/pub-neovim-for-markdown/
  - https://github.com/neovim/neovim/pull/31324
  - https://github.com/tree-sitter-grammars/tree-sitter-markdown
  - https://jdhao.github.io/2021/09/09/nvim_use_virtual_text/
  - https://deepwiki.com/MeanderingProgrammer/render-markdown.nvim
---

# Neovim Markdownビューワプラグイン調査 2026

## サマリー

2026年現在、Neovim向けMarkdownビューワプラグインはターミナル内レンダリング型（extmarks/virtual text）とブラウザプレビュー型の2系統に分かれる。ターミナル内レンダリング型の **render-markdown.nvim** が LazyVim公式採用・Dotfyle採用数1位のデファクトスタンダード。CLIレンダリング型の glow.nvim はアーカイブ済みで新規採用は非推奨。

## 詳細

### アプローチ比較

推奨度: ★=条件付き推奨 ★★=推奨 ★★★=強く推奨

| アプローチ | プラグイン | Stars | 最終更新 | メリット | デメリット | 推奨度 |
|-----------|-----------|-------|---------|---------|-----------|-------|
| ターミナル内レンダリング | **render-markdown.nvim** | 4,387 | 2026-04-08 | 外部依存ゼロ、LazyVim公式採用、デフォルト設定で即戦力、anti-conceal機構 | 画像・Mermaid非対応 | ★★★ |
| ターミナル内レンダリング（マルチフォーマット） | **markview.nvim** | 3,416 | 2026-03-20 | Typst/LaTeX/Asciidocも対応、ハイブリッドモード、Splitview | Neovim>=0.10.3必須、`lazy=false`推奨、設定が複雑 | ★★ |
| ブラウザプレビュー | **markdown-preview.nvim** | 7,800 | 2023-10-17 | Mermaid/数式/画像の完璧な表示、同期スクロール | メンテナンス事実上停止、Node.js依存、ブラウザ必須 | ★★ |
| Webviewプレビュー | **peek.nvim** | 857 | 2024-04-09 | ブラウザ不要のWebview、GitHub風スタイル | Deno依存、メンテナンス不安 | ★ |
| CLIレンダリング | **glow.nvim** | 1,333 | アーカイブ済 | — | メンテナンス終了 | — |

### 各プラグイン詳細

#### render-markdown.nvim（最推奨）

- **リポジトリ**: https://github.com/MeanderingProgrammer/render-markdown.nvim
- **Stars**: 4,387 / Dotfyle採用数698（Markdown系1位）
- **最終更新**: 2026-04-08（超アクティブ）
- **最新リリース**: v8.12.0 (2026-03-09)
- **必須Neovim**: >= 0.9.0（推奨 0.10.0+）

TreeSitterで構文木を取得し、各ノードを extmark に変換してバッファ内に視覚効果を適用。Normalモードでレンダリング、Insertモードで生テキストに戻る anti-conceal 機構が秀逸。可視範囲のみ処理 + デバウンス100msでパフォーマンス良好。

**lazy.nvim設定例:**
```lua
{
  'MeanderingProgrammer/render-markdown.nvim',
  dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
  ft = { 'markdown' },
  opts = {},
}
```

#### markview.nvim

- **リポジトリ**: https://github.com/OXY2DEV/markview.nvim
- **Stars**: 3,416 / Dotfyle採用数251
- **最終更新**: 2026-03-20
- **最新リリース**: v28.1.0 (2026-03-04)
- **必須Neovim**: >= 0.10.3

render-markdown.nvimの派生だが、Markdown + Typst + LaTeX + HTML + Asciidoc のマルチフォーマット対応が最大の差別化。ハイブリッドモード（編集&プレビュー同時）とSplitview（サイドバイサイド）が独自機能。2,056+ LaTeXシンボル、1,920 GitHubエモジ対応。

**lazy.nvim設定例:**
```lua
{
  "OXY2DEV/markview.nvim",
  lazy = false,  -- 公式推奨: lazy=trueにしないこと
}
```

#### markdown-preview.nvim

- **リポジトリ**: https://github.com/iamcco/markdown-preview.nvim
- **Stars**: 7,800（最多）
- **最終更新**: 2023-10-17（2年半以上前）
- **必須依存**: Node.js

ブラウザでリアルタイムプレビュー + 同期スクロール。KaTeX/Mermaid/PlantUML/Chart.js/Graphviz 対応で図・数式の表示品質が最も高い。render-markdown.nvimと公式にNon-Conflicting（共存可能）。

**lazy.nvim設定例:**
```lua
{
  "iamcco/markdown-preview.nvim",
  cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  build = "cd app && yarn install",
  init = function()
    vim.g.mkdp_filetypes = { "markdown" }
  end,
  ft = { "markdown" },
}
```

### 推奨事項

1. **render-markdown.nvim 単体導入**（最推奨）— 既にTreesitter・nvim-web-devicons導入済みの環境に最適。設定ほぼ3行で完了
2. **render-markdown.nvim + markdown-preview.nvim 併用** — 図・数式の確認が必要な場合。普段はバッファ内、必要時だけ`:MarkdownPreview`
3. **markview.nvim** — Typst/LaTeX/Asciidocもバッファ内で確認したい場合

### 導入時の注意点

- `:TSInstall markdown markdown_inline` でTreesitterパーサーを忘れずインストール
- `showbreak`/`breakindent` 設定の不整合でレンダリングが崩れることがある
- markview.nvim は `lazy = false` が公式推奨
- 複数プラグインが `conceallevel` を奪い合う場合がある

## 技術的知見

- **Extmark API** (`nvim_buf_set_extmark()`) がターミナル内レンダリングの根幹技術。virtual textの`overlay`/`eol`/`inline`モードとconcealでMarkdown構文を装飾
- **Neovim 0.11の`conceal_lines`** (PR #31324): 行全体を非表示にする新機能でコードブロックのフェンス行を完全に隠せる
- **TreeSitter 2パス設計**: CommonMark仕様に従い`markdown`（ブロック）と`markdown_inline`（インライン）を分離処理
- **Anti-Conceal**: カーソル行では仮想テキストを非表示にし元のMarkdownソースを表示する仕組み
- markdown-preview.nvim は Node.js + Socket.IO + React の3層アーキテクチャ

## 参考リンク

### 実践リソース
- [render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim) — デファクトスタンダードのターミナル内Markdownレンダラ
- [markview.nvim](https://github.com/OXY2DEV/markview.nvim) — マルチフォーマット対応の高カスタマイズ性レンダラ
- [markdown-preview.nvim](https://github.com/iamcco/markdown-preview.nvim) — ブラウザベースのリアルタイムプレビュー
- [peek.nvim](https://github.com/toppair/peek.nvim) — Denoベースのwebviewプレビュー
- [Markdown Ecosystem (render-markdown.nvim docs)](https://github.com/MeanderingProgrammer/render-markdown.nvim/blob/main/doc/markdown-ecosystem.md) — 各プラグインの関係性整理
- [LazyVim Markdown Extra](http://www.lazyvim.org/extras/lang/markdown) — LazyVim公式のMarkdown構成
- [My Neovim Markdown Setup 2025 (linkarzu)](https://linkarzu.com/posts/neovim/markdown-setup-2025/) — 実践的セットアップガイド
- [Neovim as a Markdown Editor (mambusskruj)](https://mambusskruj.github.io/posts/pub-neovim-for-markdown/) — Marksman LSP連携解説

### 技術的深掘り
- [Neovim conceal_lines PR #31324](https://github.com/neovim/neovim/pull/31324) — Neovim 0.11の行conceal新機能
- [tree-sitter-markdown](https://github.com/tree-sitter-grammars/tree-sitter-markdown) — 2パスMarkdownパーサー
- [Using Virtual Text in Neovim (jdhao)](https://jdhao.github.io/2021/09/09/nvim_use_virtual_text/) — Extmark API基礎解説
- [render-markdown.nvim (DeepWiki)](https://deepwiki.com/MeanderingProgrammer/render-markdown.nvim) — アーキテクチャ解析
