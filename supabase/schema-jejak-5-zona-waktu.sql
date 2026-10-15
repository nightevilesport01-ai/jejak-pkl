-- =====================================================================
-- JEJAK - Zona waktu per siswa (untuk siswa yang PKL di luar Sorong)
-- Pakai TAB QUERY BARU di SQL Editor, tempel seluruh isi file, lalu Run.
-- Aman dijalankan ulang.
--
-- Pilihan zona waktu:
--   Asia/Jayapura = WIT  (Sorong dan sekitarnya, bawaan)
--   Asia/Makassar = WITA
--   Asia/Jakarta  = WIB
-- Cara mengubah untuk satu siswa: Table Editor > tabel students > klik sel
-- kolom zona_waktu pada siswa itu > ketik salah satu nilai di atas > Save.
-- =====================================================================

alter table public.students
  add column if not exists zona_waktu text not null default 'Asia/Jayapura';

alter table public.students drop constraint if exists students_zona_waktu_check;
alter table public.students
  add constraint students_zona_waktu_check
  check (zona_waktu in ('Asia/Jayapura', 'Asia/Makassar', 'Asia/Jakarta'));

-- Pemeriksaan: tiap siswa harus tampil dengan zona_waktu
select p.full_name, st.zona_waktu
from public.students st
join public.profiles p on p.id = st.profile_id
order by p.full_name;
