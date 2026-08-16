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
/goal #{issue番号}を実装する。superpowers:brainstorming → superpowers:writing-plans → superpowers:subagent-driven-development の順で進める。worktreeを必ず切ること。spec/planが完成するまでの間にユーザへ選択を求める場面が出たら、都度確認せず自分が推奨する選択肢を選んで進める。spec/planの作成が完了したら、そこから先もユーザ確認を求めず最後まで実装を進めてよい。実装完了後はPRを作成し、mainへのマージは行わず、serveスキルでdevサーバを起動してから終了すること。
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

**`blocked` には2種類ある**: `agent_status=blocked` を検知しても即座に「要確認」として扱わない。まず `herdr agent read <名前> --source recent-unwrapped --lines 50` で理由を分類する。

- **タスク上の質問**（承認待ち・選択肢提示）→ 人間の判断が要る。ポーリングを終了しユーザーへ回す
- **利用上限**（pane に `session limit` / `Upgrade your plan` という文字列が出る）→ 判断不要。下記の自動再開シーケンスに入る

```bash
repo="<owner>/<repo>"
issues=(463 468)
declare -A resolved
declare -A resume_at
resume_prompt="利用上限で中断していたはず。plan/ledgerを読み直して、どのタスクの直後で止まったか確認し、そこから続けて。テストや実装が中途半端なタスクがあれば完了させてから次へ進む。最後まで完走したらPRを作成し、mainへのマージは行わず、serveスキルでdevサーバを起動してから終了すること。"

get_resets_at() {
  local read_out="$1" target="" mtime now hh ap tz hh24
  if [ -f ~/.claude/rate_limits.json ]; then
    mtime=$(stat -f %m ~/.claude/rate_limits.json 2>/dev/null || echo 0)
    now=$(date +%s)
    if [ $((now - mtime)) -lt 600 ]; then
      target=$(jq -r 'if ((.seven_day.used_percentage // 0) >= 95 and (.five_hour.used_percentage // 0) < 95) then .seven_day.resets_at else .five_hour.resets_at end // empty' ~/.claude/rate_limits.json 2>/dev/null)
    fi
  fi
  if [ -z "$target" ]; then
    hh=$(echo "$read_out" | grep -oE 'resets [0-9]{1,2}(am|pm)' | head -1 | grep -oE '[0-9]{1,2}')
    ap=$(echo "$read_out" | grep -oE 'resets [0-9]{1,2}(am|pm)' | head -1 | grep -oE '(am|pm)')
    tz=$(echo "$read_out" | grep -oE '\([A-Za-z_]+/[A-Za-z_]+\)' | head -1 | tr -d '()')
    if [ -n "$hh" ] && [ -n "$ap" ] && [ -n "$tz" ]; then
      hh24=$hh
      [ "$ap" = "pm" ] && [ "$hh" != "12" ] && hh24=$((hh + 12))
      [ "$ap" = "am" ] && [ "$hh" = "12" ] && hh24=0
      target=$(TZ="$tz" date -j -f "%Y-%m-%d %H:%M:%S" "$(TZ="$tz" date +%Y-%m-%d) $(printf '%02d' "$hh24"):00:00" +%s 2>/dev/null)
      [ -n "$target" ] && [ "$target" -le "$(date +%s)" ] && target=$((target + 86400))
    fi
  fi
  echo "$target"
}

while true; do
  prs=$(gh pr list --repo "$repo" --state open --json number,headRefName --limit 100)
  now=$(date +%s)
  for n in "${issues[@]}"; do
    [ -n "${resolved[$n]:-}" ] && continue
    pr=$(jq -r --arg p "feature/$n-" \
      '.[] | select((.headRefName == ($p|rtrimstr("-"))) or (.headRefName | startswith($p))) | .number' \
      <<< "$prs" | head -1)
    if [ -n "$pr" ]; then
      echo "issue-$n: PR #$pr が立った"; resolved[$n]=1; continue
    fi
    astatus=$(herdr agent get "issue-$n" 2>/dev/null | jq -r '.result.agent.agent_status // empty')
    if [ "$astatus" != "blocked" ]; then
      unset 'resume_at[$n]'
      continue
    fi
    if [ -n "${resume_at[$n]:-}" ]; then
      [ "$now" -lt "${resume_at[$n]}" ] && continue
      astatus2="$astatus"
      if [ "$astatus2" = "blocked" ]; then
        herdr agent send-keys "issue-$n" esc
        sleep 3
        astatus2=$(herdr agent get "issue-$n" 2>/dev/null | jq -r '.result.agent.agent_status // empty')
      fi
      if [ "$astatus2" = "working" ]; then
        echo "issue-$n: リセット後 working を確認、自動再開済み"
      elif [ -z "$astatus2" ]; then
        echo "issue-$n: agent が見つからない（クラッシュ/pane閉鎖の可能性）"; resolved[$n]=1
      elif [ "$astatus2" = "blocked" ]; then
        echo "issue-$n: esc後もblockedのまま。想定外のダイアログの可能性。要確認"; resolved[$n]=1
      else
        herdr agent send-keys "issue-$n" ctrl+u
        herdr agent prompt "issue-$n" "$resume_prompt"
        echo "issue-$n: 再開プロンプトを送信した"
      fi
      unset 'resume_at[$n]'
      continue
    fi
    read_out=$(herdr agent read "issue-$n" --source recent-unwrapped --lines 50 2>/dev/null)
    if echo "$read_out" | grep -qi "session limit\|Upgrade your plan"; then
      target=$(get_resets_at "$read_out")
      if [ -n "$target" ]; then
        resume_at[$n]=$((target + 120))
        echo "issue-$n: 利用上限を検知。$(date -r "${resume_at[$n]}") 頃に自動再開を試みる"
      else
        echo "issue-$n: 利用上限だが resets_at が取得できない。要確認"; resolved[$n]=1
      fi
    else
      echo "issue-$n: agent_status=blocked（要確認・タスク上の質問の可能性）"; resolved[$n]=1
    fi
  done
  [ "${#resolved[@]}" -eq "${#issues[@]}" ] && break
  sleep 60
done
echo "全Issue完了（PR出現 or blocked=要確認）"
```

