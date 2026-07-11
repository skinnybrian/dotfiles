# エージェントプロンプト

$ARGUMENTS をトピックとしてエージェントを並列起動する。

## 共通指示

- 結果は **300ワード以内** に要約してまとめること（生データをそのまま返さない）
- まとめる形式: アプローチ概要、メリット・デメリット、採用状況/推奨度、ソースURL
- **WebFetch は最大2件まで**。WebSearch の結果から最も有望な2件だけを選んで詳細を取得する。残りはスニペット情報で判断する
- WebFetch で取得したページも全文引用せず、要点を抽出して要約に組み込む

## Agent 1: 実践知識エージェント

検索先: ブログ、公式ドキュメント、Stack Overflow、dev.to、Medium

WebSearch クエリ（最低3つ）:
- "$ARGUMENTS best practices （実行時の西暦年）"
- "$ARGUMENTS tutorial guide"
- "$ARGUMENTS common mistakes pitfalls"

## Agent 2: OSSエコシステムエージェント

検索手段:
- WebSearch で関連 GitHub リポジトリ・ライブラリ比較記事を検索
- `gh search repos "$ARGUMENTS" --sort stars --limit 10`
- 必要に応じて `gh search code "$ARGUMENTS"` で実装パターンを検索

調査ポイント: スター数、最終更新日、メンテナンス状況、採用事例

## Agent 3: 学術・技術論文エージェント（`--academic` 指定時のみ起動）

WebSearch クエリ:
- "$ARGUMENTS" site:arxiv.org
- "$ARGUMENTS" research paper （実行時の西暦年）
- "$ARGUMENTS" site:dl.acm.org OR site:ieee.org
- フォールバック: "$ARGUMENTS" academic paper survey

論文が見つからない場合は技術ホワイトペーパーや RFC 等の準学術的文書を探すこと。
