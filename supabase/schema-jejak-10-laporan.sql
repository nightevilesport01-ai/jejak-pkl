-- =====================================================================
-- JEJAK - Laporan PKL: tabel isi laporan + kode program keahlian
-- Pakai TAB QUERY BARU di SQL Editor, tempel seluruh isi file, lalu Run.
-- Aman dijalankan ulang (bagian data contoh di langkah 3 hanya mengubah 2 siswa contoh).
--
-- Laporan bersifat PRIVAT: hanya siswa pemilik yang bisa membaca dan mengubah.
-- =====================================================================

-- 1. Kode program keahlian: menentukan warna sampul laporan
--    Pemasaran = merah, AKL = hijau, MPLB = kuning, TP = ungu, TJKT / PPLG / DKV = biru muda
alter table public.students add column if not exists program_kode text;
alter table public.students drop constraint if exists students_program_kode_check;
alter table public.students
  add constraint students_program_kode_check
  check (program_kode is null or program_kode in ('Pemasaran', 'AKL', 'MPLB', 'TP', 'TJKT', 'PPLG', 'DKV'));

-- 2. Tabel isi laporan (satu laporan per siswa)
create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null unique references public.students(id) on delete cascade,
  kata_pengantar text,
  latar_belakang text,
  tujuan text,
  rumusan_masalah text,
  profil_dunia_kerja text,
  hasil_pelaksanaan text,
  kesimpulan text,
  saran text,
  nip_pembimbing_sekolah text,
  nip_pembimbing_industri text,
  updated_at timestamptz not null default now()
);

alter table public.reports enable row level security;
revoke all on public.reports from anon;
grant select, insert, update, delete on public.reports to authenticated;

drop policy if exists "laporan_baca" on public.reports;
drop policy if exists "laporan_tambah" on public.reports;
drop policy if exists "laporan_ubah" on public.reports;
drop policy if exists "laporan_hapus" on public.reports;

create policy "laporan_baca" on public.reports for select to authenticated
using (public.siswa_saya(student_id));
create policy "laporan_tambah" on public.reports for insert to authenticated
with check (public.siswa_saya(student_id));
create policy "laporan_ubah" on public.reports for update to authenticated
using (public.siswa_saya(student_id)) with check (public.siswa_saya(student_id));
create policy "laporan_hapus" on public.reports for delete to authenticated
using (public.siswa_saya(student_id));

-- 3. Data contoh untuk demo (hanya 2 siswa contoh): Siswa Satu = TP (ungu), Siswa Dua = TJKT (biru muda)
update public.students set major = 'Teknik Perminyakan', program_kode = 'TP'
where profile_id = (select id from public.profiles where email = 'siswa1.jejak@example.com');
update public.students set major = 'Teknik Jaringan Komputer dan Telekomunikasi', program_kode = 'TJKT'
where profile_id = (select id from public.profiles where email = 'siswa2.jejak@example.com');

-- 4. Pemeriksaan: tabel_laporan_ada = 1, aturan_laporan = 4, dan 2 siswa tampil dengan program_kode
select
  (select count(*) from information_schema.tables where table_schema = 'public' and table_name = 'reports') as tabel_laporan_ada,
  (select count(*) from pg_policies where schemaname = 'public' and tablename = 'reports') as aturan_laporan,
  (select string_agg(p.full_name || ' = ' || coalesce(st.program_kode, '-'), ', ' order by p.full_name)
     from public.students st join public.profiles p on p.id = st.profile_id) as program_siswa;
