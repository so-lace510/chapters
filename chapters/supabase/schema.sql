-- Run this once in Supabase → SQL Editor.

create table public.experiences (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid()
                references auth.users (id) on delete cascade,
  title       text not null,
  body        text not null,
  media_path  text,
  media_type  text check (media_type in ('image', 'video')),
  happened_on date not null default current_date,
  created_at  timestamptz not null default now()
);

create index experiences_user_date_idx
  on public.experiences (user_id, happened_on desc);

-- Each person can only see and change their own entries.
alter table public.experiences enable row level security;

create policy "read own experiences" on public.experiences
  for select using (auth.uid() = user_id);
create policy "add own experiences" on public.experiences
  for insert with check (auth.uid() = user_id);
create policy "edit own experiences" on public.experiences
  for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "delete own experiences" on public.experiences
  for delete using (auth.uid() = user_id);

-- Private bucket for photos and videos. Files live in a folder named
-- after the user's id, and the policies only allow access to that folder.
insert into storage.buckets (id, name, public)
values ('experience-media', 'experience-media', false)
on conflict (id) do nothing;

create policy "read own media" on storage.objects
  for select using (
    bucket_id = 'experience-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
create policy "upload own media" on storage.objects
  for insert with check (
    bucket_id = 'experience-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
create policy "delete own media" on storage.objects
  for delete using (
    bucket_id = 'experience-media'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
