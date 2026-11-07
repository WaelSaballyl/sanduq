-- صندوقي: انسخ هذا كله والصقه في Supabase > SQL Editor > Run

create table if not exists public.items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users on delete cascade,
  kind text not null check (kind in ('text', 'file')),
  body text,
  file_path text,
  file_name text,
  file_size bigint,
  mime text,
  device text,
  created_at timestamptz not null default now()
);

alter table public.items enable row level security;

drop policy if exists "own items" on public.items;
create policy "own items" on public.items
  for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

grant select, insert, update, delete on public.items to authenticated;

-- التحديث اللحظي بين الأجهزة
alter publication supabase_realtime add table public.items;

-- مخزن الملفات (خاص، حد الملف 50MB وهو حد الخطة المجانية)
insert into storage.buckets (id, name, public, file_size_limit)
values ('files', 'files', false, 52428800)
on conflict (id) do nothing;

drop policy if exists "own files read" on storage.objects;
create policy "own files read" on storage.objects
  for select to authenticated
  using (bucket_id = 'files' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "own files insert" on storage.objects;
create policy "own files insert" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'files' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "own files delete" on storage.objects;
create policy "own files delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'files' and (storage.foldername(name))[1] = auth.uid()::text);
