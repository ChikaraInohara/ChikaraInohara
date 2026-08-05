#!/usr/bin/env bash
# 連続コミット日数のカード（streak）だけを取ってきて assets/ に置く。
#
# 🔴 **取れなかったら、前回のファイルをそのまま残す。**
# 上書きして壊すくらいなら、少し古い数字が出ている方がよい。
# このスクリプトが失敗しても README は表示され続ける、という状態を守る。
#
# ⚠️ 数字そのもの（コミット数・スター・言語）は、このスクリプトでは取らない。
# github-readme-stats の公開インスタンスが **継続的に 503** を返していて、
# 取り込み元として使えないため。そちらは GitHub Actions の中で
# 自前生成する（`.github/workflows/stats.yml`）。
# streak だけは自前生成の対象に無いので、ここで取り込んでいる。

set -uo pipefail

USER_NAME="chikarainohara"
OUT_DIR="assets"
ATTEMPTS=4
WAIT_SECONDS=20

mkdir -p "$OUT_DIR"

NAME="streak"
URL="https://github-readme-streak-stats.herokuapp.com?user=${USER_NAME}&locale=en&mode=daily&theme=dark&hide_border=false&border_radius=5"
TARGET="${OUT_DIR}/${NAME}.svg"

# 中身がカードとして成立しているか。
# ⚠️ 公開インスタンスは **200 のままエラーの絵を返す**ことがある。
# HTTPコードだけ見ていると、エラー画像で上書きしてしまう
valid_card() {
  local file="$1"
  [ -s "$file" ] || return 1
  [ "$(wc -c <"$file")" -gt 1000 ] || return 1
  grep -q "<svg" "$file" || return 1
  # ⚠️ 単語 "error" だけで弾かない。言語名やリポジトリ名に入りうる。
  # 実際にエラーの絵に出る文言だけを見る
  grep -qi "Maximum retries exceeded\|Something went wrong\|rate limit\|Could not fetch\|Bad credentials\|user not found" "$file" && return 1
  return 0
}

tmp="$(mktemp)"
for attempt in $(seq 1 "$ATTEMPTS"); do
  code="$(curl -sS -m 30 -o "$tmp" -w "%{http_code}" "$URL" || echo 000)"
  if [ "$code" = "200" ] && valid_card "$tmp"; then
    mv "$tmp" "$TARGET"
    echo "✅ ${NAME}: 更新した"
    exit 0
  fi
  echo "  ${NAME}: ${attempt}回目は取れず（HTTP ${code}）"
  sleep "$WAIT_SECONDS"
done

rm -f "$tmp"
if [ -f "$TARGET" ]; then
  echo "⚠️  ${NAME}: 取れなかった。前回のファイルを残す"
  # 🔴 ここで失敗にしない。前回のカードで README は成立している
  exit 0
fi

echo "🔴 ${NAME}: 取れず、前回のファイルも無い"
exit 1
