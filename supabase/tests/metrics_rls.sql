begin;
truncate attendance,training,performance,recruitment,employees cascade;
insert into auth.users(id) values('00000000-0000-0000-0000-000000000001');
insert into employees(id,nama,gender,tgl_lahir,departemen,jabatan,tgl_masuk,tgl_keluar,status,gaji_pokok) values
('10000000-0000-0000-0000-000000000001','Sintetis A','Perempuan','1990-01-01','SDM','Staf','2020-01-01',null,'aktif',5000000),
('10000000-0000-0000-0000-000000000002','Sintetis B','Laki-laki','1990-01-01','SDM','Staf','2020-01-01','2026-01-16','keluar',5000000);
insert into attendance(employee_id,tanggal,status) values
('10000000-0000-0000-0000-000000000001','2026-01-02','hadir'),
('10000000-0000-0000-0000-000000000001','2026-01-03','telat'),
('10000000-0000-0000-0000-000000000001','2026-01-04','cuti'),
('10000000-0000-0000-0000-000000000001','2026-01-05','alpa');
insert into recruitment(posisi,departemen,sumber,tgl_buka,tgl_terisi,jumlah_pelamar) values
('Staf','SDM','Kampus','2026-01-01','2026-01-11',10),('Staf','SDM','Portal','2026-01-01','2026-01-21',20);
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',true);
set local role authenticated;
do $$declare j jsonb;n int;begin
if is_hr_admin() then raise exception 'Viewer memperoleh admin'; end if;
j:=rpc_turnover('2026-01-01','2026-01-31',null);
if abs((j->'bulanan'->0->>'nilai')::numeric-66.67)>0.01 then raise exception 'Turnover salah: %',j;end if;
if abs((j->'departemen'->0->>'nilai')::numeric-66.67)>0.01 then raise exception 'Turnover departemen salah';end if;
j:=rpc_absensi('2026-01-01','2026-01-31',null);
if (j->>'tingkat_kehadiran')::numeric<>50 then raise exception 'Kehadiran salah';end if;
if (j->>'tingkat_keterlambatan')::numeric<>25 then raise exception 'Keterlambatan salah';end if;
j:=rpc_rekrutmen('2026-01-01','2026-01-31',null);
if (j->>'time_to_hire_hari')::numeric<>15 then raise exception 'Time-to-hire salah';end if;
if (j->>'jumlah_pelamar')::numeric<>30 then raise exception 'Pelamar salah';end if;
j:=rpc_ringkasan('2026-01-01','2026-01-31','Teknologi');
if (j->>'total_aktif')::numeric<>0 then raise exception 'Filter departemen gagal';end if;
begin insert into employees(nama,gender,tgl_lahir,departemen,jabatan,tgl_masuk,status,gaji_pokok) values('Dilarang','Perempuan','1990-01-01','SDM','Staf','2020-01-01','aktif',1);raise exception 'Viewer INSERT lolos';exception when insufficient_privilege then null;end;
update employees set nama='Dilarang';get diagnostics n=row_count;if n<>0 then raise exception 'Viewer UPDATE lolos';end if;
delete from employees;get diagnostics n=row_count;if n<>0 then raise exception 'Viewer DELETE lolos';end if;
begin update profiles set role='hr_admin';get diagnostics n=row_count;if n<>0 then raise exception 'Viewer eskalasi role lolos';end if;exception when insufficient_privilege then null;end;
if exists(select 1 from audit_log)then raise exception 'Viewer dapat membaca audit';end if;
begin if exists(select 1 from ai_cache)then raise exception 'Viewer dapat membaca cache';end if;exception when insufficient_privilege then null;end;
begin perform admit_ai(auth.uid());raise exception 'Viewer dapat melewati limiter';exception when insufficient_privilege then null;end;
end$$;
reset role;
rollback;
