-- =====================================================================
-- JEJAK - Jadwal kerja per siswa + status "libur"
-- Pakai TAB QUERY BARU di SQL Editor, tempel seluruh isi file, lalu Run.
-- Aman dijalankan ulang.
--
-- jadwal_kerja menentukan hari yang dihitung di Daftar Hadir cetak:
--   senin_jumat = Senin sampai Jumat (bawaan)
--   senin_sabtu = Senin sampai Sabtu (tempat PKL yang masuk hari Sabtu)
--   setiap_hari = Senin sampai Minggu
-- Cara mengubah untuk satu siswa: Table Editor > tabel students > klik sel
-- kolom jadwal_kerja pada siswa itu > ketik salah satu nilai di atas > Save.
-- =====================================================================

alter table public.students
  add column if not exists jadwal_kerja text not null default 'senin_jumat';

alter table public.students drop constraint if exists students_jadwal_kerja_check;
alter table public.students
  add constraint students_jadwal_kerja_check
  check (jadwal_kerja in ('senin_jumat', 'senin_sabtu', 'setiap_hari'));

-- Status kehadiran: tambah "libur" (dicatat oleh guru untuk libur nasional atau libur perusahaan)
alter table public.attendance drop constraint if exists attendance_status_check;
alter table public.attendance
  add constraint attendance_status_check
  check (status in ('hadir', 'izin', 'sakit', 'alpa', 'libur'));

-- Pemeriksaan: tiap siswa tampil dengan jadwal_kerja
select p.full_name, st.jadwal_kerja
from public.students st
join public.profiles p on p.id = st.profile_id
order by p.full_name;
