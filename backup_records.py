#!/usr/bin/env python3
"""
チーム記録ツール（Supabase）の全データを、手元のMacにバックアップする。

使い方（ターミナルで）:
    python3 backup_records.py

・backups/ フォルダに YYYYMMDD_バックアップ/ を作り、
  メンバー・記録・大会設定を CSV（Excelで開ける）と JSON で保存する。
・削除済み（画面から隠した）記録も含めて全部保存する。
・backups/ はGitHubに上げない設定（.gitignore）にしてある。
  リポジトリは公開されているため、メンバーの記録を載せないように。
"""

import csv
import datetime
import json
import os
import urllib.request

SUPABASE_URL = "https://jbqrgsctbxuhclupzxqo.supabase.co"
SUPABASE_KEY = "sb_publishable_ZeWiEErJromXkmt0WQgZbw_UYcayrB0"
TABLES = {
    "members": "members?select=*&order=name",
    "records": "records?select=*&order=date",
    "race_config": "race_config?select=*",
}


def fetch(path):
    req = urllib.request.Request(
        SUPABASE_URL + "/rest/v1/" + path,
        headers={"apikey": SUPABASE_KEY, "Authorization": "Bearer " + SUPABASE_KEY},
    )
    with urllib.request.urlopen(req) as res:
        return json.loads(res.read().decode())


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    today = datetime.date.today().strftime("%Y%m%d")
    out_dir = os.path.join(here, "backups", today + "_バックアップ")
    os.makedirs(out_dir, exist_ok=True)

    for name, path in TABLES.items():
        rows = fetch(path)
        with open(os.path.join(out_dir, name + ".json"), "w", encoding="utf-8") as f:
            json.dump(rows, f, ensure_ascii=False, indent=2)
        if rows:
            # utf-8-sig にするとExcelで開いても文字化けしない
            with open(os.path.join(out_dir, name + ".csv"), "w", encoding="utf-8-sig", newline="") as f:
                w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
                w.writeheader()
                w.writerows(rows)
        print("{}：{}件".format(name, len(rows)))

    print("\n保存先：" + out_dir)


if __name__ == "__main__":
    main()
