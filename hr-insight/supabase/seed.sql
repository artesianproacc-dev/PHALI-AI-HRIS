-- Synthetic reproducible data; destructive reset only for this synthetic dataset.
begin;
select setseed(0.42);
truncate training,performance,attendance,recruitment,employees cascade;
insert into employees(id,nama,gender,tgl_lahir,departemen,jabatan,tgl_masuk,tgl_keluar,alasan_keluar,gaji_pokok,status)
select md5('hr-demo-'||i)::uuid,'Karyawan Sintetis '||lpad(i::text,3,'0'),case when random()<0.5 then 'Perempuan' else 'Laki-laki' end,date '1972-01-01'+(random()*12000)::int,(array['SDM','Teknologi','Keuangan','Pemasaran','Operasional','Penjualan','Legal','Layanan Pelanggan'])[1+(i%8)],(array['Staf','Spesialis','Manajer'])[1+(i%3)],date '2017-01-01'+(random()*3100)::int,case when i%10=0 then date '2026-01-01'+(random()*270)::int end,case when i%10=0 then (array['Karier','Kompensasi','Pribadi'])[1+(i%3)] end,(4500000+floor(random()*150)*100000),case when i%10=0 then 'keluar' else 'aktif' end from generate_series(1,300)i;
insert into attendance(employee_id,tanggal,status,jam_lembur)
select e.id,d::date,case when r<0.03 then 'alpa' when r<0.08 then 'cuti' when r<0.12 then 'izin' when r<0.24 then 'telat' else 'hadir' end,case when r>0.8 then 2 else 0 end from employees e cross join generate_series(date '2025-10-01',date '2026-09-30',interval '1 day')d cross join lateral(select random()+length(e.nama)*0+extract(day from d)*0 r)s where extract(isodow from d)<6 and d>=e.tgl_masuk and(e.tgl_keluar is null or d<e.tgl_keluar);
insert into recruitment(posisi,departemen,sumber,tgl_buka,tgl_terisi,jumlah_pelamar) select 'Staf '||i,(array['SDM','Teknologi','Keuangan','Pemasaran','Operasional','Penjualan','Legal','Layanan Pelanggan'])[1+i%8],(array['LinkedIn','Portal Kerja','Referensi','Kampus'])[1+i%4],date '2025-10-01'+i*5,case when i%7<>0 then date '2025-10-01'+i*5+14+i%30 end,20+(random()*150)::int from generate_series(1,65)i;
insert into performance(employee_id,periode,skor) select id,d,1+floor(random()*5) from employees cross join generate_series(date '2025-12-01',date '2026-09-01',interval '3 months')d where d>=tgl_masuk and(tgl_keluar is null or d<tgl_keluar);
insert into training(employee_id,nama_pelatihan,jam,tanggal) select id,'Kompetensi dan Kolaborasi',4+(random()*12)::int,greatest(tgl_masuk,date '2025-10-01')+floor(random()*(least(coalesce(tgl_keluar-1,date '2026-09-30'),date '2026-09-30')-greatest(tgl_masuk,date '2025-10-01')+1))::int from employees;
commit;