このスクリプトを Bash tool の `run_in_background: true` で起動する（実装ボリューム次第で数時間かかることがあるため）。全 Issue が解決してループが終了すると完了通知が届く。ブランチ名フィルタは `feature/<番号>-` の末尾ハイフンまで含めて誤マッチ（`feature/4630-...` 等）を防ぐ。

**利用上限からの自動再開（実証済み手順、上のスクリプトの実装根拠）**:

1. 再開予定時刻に到達したら、まず `agent_status` を再確認する。まだ `blocked` のときだけ `herdr agent send-keys <名前> esc` でダイアログを閉じる。子セッションが自動で復帰していたら `esc` は不要かつ危険（working 中に送ると実行中のタスクを中断させてしまう）
2. `herdr agent get <名前>` で状態を見る。**`working` に戻っていれば自動で続きを再開している**（実運用で2セッション中1つはこれで復帰した）
3. `idle` / `done` のままなら再開プロンプトを送る。**送信前に `herdr agent send-keys <名前> ctrl+u` で入力欄をクリアする**こと。esc 後に入力欄へ古いテキストが残っていたケースがあり、そのまま送ると文字列が連結されて壊れる（実際に残骸「Task 1が終わるまで待ってて」が残っていた）
4. 再開プロンプトは「plan/ledger を読み直して、止まっていたタスクの続きから最後まで完走する」ことを指示する（スクリプト内 `resume_prompt` 参照）。子セッションは自身の ledger から続きを判断できる

中断してもコミット済みの成果は失われない。**worktree を消さない限り安全**。

**再開予定時刻（resets_at）の取得**: pane のテキストに `You have hit your session limit · resets 11pm (Asia/Tokyo)` のように時刻とタイムゾーンが出るが、**セッションが再開するとスクロールで流れて読めなくなる**ため、blocked 検知のその場（`herdr agent read` した瞬間）で保存する必要がある。より堅いソースとして、statusline に渡る JSON payload に `rate_limits.five_hour.resets_at` / `seven_day.resets_at`（Unix epoch秒）が入っている。`~/dotfiles/claude/statusline.py` はこれを毎回 `~/.claude/rate_limits.json` に永続化するため、上記スクリプトは次の優先順で取得する:

1. `~/.claude/rate_limits.json` の mtime が10分以内なら、`seven_day.used_percentage` が95%以上かつ `five_hour.used_percentage` が95%未満のときだけ `seven_day.resets_at` を使い、それ以外は `five_hour.resets_at` を使う（account 全体で共有される利用上限のため、blocked になった子セッション自身の描画でなくても有効）
2. 古い/存在しない場合は、分類時に読んだ pane テキストから `resets <時刻>(am|pm) (<TZ>)` を正規表現で抜き、その日の該当時刻に変換する（既に過去なら+1日）。この経路は `five_hour`/`seven_day` の区別ができないため `five_hour` 相当（直近の時刻）とみなす
3. どちらも取れない場合は自動再開を諦め、「要確認（resets_at不明）」として人間に投げる

pane テキストのフォールバック経路では引き続き `five_hour`/`seven_day` の区別がつかないため、誤って短い方の窓で待ってしまうことはありうる。その場合（リセット後もまだ `blocked`）は次の周回で再分類され、そのときは recorder が新しい値を反映しているはずなので正しい方の resets_at で再度待つ — **誤判定は致命的にならない**（再入可能な設計）。`resume_at` に足す120秒のバッファは、リセット時刻ちょうどに再開を試みると子セッション側の状態反映が間に合わないことがあるための安全マージン。

**既知の制約**:
- エージェントがクラッシュした・pane が閉じられた場合はこのループでは検知できない（`herdr agent list` から消えるだけで、上記条件のどちらにも当たらない）。長時間ログが動かない場合は `herdr agent get issue-<番号>` で手動確認する
- `rate_limits.json` は Claude Code のドキュメント化されていない内部フィールドに依存する（確認済みバージョン: 2.1.233）。将来変わる可能性があり、その場合は pane テキストのフォールバックに自動で切り替わる（それも崩れたら手動再開手順に頼る）

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
| `blocked` を検知したら即座に「要確認」として人間に投げる | まず `herdr agent read` で理由を分類する。「session limit」「Upgrade your plan」なら利用上限＝判断不要、それ以外はタスク上の質問＝要確認 |
| 利用上限からの再開で `esc` を無条件で送る | 再開予定時刻到達後、まず `agent_status` を再確認し、まだ `blocked` のときだけ `esc` を送る。`working` なら子セッションが自動再開済みなので何もしない |
| 再開プロンプト送信前に入力欄をクリアしない | `herdr agent send-keys <名前> ctrl+u` でクリアしてから送る。esc 後に古い入力テキストが残っていることがあり、そのまま送ると連結されて壊れる |
