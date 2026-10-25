-- Private raster-only buckets. Signed read links require authenticated SELECT.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values
('company-assets','company-assets',false,2097152,array['image/png','image/jpeg','image/webp']),
('avatars','avatars',false,2097152,array['image/png','image/jpeg','image/webp'])
on conflict(id) do update set public=false,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;
create policy hr_media_read on storage.objects for select to authenticated using(bucket_id in ('company-assets','avatars'));
create policy hr_logo_insert on storage.objects for insert to authenticated with check(bucket_id='company-assets' and public.is_hr_admin() and name ~ '^company/[a-f0-9-]+\.(png|jpg|webp)$');
create policy hr_logo_update on storage.objects for update to authenticated using(bucket_id='company-assets' and public.is_hr_admin()) with check(bucket_id='company-assets' and public.is_hr_admin() and name ~ '^company/[a-f0-9-]+\.(png|jpg|webp)$');
create policy hr_logo_delete on storage.objects for delete to authenticated using(bucket_id='company-assets' and public.is_hr_admin());
create policy hr_avatar_insert on storage.objects for insert to authenticated with check(bucket_id='avatars' and name ~ ('^'||auth.uid()::text||'/[a-f0-9-]+\.(png|jpg|webp)$'));
create policy hr_avatar_update on storage.objects for update to authenticated using(bucket_id='avatars' and split_part(name,'/',1)=auth.uid()::text) with check(bucket_id='avatars' and name ~ ('^'||auth.uid()::text||'/[a-f0-9-]+\.(png|jpg|webp)$'));
create policy hr_avatar_delete on storage.objects for delete to authenticated using(bucket_id='avatars' and split_part(name,'/',1)=auth.uid()::text);
