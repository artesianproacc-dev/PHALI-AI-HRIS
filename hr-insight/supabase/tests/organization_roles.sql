begin;
insert into auth.users(id) values
('20000000-0000-0000-0000-000000000001'),('20000000-0000-0000-0000-000000000002'),
('20000000-0000-0000-0000-000000000003'),('20000000-0000-0000-0000-000000000004');
update profiles set role=case right(id::text,1) when '1' then 'hr_admin' when '2' then 'hr_staff' when '3' then 'manager' else 'viewer' end where id::text like '20000000%';
select set_config('request.jwt.claim.sub','20000000-0000-0000-0000-000000000001',true);
set local role authenticated;
do $$declare n int;denied boolean:=false;begin
update organization_settings set nama='Perusahaan Uji Sintetis',alamat='Alamat Sintetis';get diagnostics n=row_count;if n<>1 then raise exception 'Admin gagal mengubah organisasi';end if;
perform set_user_role('20000000-0000-0000-0000-000000000002','manager');
if(select role from profiles where id='20000000-0000-0000-0000-000000000002')<>'manager' then raise exception 'Perubahan peran gagal';end if;
perform set_user_role('20000000-0000-0000-0000-000000000002','hr_staff');
begin perform set_user_role(auth.uid(),'viewer');exception when raise_exception then denied:=true;end;if not denied then raise exception 'Admin dapat menurunkan peran sendiri';end if;
insert into storage.objects(bucket_id,name) values('company-assets','company/11111111-1111-1111-1111-111111111111.png');
end$$;
reset role;
select set_config('request.jwt.claim.sub','20000000-0000-0000-0000-000000000002',true);
set local role authenticated;
do $$declare n int;begin
if not can_manage_hr() or is_hr_admin() then raise exception 'Hak Staf HR salah';end if;
insert into employees(id,nama,gender,tgl_lahir,departemen,jabatan,tgl_masuk,status,gaji_pokok) values('30000000-0000-0000-0000-000000000001','Uji Staf HR','Perempuan','1990-01-01','SDM','Staf','2020-01-01','aktif',1);
update employees set jabatan='Spesialis' where id='30000000-0000-0000-0000-000000000001';get diagnostics n=row_count;if n<>1 then raise exception 'Staf gagal update HR';end if;
delete from employees where id='30000000-0000-0000-0000-000000000001';get diagnostics n=row_count;if n<>1 then raise exception 'Staf gagal delete HR';end if;
update organization_settings set nama='Dilarang';get diagnostics n=row_count;if n<>0 then raise exception 'Staf mengubah organisasi';end if;
begin perform set_user_role('20000000-0000-0000-0000-000000000004','hr_admin');raise exception 'Staf dapat mengubah peran';exception when insufficient_privilege then null;end;
begin insert into storage.objects(bucket_id,name) values('company-assets','company/22222222-2222-2222-2222-222222222222.png');raise exception 'Staf dapat mengganti logo';exception when insufficient_privilege then null;end;
insert into storage.objects(bucket_id,name) values('avatars','20000000-0000-0000-0000-000000000002/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa.jpg');
perform update_my_profile('Nama Staf Sintetis','20000000-0000-0000-0000-000000000002/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa.jpg');
if(select nama from profiles where id=auth.uid())<>'Nama Staf Sintetis' then raise exception 'Profil sendiri gagal diperbarui';end if;
if(select role from profiles where id=auth.uid())<>'hr_staff' then raise exception 'Update profil mengubah peran';end if;
end$$;
reset role;
select set_config('request.jwt.claim.sub','20000000-0000-0000-0000-000000000003',true);
set local role authenticated;
do $$declare n int;begin
if can_manage_hr() then raise exception 'Manajer memperoleh tulis HR';end if;
begin insert into employees(nama,gender,tgl_lahir,departemen,jabatan,tgl_masuk,status,gaji_pokok) values('Dilarang','Perempuan','1990-01-01','SDM','Staf','2020-01-01','aktif',1);raise exception 'Manajer INSERT lolos';exception when insufficient_privilege then null;end;
update organization_settings set nama='Dilarang';get diagnostics n=row_count;if n<>0 then raise exception 'Manajer mengubah perusahaan';end if;
-- Another user's image cannot be overwritten, deleted, or attached to this profile.
begin insert into storage.objects(bucket_id,name) values('avatars','20000000-0000-0000-0000-000000000002/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb.png');raise exception 'Unggah foto orang lain lolos';exception when insufficient_privilege then null;end;
update storage.objects set name='20000000-0000-0000-0000-000000000003/cccccccc-cccc-cccc-cccc-cccccccccccc.png' where bucket_id='avatars' and name like '20000000-0000-0000-0000-000000000002/%';get diagnostics n=row_count;if n<>0 then raise exception 'Overwrite foto orang lain lolos';end if;
delete from storage.objects where bucket_id='avatars' and name like '20000000-0000-0000-0000-000000000002/%';get diagnostics n=row_count;if n<>0 then raise exception 'Hapus foto orang lain lolos';end if;
end$$;
reset role;
select set_config('request.jwt.claim.sub','20000000-0000-0000-0000-000000000004',true);
set local role authenticated;
do $$declare n int;denied boolean:=false;begin
if not exists(select 1 from organization_settings where nama='Perusahaan Uji Sintetis') then raise exception 'Pengamat gagal membaca perusahaan';end if;
perform update_my_profile('Pengamat Sintetis',null);
begin perform update_my_profile('Pengamat Sintetis','20000000-0000-0000-0000-000000000002/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa.jpg');exception when raise_exception then denied:=true;end;if not denied then raise exception 'Pengamat memasang foto milik orang lain';end if;
begin update profiles set role='hr_admin' where id=auth.uid();raise exception 'Eskalasi peran langsung lolos';exception when insufficient_privilege then null;end;
begin perform set_user_role(auth.uid(),'hr_admin');raise exception 'Eskalasi lewat RPC lolos';exception when insufficient_privilege then null;end;
delete from storage.objects where bucket_id='company-assets';get diagnostics n=row_count;if n<>0 then raise exception 'Pengamat menghapus logo';end if;
end$$;
reset role;
rollback;
