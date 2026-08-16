---
name: dispatch-goal
description: Use when GitHub Issue を1件または複数件、herdrの子セッションに/goalで自走投げして実装させたいとき（「goalでやって」「#123をgoalで回して」「並列でIssue実装させて」等の自然文を含む）、または起動済みの/goal自走セッションの完了を監視して回収・報告したいとき。
---

# dispatch-goal — Issue を子セッションへ /goal で自走投げする運用

## Overview

GitHub Issue を1件（または複数件同時）、herdr の子 Claude セッションへ **`/goal`** で投げて自走実装させ、完了を検知して回収・報告するまでの一連の手順。pane / agent 操作そのものの作法は **REQUIRED SUB-SKILL: herdr**（`~/dotfiles/claude/skills/herdr/SKILL.md`）に譲り、ここでは goal 自走運用に固有の手順とハマりどころだけを扱う。herdr の基本操作（split, start, prompt の構文等）は先に herdr skill を参照すること。

## ⚠️ herdr の golden path をそのまま使わない

herdr skill の「複数並列」golden path は「`--wait` 無しで全員に送信 → `herdr agent wait <名前>` で1体ずつ回収」と教えているが、**goal 自走セッションの完了検知にこれを使ってはいけない**。理由は「完了検知」節を参照。goal 用の完了検知は herdr skill の golden path を明示的に上書きし、必ずポーリングループ方式を使う。

## 固定プロンプト（逐語で送る。差し替えは `{issue番号}` のみ）

```
/goal #{issue番号}を実装する。worktreeを必ず切る。superpowersスキルベースで進める。ブレスト途中でユーザに選択を求めてきた時は、推奨を自動選択して続行する。spec/plan両方作成完了次第、ユーザに確認を求めずに実装を進めてしまってOK。実装完了したらPRを作り、serveスキルでdevサーバを起動してから終えること。
```

文言は変えない。要約・意訳して送らない。

## 起動シーケンス

1. `test "${HERDR_ENV:-}" = 1` を確認。herdr 外なら pane / agent 操作をせず、ユーザーに herdr セッションでの起動を案内する。
2. 対象リポジトリで `git pull` して main を最新化。
3. 対象 Issue 本文の「前提」節に依存 PR の記載があれば、`gh pr view <PR番号> --repo <owner>/<repo> --json state -q .state` でマージ済み（`MERGED`）か確認する。未マージなら着手前にユーザーへ確認する。
4. **複数 Issue を同時に立ち上げる場合**、着手前に各 Issue 本文を読み、対象ファイル・機能領域が重ならないか確認する（別 Issue 由来の2 PR が同一ファイルを書き換えてコンフリクトした実績あり）。
   - ファイル/ディレクトリ単位で担当を分けられる重なりなら、対象 Issue の「前提」節にファイル所有権を明記する（無ければ新規に追記する）。ただし固定プロンプトは変更しないため遵守を強制する仕組みは無い。「完了後の定型処理」で PR の diff が担当範囲に収まっているか確認する。
   - 同一ファイルの同一箇所を両方が触るなど分割できない重なりなら、直列化する：片方だけ先に起動シーケンス5以降を進め、その PR がマージされてからもう片方に着手する。
   - どちらの対処を取るかはユーザーに提案し、**回答を待ってから**起動シーケンス5以降に進む。
5. 対象タブを決める。Issue 実装用に開いているタブがあればそこに、無ければ `herdr tab create --workspace <ID> --cwd <対象リポジトリ> --no-focus` で作る。
6. `herdr pane split --current --direction <right|down> --cwd <対象リポジトリ> --no-focus` で pane を分割し、`pane_id` を JSON レスポンスから読む。
7. `herdr agent start issue-<issue番号> --kind claude --pane <pane_id> -- --model sonnet`（モデル省略時は sonnet 既定）。
8. 固定プロンプトを送信する。**複数 Issue を同時に立ち上げる場合、プロンプトは `--wait` を付けずに全員へ送る**。
9. 続けて `herdr agent prompt issue-<issue番号> "/rename issue-<issue番号>-<slug>"` を送る。working 中でも通り、実行中のタスクを中断しない（実証済み）。`/rename` はホスト側の ListAgents / terminal title の表示名を変えるだけで、herdr の agent 名（手順7で `agent start` に渡した `issue-<issue番号>`）は変わらない — **監視・回収は常に `issue-<issue番号>` の方を使う**。
10. 完了監視ループを仕掛ける（次節）。

## 完了検知：`agent wait` は使わない

**なぜ**: 子セッションが subagent-driven-development で実装すると、サブエージェントの完了待ちの間に一瞬 `idle` になり、`herdr agent wait`（`idle`/`done`/`blocked` の settled 状態待ち）はこれを「完了」と誤判定する。実際に2回誤検知した。

