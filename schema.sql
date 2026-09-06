-- THE FULL CREW チーム記録ツール — Supabaseテーブル定義
-- Supabaseの「SQL Editor」にこのファイルの中身を全部貼り付けて実行してください。
-- （手順の詳細は 20260906_セットアップ手順.md を参照）

-- メンバー（名前とPINでゆるく本人確認する）
create table if not exists members (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  pin text not null,
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

-- このツールは「名前＋簡単なPIN」による軽い本人確認だけを想定しており、
-- Supabase自体のログイン機能は使いません。そのためアクセスキー（anon key）を
-- 持っている人（＝チームメンバー）は誰でも読み書きできる設定にしています。
-- 少人数の信頼できるチーム内での利用を前提とした割り切りです。
drop policy if exists "anon full access members" on members;
create policy "anon full access members" on members for all using (true) with check (true);

drop policy if exists "anon full access records" on records;
create policy "anon full access records" on records for all using (true) with check (true);

drop policy if exists "anon full access race_config" on race_config;
create policy "anon full access race_config" on race_config for all using (true) with check (true);
