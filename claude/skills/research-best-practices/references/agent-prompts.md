# エージェントプロンプト

$ARGUMENTS をトピックとして、以下の3つのエージェントを並列で起動する。

## Agent 1: 実践知識エージェント

```
「$ARGUMENTS」について、実践的なベストプラクティスを調査してください。

検索対象:
- ブログ記事、チュートリアル、公式ドキュメント
- Stack Overflow、dev.to、Medium等の技術記事
- 公式ガイドやリファレンス

WebSearchで以下のクエリを実行（最低3つ）:
- "$ARGUMENTS best practices （実行時の西暦年）"
- "$ARGUMENTS tutorial guide"
- "$ARGUMENTS common mistakes pitfalls"

有望な結果はWebFetchで詳細を取得すること。

各結果について以下をまとめて返す:
- アプローチの概要
- メリット・デメリット
- 採用状況・推奨度
- ソースURL

日本語で報告すること。
```

## Agent 2: OSSエコシステムエージェント

```
「$ARGUMENTS」について、オープンソースの実装例やライブラリを調査してください。

検索手段:
- WebSearchで「$ARGUMENTS」関連のGitHubリポジトリ、ライブラリ比較記事を検索
- Bashで `gh search repos "$ARGUMENTS" --sort stars --limit 10` を実行
- 必要に応じて `gh search code "$ARGUMENTS"` で実装パターンを検索

調査ポイント:
- 人気ライブラリ・フレームワークの比較
- スター数、最終更新日、メンテナンス状況
- 実際の採用事例
- 異なるアプローチの実装例

各結果について以下をまとめて返す:
- リポ名/ライブラリ名とURL
- スター数・最終更新
- アプローチの特徴
- メリット・デメリット

日本語で報告すること。
```

## Agent 3: 学術・技術論文エージェント

```
「$ARGUMENTS」に関連する学術論文や技術論文を調査してください。

WebSearchで以下のクエリを実行（site:指定が効かない場合は通常検索にフォールバック）:
- "$ARGUMENTS" site:arxiv.org
- "$ARGUMENTS" research paper （実行時の西暦年）
- "$ARGUMENTS" site:dl.acm.org OR site:ieee.org
- フォールバック: "$ARGUMENTS" academic paper survey

有望な論文はWebFetchでabstractや概要を取得すること。Google Scholarはスクレイピング困難な場合があるため、arXivやACM DL等を優先する。

各論文について以下をまとめて返す:
- タイトル
- 著者・発表年
- 主要な知見・提案手法
- 実務への応用可能性
- URL

論文が見つからない場合は、その旨を報告し、技術ホワイトペーパーやRFC等の準学術的文書を探すこと。

日本語で報告すること。
```
