-- =====================================================================
-- JEJAK - Langkah 7: uji cepat aturan akses (RLS)
-- Pakai TAB QUERY BARU, tempel seluruh isi file, lalu Run.
-- Hasil akhir: tabel kecil berisi 5 baris (siswa1, siswa2, guru1, guru2, admin),
-- yang menunjukkan berapa data yang BISA DILIHAT tiap akun.
-- Boleh dijalankan ulang. Data contoh (jurnal) hanya dibuat sekali.
-- =====================================================================

-- 1. Data contoh: 1 jurnal untuk tiap siswa (kalau belum ada)
insert into public.journals (student_id, activity_title, activity_description, what_learned, understanding_level)
select st.id, 'Jurnal contoh ' || p.full_name, 'Kegiatan contoh', 'Pelajaran contoh', 'cukup'
from public.students st
join public.profiles p on p.id = st.profile_id
where not exists (select 1 from public.journals j where j.student_id = st.id);

-- 2. Tabel sementara untuk menampung hasil uji
drop table if exists pg_temp.hasil;
create temp table hasil (pengguna text, profil int, siswa int, absen int, jurnal int);
grant all on hasil to authenticated;

-- 3. Uji sebagai siswa1
select set_config('request.jwt.claims', json_build_object('sub', (select id::text from auth.users where email = 'siswa1.jejak@example.com'), 'role', 'authenticated')::text, true);
set local role authenticated;
insert into hasil select 'siswa1', (select count(*) from public.profiles), (select count(*) from public.students), (select count(*) from public.attendance), (select count(*) from public.journals);
reset role;

-- 4. Uji sebagai siswa2
select set_config('request.jwt.claims', json_build_object('sub', (select id::text from auth.users where email = 'siswa2.jejak@example.com'), 'role', 'authenticated')::text, true);
set local role authenticated;
insert into hasil select 'siswa2', (select count(*) from public.profiles), (select count(*) from public.students), (select count(*) from public.attendance), (select count(*) from public.journals);
reset role;

-- 5. Uji sebagai guru1
select set_config('request.jwt.claims', json_build_object('sub', (select id::text from auth.users where email = 'guru1.jejak@example.com'), 'role', 'authenticated')::text, true);
set local role authenticated;
insert into hasil select 'guru1', (select count(*) from public.profiles), (select count(*) from public.students), (select count(*) from public.attendance), (select count(*) from public.journals);
reset role;

-- 6. Uji sebagai guru2
select set_config('request.jwt.claims', json_build_object('sub', (select id::text from auth.users where email = 'guru2.jejak@example.com'), 'role', 'authenticated')::text, true);
set local role authenticated;
insert into hasil select 'guru2', (select count(*) from public.profiles), (select count(*) from public.students), (select count(*) from public.attendance), (select count(*) from public.journals);
reset role;

-- 7. Uji sebagai admin
select set_config('request.jwt.claims', json_build_object('sub', (select id::text from auth.users where email = 'admin.jejak@example.com'), 'role', 'authenticated')::text, true);
set local role authenticated;
insert into hasil select 'admin', (select count(*) from public.profiles), (select count(*) from public.students), (select count(*) from public.attendance), (select count(*) from public.journals);
reset role;

-- 8. Tampilkan hasil
select * from hasil order by pengguna;
