-- 20260922 宿題の記録（どの宿題をやったか・レベル・補強）に対応する
-- Supabaseの「SQL Editor」に全部貼り付けて Run する。何度実行しても問題ない。

-- 1) 記録に「宿題のどれか」を持たせる（long=ロング走 / easy=ゆっくりラン / other=それ以外。空＝未選択の古い記録）
alter table records add column if not exists menu text;
alter table records drop constraint if exists records_menu_check;
alter table records add constraint records_menu_check check (menu is null or menu in ('long','easy','other'));

-- 2) メンバーに宿題のレベルを持たせる（空＝まだ選んでいない）
alter table members add column if not exists level text;
alter table members drop constraint if exists members_level_check;
alter table members add constraint members_level_check check (level is null or level in ('ライト','スタンダード','チャレンジ'));

-- 3) 補強（走らないので距離などがない）は別の表に「やった日」だけ記録する
create table if not exists strength_logs (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references members(id),
  date date not null,
  deleted_at timestamptz,          -- 削除した日時（空＝表示中）。記録と同じく本当には消さない
  created_at timestamptz not null default now()
);
alter table strength_logs enable row level security;

-- 読む・追加・更新だけ許可（本当の削除はできない。記録・メンバーと同じ方針）
drop policy if exists "anon select strength_logs" on strength_logs;
drop policy if exists "anon insert strength_logs" on strength_logs;
drop policy if exists "anon update strength_logs" on strength_logs;
create policy "anon select strength_logs" on strength_logs for select using (true);
create policy "anon insert strength_logs" on strength_logs for insert with check (true);
create policy "anon update strength_logs" on strength_logs for update using (true) with check (true);

-- 4) 平均心拍を任意にする（入力の手間を減らすため。2026-09-22 本人と合意）
alter table records alter column heart_rate drop not null;
