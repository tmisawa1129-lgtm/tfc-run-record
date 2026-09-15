-- THE FULL CREW チーム記録ツール — Supabaseテーブル定義
-- Supabaseの「SQL Editor」にこのファイルの中身を全部貼り付けて実行してください。
-- （手順の詳細は 20260906_セットアップ手順.md を参照）

-- メンバー（名前だけで識別する。本格的な認証はなし）
create table if not exists members (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  role text not null default 'member' check (role in ('member', 'coach')),
  created_at timestamptz not null default now()
);

-- 1件ずつの練習記録
create table if not exists records (
  id uuid primary key default gen_random_uuid(),
  member_id uuid not null references members(id) on delete cascade,
  date date not null,
  distance_km numeric not null,
  duration_text text not null,
  pace_text text not null,
  heart_rate integer not null,
  cadence integer,
  ground_contact_ms integer,
  rpe integer check (rpe between 1 and 10),
  memo text,
  deleted_at timestamptz,  -- 削除した日時（空＝表示中）。削除は画面から隠すだけで、あとで戻せる
  created_at timestamptz not null default now()
);

-- 目標大会（1行だけ使う共有設定）
create table if not exists race_config (
  id int primary key default 1,
  race_name text not null default '第74回 勝田全国マラソン',
  race_date date not null default '2027-01-31',
  target_distance_km numeric not null default 42.195,
  updated_at timestamptz not null default now()
);
insert into race_config (id) values (1) on conflict (id) do nothing;

-- 行レベルセキュリティ（RLS）を有効化
alter table members enable row level security;
alter table records enable row level security;
alter table race_config enable row level security;

-- このツールは名前を選ぶだけの本人確認しか行わず、
-- Supabase自体のログイン機能は使いません。そのためアクセスキー（anon key）を
-- 持っている人（＝チームメンバー）は誰でも読み書きできる設定にしています。
-- 少人数の信頼できるチーム内での利用を前提とした割り切りです。
-- ただし「本当の削除」は許可しない（2026-09-14変更。記録の削除は deleted_at を入れて隠す）
-- アプリのキーでは「本当の削除」をできないようにする（読む・追加・更新だけ許可）
drop policy if exists "anon full access records" on records;
drop policy if exists "anon select records" on records;
drop policy if exists "anon insert records" on records;
drop policy if exists "anon update records" on records;
create policy "anon select records" on records for select using (true);
create policy "anon insert records" on records for insert with check (true);
create policy "anon update records" on records for update using (true) with check (true);

-- メンバーを消すと記録も一緒に消えるため、メンバーも削除不可にする
drop policy if exists "anon full access members" on members;
drop policy if exists "anon select members" on members;
drop policy if exists "anon insert members" on members;
drop policy if exists "anon update members" on members;
create policy "anon select members" on members for select using (true);
create policy "anon insert members" on members for insert with check (true);
create policy "anon update members" on members for update using (true) with check (true);

-- 大会設定も読む・更新だけ
drop policy if exists "anon full access race_config" on race_config;
drop policy if exists "anon select race_config" on race_config;
drop policy if exists "anon update race_config" on race_config;
create policy "anon select race_config" on race_config for select using (true);
create policy "anon update race_config" on race_config for update using (true) with check (true);
