-- =====================================================================
-- JEJAK - Arsip dokumen PKL (sertifikat, raport, lembar penilaian, dll.)
-- Pakai TAB QUERY BARU di SQL Editor, tempel seluruh isi file, lalu Run.
-- Aman dijalankan ulang.
--
-- Dokumen bersifat PRIVAT: hanya siswa pemilik yang bisa melihatnya
-- (raport dan nilai tidak terlihat oleh siswa lain, guru, maupun admin).
-- CATATAN: kalau suatu hari file schema-jejak-3-rls.sql dijalankan ulang,
-- jalankan file ini sekali lagi (file itu menghapus semua aturan lama).
-- =====================================================================

-- 1. Tabel dokumen
create table if not exists public.documents (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  document_name text not null,
  category text not null check (category in ('sertifikat', 'raport', 'penilaian', 'surat', 'laporan', 'lainnya')),
  file_path text not null,
  mime_type text,
  description text,
  document_date date,
  created_at timestamptz not null default now()
);

alter table public.documents enable row level security;
revoke all on public.documents from anon;
grant select, insert, update, delete on public.documents to authenticated;

drop policy if exists "dok_baca" on public.documents;
drop policy if exists "dok_tambah" on public.documents;
drop policy if exists "dok_ubah" on public.documents;
drop policy if exists "dok_hapus" on public.documents;

create policy "dok_baca" on public.documents for select to authenticated
using (public.siswa_saya(student_id));
create policy "dok_tambah" on public.documents for insert to authenticated
with check (public.siswa_saya(student_id));
create policy "dok_ubah" on public.documents for update to authenticated
using (public.siswa_saya(student_id)) with check (public.siswa_saya(student_id));
create policy "dok_hapus" on public.documents for delete to authenticated
using (public.siswa_saya(student_id));

-- 2. Bucket privat: JPEG atau PDF, maksimal 5 MB
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('dokumen-pkl', 'dokumen-pkl', false, 5242880, array['image/jpeg', 'application/pdf'])
on conflict (id) do update
  set public = false, file_size_limit = 5242880, allowed_mime_types = array['image/jpeg', 'application/pdf'];

-- 3. Aturan akses file: folder pertama = id siswa pemilik
drop policy if exists "dokfile_baca" on storage.objects;
drop policy if exists "dokfile_unggah" on storage.objects;
drop policy if exists "dokfile_hapus" on storage.objects;

create policy "dokfile_baca" on storage.objects for select to authenticated
using (bucket_id = 'dokumen-pkl' and public.siswa_saya(((storage.foldername(name))[1])::uuid));
create policy "dokfile_unggah" on storage.objects for insert to authenticated
with check (bucket_id = 'dokumen-pkl' and public.siswa_saya(((storage.foldername(name))[1])::uuid));
create policy "dokfile_hapus" on storage.objects for delete to authenticated
using (bucket_id = 'dokumen-pkl' and public.siswa_saya(((storage.foldername(name))[1])::uuid));

-- 4. Pemeriksaan: tabel_ada = 1, bucket_privat = 1, aturan_tabel = 4, aturan_file = 3
select
  (select count(*) from information_schema.tables where table_schema = 'public' and table_name = 'documents') as tabel_ada,
  (select count(*) from storage.buckets where id = 'dokumen-pkl' and public = false) as bucket_privat,
  (select count(*) from pg_policies where schemaname = 'public' and tablename = 'documents') as aturan_tabel,
  (select count(*) from pg_policies where schemaname = 'storage' and policyname like 'dokfile_%') as aturan_file;
