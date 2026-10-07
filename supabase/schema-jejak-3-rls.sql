-- =====================================================================
-- JEJAK - Langkah 6: aturan akses (Row Level Security) per role
-- Pakai TAB QUERY BARU di SQL Editor, tempel seluruh isi file, lalu Run.
-- Aman dijalankan ulang: aturan lama dihapus dulu, lalu dibuat lagi.
--
-- Ringkasan aturan:
--   Siswa : hanya data sendiri. Boleh absen (hadir/izin/sakit) untuk HARI INI,
--           buat dan ubah jurnal sendiri, unggah foto jurnal sendiri.
--   Guru  : hanya siswa bimbingannya. Boleh lihat jurnal, atur kehadiran
--           (termasuk Alpa), dan memberi feedback.
--   Admin : kelola profil, data siswa, dan kehadiran. Tidak membaca jurnal.
--   Orang tanpa login: tidak bisa mengakses apa pun.
-- =====================================================================

-- 0. Hapus aturan lama (supaya file ini bisa dijalankan ulang)
do $$
declare r record;
begin
  for r in select policyname, tablename from pg_policies where schemaname = 'public' loop
    execute format('drop policy %I on public.%I', r.policyname, r.tablename);
  end loop;
end $$;

-- 1. Fungsi bantu (dipakai oleh aturan di bawah)
create or replace function public.my_role()
returns text language sql stable security definer set search_path = public as $$
  select role from public.profiles where id = auth.uid()
$$;

-- apakah siswa ini adalah saya
create or replace function public.siswa_saya(sid uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.students where id = sid and profile_id = auth.uid())
$$;

-- apakah siswa ini bimbingan saya (sebagai guru)
create or replace function public.siswa_bimbingan(sid uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.students where id = sid and guru_id = auth.uid())
$$;

-- apakah jurnal ini milik saya
create or replace function public.jurnal_saya(jid uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.journals j
    join public.students s on s.id = j.student_id
    where j.id = jid and s.profile_id = auth.uid())
$$;

-- apakah jurnal ini milik siswa bimbingan saya
create or replace function public.jurnal_bimbingan(jid uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.journals j
    join public.students s on s.id = j.student_id
    where j.id = jid and s.guru_id = auth.uid())
$$;

-- apakah jurnal ini sudah punya feedback
create or replace function public.jurnal_ditanggapi(jid uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.feedback where journal_id = jid)
$$;

revoke all on function public.my_role() from public, anon;
revoke all on function public.siswa_saya(uuid) from public, anon;
revoke all on function public.siswa_bimbingan(uuid) from public, anon;
revoke all on function public.jurnal_saya(uuid) from public, anon;
revoke all on function public.jurnal_bimbingan(uuid) from public, anon;
revoke all on function public.jurnal_ditanggapi(uuid) from public, anon;
grant execute on function public.my_role() to authenticated;
grant execute on function public.siswa_saya(uuid) to authenticated;
grant execute on function public.siswa_bimbingan(uuid) to authenticated;
grant execute on function public.jurnal_saya(uuid) to authenticated;
grant execute on function public.jurnal_bimbingan(uuid) to authenticated;
grant execute on function public.jurnal_ditanggapi(uuid) to authenticated;

-- 2. Hak dasar: hanya pengguna yang sudah login. Orang tanpa login tidak diberi akses sama sekali.
revoke all on all tables in schema public from anon;
grant usage on schema public to authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;

-- 3. profiles
create policy "profiles_baca" on public.profiles for select to authenticated
using (
  id = auth.uid()
  or public.my_role() = 'admin'
  or exists (select 1 from public.students st where st.profile_id = profiles.id and st.guru_id = auth.uid())
  or exists (select 1 from public.students st where st.guru_id = profiles.id and st.profile_id = auth.uid())
);
create policy "profiles_admin_semua" on public.profiles for all to authenticated
using (public.my_role() = 'admin') with check (public.my_role() = 'admin');

-- 4. students
create policy "students_baca" on public.students for select to authenticated
using (profile_id = auth.uid() or guru_id = auth.uid() or public.my_role() = 'admin');
create policy "students_admin_semua" on public.students for all to authenticated
using (public.my_role() = 'admin') with check (public.my_role() = 'admin');

-- 5. attendance
create policy "absen_baca" on public.attendance for select to authenticated
using (public.siswa_saya(student_id) or public.siswa_bimbingan(student_id) or public.my_role() = 'admin');

create policy "absen_siswa_tambah" on public.attendance for insert to authenticated
with check (
  public.siswa_saya(student_id)
  and status in ('hadir', 'izin', 'sakit')
  and attendance_date = ((now() at time zone 'Asia/Jayapura')::date)
  and check_in between now() - interval '5 minutes' and now() + interval '5 minutes'
);

create policy "absen_guru_tambah" on public.attendance for insert to authenticated
with check (public.siswa_bimbingan(student_id));
create policy "absen_guru_ubah" on public.attendance for update to authenticated
using (public.siswa_bimbingan(student_id)) with check (public.siswa_bimbingan(student_id));

create policy "absen_admin_semua" on public.attendance for all to authenticated
using (public.my_role() = 'admin') with check (public.my_role() = 'admin');

-- 6. journals
create policy "jurnal_baca" on public.journals for select to authenticated
using (public.siswa_saya(student_id) or public.siswa_bimbingan(student_id));
create policy "jurnal_siswa_tambah" on public.journals for insert to authenticated
with check (public.siswa_saya(student_id));
create policy "jurnal_siswa_ubah" on public.journals for update to authenticated
using (public.siswa_saya(student_id)) with check (public.siswa_saya(student_id));
create policy "jurnal_siswa_hapus" on public.journals for delete to authenticated
using (public.siswa_saya(student_id) and not public.jurnal_ditanggapi(id));

-- 7. journal_photos
create policy "foto_baca" on public.journal_photos for select to authenticated
using (public.jurnal_saya(journal_id) or public.jurnal_bimbingan(journal_id));
create policy "foto_siswa_tambah" on public.journal_photos for insert to authenticated
with check (public.jurnal_saya(journal_id));
create policy "foto_siswa_hapus" on public.journal_photos for delete to authenticated
using (public.jurnal_saya(journal_id));

-- 8. feedback
create policy "feedback_baca" on public.feedback for select to authenticated
using (public.jurnal_saya(journal_id) or public.jurnal_bimbingan(journal_id));
create policy "feedback_guru_tambah" on public.feedback for insert to authenticated
with check (
  public.my_role() = 'guru'
  and responder_id = auth.uid()
  and public.jurnal_bimbingan(journal_id)
);

-- 9. Pemeriksaan: harus muncul daftar aturan (sekitar 20 baris)
select tablename, policyname, cmd from pg_policies where schemaname = 'public' order by tablename, policyname;
