-- Replace the storage policies from the previous schema with these stricter policies.
-- Run after the original schema, or use this block in a fresh project.
drop policy if exists "users upload own photos" on storage.objects;
drop policy if exists "users manage own photos" on storage.objects;
drop policy if exists "authenticated view approved photos" on storage.objects;

create policy "users upload own photos" on storage.objects for insert to authenticated
with check (bucket_id = 'profile-photos' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "users manage own photos" on storage.objects for delete to authenticated
using (bucket_id = 'profile-photos' and ((storage.foldername(name))[1] = auth.uid()::text or public.is_admin()));

create policy "owners admins view photos" on storage.objects for select to authenticated
using (
  bucket_id = 'profile-photos'
  and ((storage.foldername(name))[1] = auth.uid()::text
    or public.is_admin()
    or exists (
      select 1 from public.profiles p
      where p.id::text = (storage.foldername(name))[1]
        and p.status = 'approved'
    ))
);
