-- =====================================================================
-- JEJAK - Dokumen PKL: guru bimbingan boleh MELIHAT (hanya baca)
-- Jalankan SETELAH schema-jejak-7-dokumen.sql.
-- Pakai TAB QUERY BARU di SQL Editor, tempel seluruh isi file, lalu Run.
-- Aman dijalankan ulang.
--
-- Hasil akhir:
--   Siswa : melihat, menambah, dan menghapus dokumen miliknya.
--   Guru  : hanya MELIHAT dokumen siswa bimbingannya (tidak bisa mengubah).
--   Siswa lain dan admin : tidak bisa melihat.
-- =====================================================================

-- 1. Tambah jenis "bukti kegiatan"
alter table public.documents drop constraint if exists documents_category_check;
alter table public.documents add constraint documents_category_check
  check (category in ('sertifikat', 'raport', 'penilaian', 'surat', 'laporan', 'bukti', 'lainnya'));

-- 2. Aturan baca tabel dokumen: pemilik atau guru bimbingan
drop policy if exists "dok_baca" on public.documents;
create policy "dok_baca" on public.documents for select to authenticated
using (public.siswa_saya(student_id) or public.siswa_bimbingan(student_id));

-- 3. Aturan baca file dokumen: pemilik atau guru bimbingan
drop policy if exists "dokfile_baca" on storage.objects;
create policy "dokfile_baca" on storage.objects for select to authenticated
using (
  bucket_id = 'dokumen-pkl'
  and (public.siswa_saya(((storage.foldername(name))[1])::uuid)
       or public.siswa_bimbingan(((storage.foldername(name))[1])::uuid))
);

-- 4. Pemeriksaan: harus muncul 2 baris (dok_baca dan dokfile_baca), keduanya SELECT
select tablename, policyname, cmd
from pg_policies
where policyname in ('dok_baca', 'dokfile_baca')
order by policyname;
