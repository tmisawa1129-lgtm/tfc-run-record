#!/usr/bin/env python3
"""
ラン記録_マスター.csv → チーム記録ツール（Supabase）へ tetsu の記録を同期する。

使い方（ターミナルで）:
    python3 sync_tetsu.py            # 新しい記録を追加する
    python3 sync_tetsu.py --dry-run  # 追加せず、何が追加されるかだけ表示する

・すでに登録済みの記録（日付＋距離が一致）は自動でスキップするので、
  何度実行しても二重登録にはならない。
・心拍が記録されていない行は、チーム記録ツール側で心拍が必須項目のためスキップする。
"""

import csv
import json
import re
import sys
import urllib.request

CSV_PATH = "/Users/mt/Documents/Claude Code/ランニング記録/2_記録データ/ラン記録_マスター.csv"
SUPABASE_URL = "https://jbqrgsctbxuhclupzxqo.supabase.co"
SUPABASE_KEY = "sb_publishable_ZeWiEErJromXkmt0WQgZbw_UYcayrB0"
MEMBER_ID = "c6b96a03-9810-44c5-b77d-beb801d7c3c2"  # tetsu

HEADERS = {
    "apikey": SUPABASE_KEY,
    "Authorization": "Bearer " + SUPABASE_KEY,
    "Content-Type": "application/json",
}


def api(path, method="GET", body=None, extra_headers=None):
    headers = dict(HEADERS)
    if extra_headers:
        headers.update(extra_headers)
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(
        SUPABASE_URL + "/rest/v1/" + path, data=data, headers=headers, method=method
    )
    with urllib.request.urlopen(req) as res:
        text = res.read().decode()
        return json.loads(text) if text.strip() else None


def is_number(s):
    return bool(s) and re.fullmatch(r"[0-9]+(\.[0-9]+)?", s.strip())


def to_int(s):
    s = (s or "").strip()
    return int(float(s)) if is_number(s) else None


def convert_pace(s):
    """7'48\" のような表記を 7:48 に直す（チーム記録ツール側の書式に合わせる）"""
    s = (s or "").strip()
    m = re.match(r"(\d+)'(\d+)", s)
    return "{}:{}".format(m.group(1), m.group(2).zfill(2)) if m else s


def read_csv_rows():
    rows = []
    with open(CSV_PATH, encoding="utf-8") as f:
        for r in csv.DictReader(f):
            date_raw = (r.get("日付") or "").strip()
            if len(date_raw) != 8:
                continue
            hr = to_int(r.get("平均心拍"))
            if hr is None:
                rows.append({"skip": "心拍なし", "date": date_raw})
                continue

            # このCSVは行によって「備考」と「Zone2秒」の中身が入れ替わっていることがある。
            # 備考が数値だけ かつ Zone2秒が文章なら、入れ替わりとみなして直す。
            memo = (r.get("備考") or "").strip()
            zone2 = (r.get("Zone2秒") or "").strip()
            if is_number(memo) and zone2 and not is_number(zone2):
                memo = zone2

            rows.append({
                "date": "{}-{}-{}".format(date_raw[:4], date_raw[4:6], date_raw[6:]),
                "distance_km": float(r["距離km"]),
                "duration_text": (r.get("時間") or "").strip(),
                "pace_text": convert_pace(r.get("平均ペース")),
                "heart_rate": hr,
                "cadence": to_int(r.get("ピッチ表示値")),
                "ground_contact_ms": to_int(r.get("接地時間ms")),
                "rpe": None,
                "memo": memo or None,
            })
    return rows


def main():
    dry_run = "--dry-run" in sys.argv

    existing = api(
        "records?member_id=eq.{}&select=date,distance_km".format(MEMBER_ID)
    )
    known = {(e["date"], round(float(e["distance_km"]), 2)) for e in existing}
    print("Supabase側の既存記録：{}件".format(len(existing)))

    new_rows, skipped = [], []
    for row in read_csv_rows():
        if row.get("skip"):
            skipped.append(row)
            continue
        if (row["date"], round(row["distance_km"], 2)) in known:
            continue
        new_rows.append(row)

    for row in skipped:
        print("スキップ：{}（{}）".format(row["date"], row["skip"]))

    if not new_rows:
        print("追加する記録はありません（すべて同期済み）。")
        return

    print("追加する記録：{}件".format(len(new_rows)))
    for row in new_rows:
        print("  {} {:>6.2f}km {:>7} ペース{:>6} 心拍{}".format(
            row["date"], row["distance_km"], row["duration_text"],
            row["pace_text"], row["heart_rate"]))

    if dry_run:
        print("\n--dry-run のため、実際の追加は行っていません。")
        return

    payload = [dict(row, member_id=MEMBER_ID) for row in new_rows]
    api("records", method="POST", body=payload,
        extra_headers={"Prefer": "return=minimal"})
    print("\n追加しました。")

    after = api("records?member_id=eq.{}&select=id".format(MEMBER_ID))
    print("同期後の合計：{}件".format(len(after)))


if __name__ == "__main__":
    main()
