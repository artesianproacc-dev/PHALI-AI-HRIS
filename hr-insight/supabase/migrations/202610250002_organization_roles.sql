-- One organization per installation; all domain data belongs to this workspace.
alter table public.profiles drop constraint profiles_role_check;
alter table public.profiles add constraint profiles_role_check check(role in ('hr_admin','hr_staff','manager','viewer'));
alter table public.profiles add column avatar_path text;
create table public.organization_settings (
 id integer primary key default 1 check(id=1),
 nama text not null default 'Organisasi Saya' check(length(trim(nama)) between 1 and 120),
 bidang text not null default '' check(length(bidang)<=120),
 email text not null default '' check(length(email)<=200),
 telepon text not null default '' check(length(telepon)<=40),
 alamat text not null default '' check(length(alamat)<=1000),
 website text not null default '' check(length(website)<=300 and (website='' or website ~ '^https?://')),
 logo_path text check(logo_path is null or logo_path ~ '^company/[a-f0-9-]+\.(png|jpg|webp)$'),
 zona_waktu text not null default 'Asia/Jakarta' check(zona_waktu in ('Asia/Jakarta','Asia/Makassar','Asia/Jayapura')),
 diperbarui_pada timestamptz not null default now()
);
insert into public.organization_settings(id) values(1);
alter table public.organization_settings enable row level security;
create policy organization_read on public.organization_settings for select to authenticated using(true);
create policy organization_update on public.organization_settings for update to authenticated using(public.is_hr_admin()) with check(public.is_hr_admin());
grant select,update on public.organization_settings to authenticated;
grant all on public.organization_settings to service_role;
create trigger audit_change after update on public.organization_settings for each row execute function public.audit_changes();
create function public.can_manage_hr() returns boolean language sql stable security definer set search_path=public as $$select exists(select 1 from profiles where id=auth.uid() and role in ('hr_admin','hr_staff'))$$;
do $$declare t text;begin foreach t in array array['employees','attendance','recruitment','performance','training'] loop
execute format('drop policy write_admin on public.%I',t);
execute format('create policy write_hr on public.%I for all to authenticated using(public.can_manage_hr()) with check(public.can_manage_hr())',t);
end loop;end$$;
-- All profile writes by users go through narrow RPCs, never a general UPDATE.
drop policy profiles_admin on public.profiles;
revoke insert,update,delete on public.profiles from authenticated,anon;
create function public.update_my_profile(p_nama text,p_avatar_path text default null) returns void language plpgsql security definer set search_path=public as $$begin
if auth.uid() is null then raise exception 'Silakan masuk kembali.';end if;
if p_nama is null or length(trim(p_nama)) not between 1 and 120 then raise exception 'Nama wajib diisi, maksimal 120 karakter.';end if;
if p_avatar_path is not null and (p_avatar_path !~ ('^'||auth.uid()::text||'/[a-f0-9-]+\.(png|jpg|webp)$')) then raise exception 'Lokasi foto profil tidak valid.';end if;
update public.profiles set nama=trim(p_nama),avatar_path=p_avatar_path where id=auth.uid();
if not found then raise exception 'Profil tidak tersedia.';end if;
end$$;
create function public.set_user_role(p_user_id uuid,p_role text) returns void language plpgsql security definer set search_path=public as $$declare old_role text;begin
perform pg_advisory_xact_lock(hashtextextended('hr-insight-role-management',0));
if not public.is_hr_admin() then raise exception 'Hanya Admin SDM yang dapat mengatur peran.' using errcode='42501';end if;
if p_user_id=auth.uid() then raise exception 'Peran Anda sendiri tidak dapat diubah. Minta Admin SDM lain untuk membantu.';end if;
if p_role is null or p_role not in ('hr_admin','hr_staff','manager','viewer') then raise exception 'Peran tidak valid.';end if;
select role into old_role from profiles where id=p_user_id for update;
if not found then raise exception 'Pengguna tidak ditemukan.';end if;
update profiles set role=p_role where id=p_user_id;
insert into audit_log(user_id,aksi,detail) values(auth.uid(),'ubah_peran',jsonb_build_object('target',p_user_id,'dari',old_role,'ke',p_role));
end$$;
revoke all on function public.update_my_profile(text,text),public.set_user_role(uuid,text) from public,anon;
grant execute on function public.update_my_profile(text,text),public.set_user_role(uuid,text) to authenticated;
