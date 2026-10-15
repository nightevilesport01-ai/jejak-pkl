-- =====================================================================
-- JEJAK - Portofolio ringkas (satu halaman, bisa dicetak)
-- Pakai TAB QUERY BARU di SQL Editor, tempel seluruh isi file, lalu Run.
-- Aman dijalankan ulang.
--
-- Portofolio bersifat PRIVAT: hanya siswa pemilik yang bisa membaca dan mengubah.
-- Tidak ada tautan publik.
-- =====================================================================

create table if not exists public.portfolios (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null unique references public.students(id) on delete cascade,
  tentang text,
  capaian text,
  keterampilan text,
  kontak text,
  jurnal_ids uuid[] not null default '{}',
  foto_ids uuid[] not null default '{}',
  updated_at timestamptz not null default now()
);

alter table public.portfolios enable row level security;
revoke all on public.portfolios from anon;
grant select, insert, update, delete on public.portfolios to authenticated;

drop policy if exists "porto_baca" on public.portfolios;
drop policy if exists "porto_tambah" on public.portfolios;
drop policy if exists "porto_ubah" on public.portfolios;
drop policy if exists "porto_hapus" on public.portfolios;

create policy "porto_baca" on public.portfolios for select to authenticated
using (public.siswa_saya(student_id));
create policy "porto_tambah" on public.portfolios for insert to authenticated
with check (public.siswa_saya(student_id));
create policy "porto_ubah" on public.portfolios for update to authenticated
using (public.siswa_saya(student_id)) with check (public.siswa_saya(student_id));
create policy "porto_hapus" on public.portfolios for delete to authenticated
using (public.siswa_saya(student_id));

-- Pemeriksaan: tabel_portofolio_ada = 1 dan aturan_portofolio = 4
select
  (select count(*) from information_schema.tables where table_schema = 'public' and table_name = 'portfolios') as tabel_portofolio_ada,
  (select count(*) from pg_policies where schemaname = 'public' and tablename = 'portfolios') as aturan_portofolio;
