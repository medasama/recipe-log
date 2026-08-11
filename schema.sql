-- recipe-log: Supabase schema
-- 何度実行しても安全(冪等)な書き方にしています。

-- 1) テーブル作成
create table if not exists "recipe-log" (
  id text primary key,
  datetime timestamptz not null,
  title text,
  comment text,
  photo text
);

-- 2) RLSを有効化
alter table "recipe-log" enable row level security;

-- 3) anon/publishable key で全操作(SELECT/INSERT/UPDATE/DELETE)を許可するポリシー
drop policy if exists "recipe-log_anon_all" on "recipe-log";
create policy "recipe-log_anon_all"
  on "recipe-log"
  for all
  to anon
  using (true)
  with check (true);

-- 4) UPDATE/DELETE時にRealtimeへ完全な行情報を送るための設定
alter table "recipe-log" replica identity full;

-- 5) Realtime publication へテーブルを追加(重複追加によるエラーを回避)
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'recipe-log'
  ) then
    alter publication supabase_realtime add table "recipe-log";
  end if;
end $$;
