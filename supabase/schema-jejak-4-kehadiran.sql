-- =====================================================================
-- JEJAK - Langkah 10 (Hari 3): jam pulang (check-out)
-- Pakai TAB QUERY BARU di SQL Editor, tempel seluruh isi file, lalu Run.
-- Aman dijalankan ulang.
--
-- Kenapa memakai fungsi? Siswa TIDAK diberi hak mengubah baris kehadiran
-- (supaya tidak bisa memalsukan jam masuk atau status). Jam pulang dicatat
-- lewat fungsi khusus yang hanya mengisi kolom check_out, memakai jam server.
-- =====================================================================

-- 1. Kolom jam pulang
alter table public.attendance add column if not exists check_out timestamptz;

-- 2. Fungsi check-out: hanya untuk siswa yang sudah check-in "hadir" HARI INI
create or replace function public.absen_pulang()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_siswa uuid;
  v_baris int;
begin
  select id into v_siswa from public.students where profile_id = auth.uid();
  if v_siswa is null then
    raise exception 'Akun ini bukan akun siswa.';
  end if;

  update public.attendance
     set check_out = now()
   where student_id = v_siswa
     and attendance_date = ((now() at time zone 'Asia/Jayapura')::date)
     and status = 'hadir'
     and check_out is null;

  get diagnostics v_baris = row_count;
  if v_baris = 0 then
    raise exception 'Belum check-in hari ini, atau kamu sudah check-out.';
  end if;
end;
$$;

revoke all on function public.absen_pulang() from public, anon;
grant execute on function public.absen_pulang() to authenticated;

-- 3. Pemeriksaan: harus muncul kolom check_out dan fungsi absen_pulang
select
  (select count(*) from information_schema.columns
     where table_schema = 'public' and table_name = 'attendance' and column_name = 'check_out') as kolom_check_out_ada,
  (select count(*) from pg_proc p join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'public' and p.proname = 'absen_pulang') as fungsi_absen_pulang_ada;
