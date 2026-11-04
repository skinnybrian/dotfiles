#!/usr/bin/env python3
"""reply-language-guard.py — Stop hook

返答が日本語になっているかを機械で見る（グローバル CLAUDE.md「言語」を守らせる）。
直近の返答（最後のユーザーの発言より後のアシスタントの文）と、その最後のメッセージのそれぞれで、
日本語の文字（ひらがな・カタカナ・漢字）が英字の MAX_RATIO 倍に満たず、英字が MIN_LATIN 字以上あれば、
止めて日本語で書き直させる。

「日本語が 1 文字も無い」ではなく割合で見るのは、英語の返答の末尾に必ず付ける日本語の 1 行
（※ 本回答は参考情報… など）が混ざっても見落とさないため。2026-11-04 に過去の返答 1,622 件で測り、
英語の返答は 0.026 以下、日本語の返答は 0.04 以上だった。

- stop_hook_active が真なら何もしない（書き直しが繰り返されるのを防ぐ）
- コードブロック・インラインコード・URL は数えない。JSON だけの返答（{ か [ で始まる）と、
  Claude Code 自身のエラー文（API Error・You've hit your …）は見ない
- 環境変数 REPLY_LANGUAGE_GUARD=off で止められる（英語で返させたい自動実行など）
- 入力が読めない・壊れているときは何もしない（exit 0）
"""
import json
import os
import re
import sys

MIN_LATIN = 80
MAX_RATIO = 0.05
REASON = (
    "返答のほとんどが英語になっている（日本語の文字が英字の 5% 未満）。"
    "グローバル CLAUDE.md「言語」のとおり、同じ内容を日本語で書き直して返す"
    "（コード・コマンド・識別子は原語のまま）。"
)


def is_real_user(entry):
    if entry.get("isMeta"):
        return False
    content = (entry.get("message") or {}).get("content")
    if isinstance(content, str):
        return True
    if isinstance(content, list):
        return any(isinstance(c, dict) and c.get("type") == "text" for c in content)
    return False


def last_turn_texts(path):
    """(ターン全体の文, 最後のメッセージの文) を返す"""
    turn, last = [], []
    with open(path, encoding="utf-8") as f:
        for line in f:
            try:
                entry = json.loads(line)
            except ValueError:
                continue
            if entry.get("isSidechain"):
                continue
            kind = entry.get("type")
            if kind == "user" and is_real_user(entry):
                turn, last = [], []
            elif kind == "assistant":
                content = (entry.get("message") or {}).get("content")
                if isinstance(content, list):
                    found = [c.get("text", "") for c in content if isinstance(c, dict) and c.get("type") == "text"]
                    if found:
                        turn += found
                        last = found
    return "\n".join(turn), "\n".join(last)


def needs_japanese(text):
    if not isinstance(text, str):
        return False
    body = re.sub(r"```.*?```", " ", text, flags=re.S)
    body = re.sub(r"`[^`\n]*`", " ", body)
    body = re.sub(r"https?://\S+", " ", body).strip()
    if not body or body[0] in "{[" or body.startswith(("API Error", "You've hit your")):
        return False
    japanese = len(re.findall(r"[぀-ヿ㐀-鿿]", body))
    latin = len(re.findall(r"[A-Za-z]", body))
    return latin >= MIN_LATIN and japanese < latin * MAX_RATIO


def main():
    if os.environ.get("REPLY_LANGUAGE_GUARD") == "off":
        return
    data = json.load(sys.stdin)
    if data.get("stop_hook_active"):
        return
    last = data.get("last_assistant_message")
    turn = ""
    path = data.get("transcript_path")
    if path and os.path.isfile(path):
        turn, from_transcript = last_turn_texts(path)
        if not isinstance(last, str) or not last:
            last = from_transcript
    if needs_japanese(last) or needs_japanese(turn):
        print(json.dumps({"decision": "block", "reason": REASON}, ensure_ascii=False))


if __name__ == "__main__":
    try:
        main()
    except Exception:
        pass
    sys.exit(0)
