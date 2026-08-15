#!/usr/bin/env bash
set -euo pipefail

direction="${1:?Usage: $(basename "$0") left|right}"

: "${HERDR_SOCKET_PATH:?This command must run from Herdr}"
: "${HERDR_ACTIVE_WORKSPACE_ID:?This command must run from Herdr}"
: "${HERDR_ACTIVE_TAB_ID:?This command must run from Herdr}"

request() {
  printf '%s\n' "$1" | nc -U "$HERDR_SOCKET_PATH"
}

tabs_response="$(request "$(jq -cn \
  --arg workspace_id "$HERDR_ACTIVE_WORKSPACE_ID" \
  '{id: "key:tab:list", method: "tab.list", params: {workspace_id: $workspace_id}}')")"
current_index="$(jq -er --arg tab_id "$HERDR_ACTIVE_TAB_ID" \
  '.result.tabs | map(.tab_id) | index($tab_id)' <<<"$tabs_response")"
tab_count="$(jq -er '.result.tabs | length' <<<"$tabs_response")"

case "$direction" in
  left)
    if ((current_index == 0)); then
      target_index="$tab_count"
    else
      target_index=$((current_index - 1))
    fi
    ;;
  # Herdr applies insert_index before removing the source tab. Moving right
  # therefore needs to insert two positions ahead to advance by one.
  right)
    if ((current_index == tab_count - 1)); then
      target_index=0
    else
      target_index=$((current_index + 2))
    fi
    ;;
  *)
    printf 'Unknown direction: %s\n' "$direction" >&2
    exit 2
    ;;
esac

request "$(jq -cn \
  --arg tab_id "$HERDR_ACTIVE_TAB_ID" \
  --argjson insert_index "$target_index" \
  '{id: "key:tab:move", method: "tab.move", params: {tab_id: $tab_id, insert_index: $insert_index}}')" \
  >/dev/null
