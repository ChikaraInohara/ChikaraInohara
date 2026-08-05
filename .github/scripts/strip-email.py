#!/usr/bin/env python3
"""生成されたカードから、公開メールアドレスの行を落とす。

🔴 カード生成器はプロフィールの公開メールアドレスを SVG に焼き込む。
プロフィールページに出ているものではあるが、**リポジトリの中の
ファイルとしてコミットされる**のは別の話で、履歴に残り、
クローンした人の手元にも残る。ここで落としておく。

⚠️ 消すのは1行と、その行のアイコンだけ。他は触らない。
アドレスが見つからなければ何もしない（生成器の作りが変わっても壊れない）。
"""

import re
import sys
from pathlib import Path

EMAIL_TEXT = re.compile(
    r'<text[^>]*\by="(?P<y>\d+)"[^>]*>[^<]*@[^<@\s]+\.[^<@\s]+</text>'
)

def strip(path: Path) -> bool:
    svg = path.read_text(encoding="utf-8")
    match = EMAIL_TEXT.search(svg)
    if not match:
        return False

    svg = svg[: match.start()] + svg[match.end() :]

    # 同じ行のアイコン。テキストのベースラインより 14px 上に置かれている。
    #
    # ⚠️ アイコンは **2重の <g> に包まれている**
    #   `<g class="gpsc-item" …><g transform="translate(0,84)" …><path/></g></g>`
    # 内側だけ消すと外側の閉じタグが余り、SVGが壊れて画像が出なくなる
    # （一度これをやって、カードが真っ黒になった）。包みごと消す。
    icon_y = int(match.group("y")) - 14
    icon = re.compile(
        r'<g[^>]*>\s*<g transform="translate\(0,%d\)"[^>]*>.*?</g>\s*</g>' % icon_y,
        re.DOTALL,
    )
    icon_match = icon.search(svg)
    if icon_match:
        svg = svg[: icon_match.start()] + svg[icon_match.end() :]
    else:
        print(f"  ⚠️ {path.name}: アイコンの位置が変わっている。文字だけ消した")

    path.write_text(svg, encoding="utf-8")
    return True


def main() -> int:
    targets = sorted(Path("profile-summary-card-output").rglob("0-profile-details.svg"))
    if not targets:
        print("カードが見つからない")
        return 1

    for target in targets:
        if strip(target):
            print(f"✅ {target}: メールアドレスの行を消した")
        else:
            print(f"   {target}: メールアドレスは入っていない")
    return 0


if __name__ == "__main__":
    sys.exit(main())
