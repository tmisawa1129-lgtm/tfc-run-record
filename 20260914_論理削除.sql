-- 20260914 論理削除（消しても戻せる）対応
-- Supabaseの「SQL Editor」に全部貼り付けて Run する。何度実行しても問題ない。

-- 記録に「削除した日時」の列を足す（空＝削除されていない）
alter table records add column if not exists deleted_at timestamptz;

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
