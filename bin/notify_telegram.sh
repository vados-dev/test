#!/usr/bin/env bash

msg=${1:-no message}

if [[ "${DRY_RUN:-0}" == "1" ]]; then
  echo "[notify][dry-run] $msg"
  exit 0
fi

if [[ -z "${BOT_TOKEN:-}" || -z "${CHAT_ID:-}" ]]; then
  echo "[notify] BOT_TOKEN/CHAT_ID not set, skip"
  exit 0
fi
#echo "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage?chat_id=${CHAT_ID}&text=$msg&parse_mode=$TGParseMode&disable_web_page_preview=$TGDisableWebPagePreview"
#exit 0
curl -fsS --connect-timeout 5 --max-time 10 \
  -X POST "https://api.telegram.org/bot"${BOT_TOKEN}"/sendMessage" \
  -d "chat_id=${CHAT_ID}" \
  -d "parse_mode=html" \
  -d "disable_web_page_preview=True" \
  --data-urlencode "text=${msg}"
  # >/dev/null
# || true
