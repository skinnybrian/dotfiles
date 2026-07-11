## ローカル開発サーバー（portless）

- web プロジェクトの dev server は `portless run` 経由で起動する（`dev` script があれば `portless run` だけでよい。例: `portless run npm run dev`）。ポート番号ではなく `https://<プロジェクト名>.localhost` でアクセスする
- linked git worktree ではブランチ名（最終セグメント）が自動でサブドメインになる（例: `https://feature-auth.myapp.localhost`）。起動中の URL は statusline に 🌐 で表示される
- portless 未インストール環境（Android Linux 等）では従来どおり起動する（`command -v portless` で確認）
- 死んだルートが残っていたら `portless prune` で掃除する
- **devサーバーのプロセスをkillする前に、必ず `portless list` で対象appのPIDを確認し、そのPIDだけをkillする。** `ps aux | grep <worktreeパス>` のような自前の文字列一致でPIDを洗い出すと、たまたまそのパスをコマンドライン上に含む**共有リバースプロキシ本体**（`lsof` では `localhost:phrelaydbg` のような固定サービス名でLISTEN、全アプリ共通の入り口）まで巻き込んで一緒にkillしてしまうことがあり、その場合そのマシン上の**全portlessアプリのURLが一斉に502/接続不可**になる。誤って共有プロキシを落とした場合は `portless proxy start --port <既存のポート番号> --https` で復旧できる（生きている各devサーバーは自動的に再登録される。個別再起動は不要）。`portless proxy stop` は共有プロキシ全体を止めるコマンドなので、単一アプリの停止目的では使わない。
