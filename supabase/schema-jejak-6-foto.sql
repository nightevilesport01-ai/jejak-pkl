-- =====================================================================
-- JEJAK - Foto / bukti kegiatan (Storage)
-- Pakai TAB QUERY BARU di SQL Editor, tempel seluruh isi file, lalu Run.
-- Aman dijalankan ulang.
--
-- Bucket "bukti-jurnal" bersifat PRIVAT (foto tidak bisa dibuka lewat link umum).
-- Foto disimpan di folder: <id siswa>/<id jurnal>/<nama acak>.jpg
--   Siswa : boleh mengunggah, melihat, dan menghapus foto di folder miliknya.
--   Guru  : hanya boleh melihat foto siswa bimbingannya.
-- =====================================================================

-- 1. Bucket privat, hanya menerima JPEG, maksimal 3 MB (foto dikecilkan otomatis oleh aplikasi)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('bukti-jurnal', 'bukti-jurnal', false, 3145728, array['image/jpeg'])
on conflict (id) do update
  set public = false, file_size_limit = 3145728, allowed_mime_types = array['image/jpeg'];

-- 2. Aturan akses (dibuat ulang supaya aman dijalankan lagi)
drop policy if exists "bukti_baca" on storage.objects;
drop policy if exists "bukti_unggah" on storage.objects;
drop policy if exists "bukti_hapus" on storage.objects;

create policy "bukti_baca" on storage.objects for select to authenticated
using (
  bucket_id = 'bukti-jurnal'
  and (public.siswa_saya(((storage.foldername(name))[1])::uuid)
       or public.siswa_bimbingan(((storage.foldername(name))[1])::uuid))
);

create policy "bukti_unggah" on storage.objects for insert to authenticated
with check (
  bucket_id = 'bukti-jurnal'
  and public.siswa_saya(((storage.foldername(name))[1])::uuid)
);

create policy "bukti_hapus" on storage.objects for delete to authenticated
using (
  bucket_id = 'bukti-jurnal'
  and public.siswa_saya(((storage.foldername(name))[1])::uuid)
);

-- 3. Pemeriksaan: bucket_ada = 1, bucket_privat = 1, aturan_ada = 3
select
  (select count(*) from storage.buckets where id = 'bukti-jurnal') as bucket_ada,
  (select count(*) from storage.buckets where id = 'bukti-jurnal' and public = false) as bucket_privat,
  (select count(*) from pg_policies where schemaname = 'storage' and policyname like 'bukti_%') as aturan_ada;