**代わりに**: 対象ブランチの PR が立つ、または `agent_status` が `blocked` になるまで、**60秒間隔でポーリング**する。`idle` や `done` は完了の根拠にしない。ポーリングループは Bash tool の **`run_in_background: true`** で起動する。ブロックされるのは foreground 実行の長時間 `sleep` であって、`run_in_background: true` で起動したバックグラウンドの `sleep` ループはブロックされない（実測で確認済み）。全 Issue 解決でループが終了すると、その時点で完了通知が1回届く。Issue ごとに個別の通知を都度受け取りたい場合は Monitor tool（`persistent: true`）で同じスクリプトを起動してもよい（`echo` 行1つが通知1件になる点が Bash 版の「最後に1回だけ通知」と異なる）。

```bash
repo="<owner>/<repo>"
issues=(463 468)
declare -A resolved
while true; do
  prs=$(gh pr list --repo "$repo" --state open --json number,headRefName --limit 100)
  for n in "${issues[@]}"; do
    [ -n "${resolved[$n]:-}" ] && continue
    pr=$(jq -r --arg p "feature/$n-" \
      '.[] | select((.headRefName == ($p|rtrimstr("-"))) or (.headRefName | startswith($p))) | .number' \
      <<< "$prs" | head -1)
    astatus=$(herdr agent get "issue-$n" 2>/dev/null | jq -r '.result.agent.agent_status // empty')
    if [ -n "$pr" ]; then
      echo "issue-$n: PR #$pr が立った"; resolved[$n]=1
    elif [ "$astatus" = "blocked" ]; then
      echo "issue-$n: agent_status=blocked（要確認）"; resolved[$n]=1
    fi
  done
  [ "${#resolved[@]}" -eq "${#issues[@]}" ] && break
  sleep 60
done
echo "全Issue完了（PR出現 or blocked）"
```

このスクリプトを Bash tool の `run_in_background: true` で起動する（実装ボリューム次第で数時間かかることがあるため）。全 Issue が解決してループが終了すると完了通知が届く。ブランチ名フィルタは `feature/<番号>-` の末尾ハイフンまで含めて誤マッチ（`feature/4630-...` 等）を防ぐ。

**既知の制約**: エージェントがクラッシュした・pane が閉じられた場合はこのループでは検知できない（`herdr agent list` から消えるだけで、上記条件のどちらにも当たらない）。長時間ログが動かない場合は `herdr agent get issue-<番号>` で手動確認する。

## 完了後の定型処理

1. `gh pr view <番号> --json body -q .body` で PR 本文を確認する。
2. 複数 Issue でファイル所有権を明記していた場合、`gh pr view <番号> --json files` で diff が担当範囲に収まっているか確認する。
3. dev サーバ URL を `curl -sk -o /dev/null -w '%{http_code}'` で叩き 200 を確認する。
4. Chrome で該当画面を開く。
5. ユーザーへ報告する。含める要素:
   - PR 番号とリンク
   - 規模（追加削除行数・変更ファイル数）
   - 採った設計判断
   - 検証結果（テスト・E2E・レビュー）
   - 切り出されたフォローアップ Issue
   - 他 PR とのコンフリクト注意点

## 引数

- Issue 番号（複数可。例: `dispatch-goal 463 468`）
- タブ名（省略可。省略時は既存タブ流用 or 新規作成）
- モデル（省略可。既定 `sonnet`）

## よくあるミス

| ミス | 正しい形 |
|---|---|
| goal セッションの完了判定に `herdr agent wait` を使う | herdr skill の並列 golden path は goal 自走セッションには適用しない。PR 出現 / `blocked` のポーリングを使う |
| 固定プロンプトを要約・意訳して送る | 逐語のまま送る。`{issue番号}` 以外は変えない |
| `/rename` を送り忘れる、または送信をためらう | working 中でも安全に送れる。ホスト側追跡のため必ず送る |
| 依存 PR の確認を飛ばして着手する | Issue 本文の「前提」節を必ず確認してからでないと着手しない |
| `/rename` 後の名前で `herdr agent get` を呼ぶ | ポーリング対象は `agent start` に渡した名前（`issue-<番号>`）のまま。`/rename` は別の名前空間 |
| 複数 Issue 間のファイル衝突を確認せずに並列起動する | 各 Issue 本文を読み、対象ファイル・機能領域の重なりを事前確認する。重なる場合は「前提」節に所有権を明記するか直列化を提案する |
| ポーリングループを `run_in_background: true` を付けずに実行する | foreground の長時間 `sleep` はブロックされる。必ず `run_in_background: true` で起動する |
