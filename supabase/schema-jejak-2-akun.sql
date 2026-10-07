-- =====================================================================
-- JEJAK - Langkah 5: isi nama + peran untuk 5 akun uji
-- Pakai TAB QUERY BARU di SQL Editor (jangan di tab lama), lalu Run.
-- Jalankan SEKALI saja.
-- =====================================================================

-- 1. profiles: nama dan peran tiap akun (diambil dari akun yang sudah dibuat)
insert into public.profiles (id, full_name, role, email)
select u.id, v.full_name, v.role, u.email
from auth.users u
join (values
  ('admin.jejak@example.com', 'Admin JEJAK', 'admin'),
  ('guru1.jejak@example.com', 'Guru Satu',   'guru'),
  ('guru2.jejak@example.com', 'Guru Dua',    'guru'),
  ('siswa1.jejak@example.com', 'Siswa Satu', 'siswa'),
  ('siswa2.jejak@example.com', 'Siswa Dua',  'siswa')
) as v(email, full_name, role) on v.email = u.email;

-- 2. students: data siswa contoh, Siswa Satu dibimbing Guru Satu, Siswa Dua dibimbing Guru Dua
insert into public.students
  (profile_id, nis, class_name, major, guru_id, company_name, industry_supervisor, pkl_start_date, pkl_end_date)
select s.id, v.nis, 'XI-A', 'Jurusan Contoh', g.id,
       'Perusahaan Contoh', 'Pembimbing Contoh', date '2026-10-01', date '2026-12-31'
from (values
  ('siswa1.jejak@example.com', '0001', 'guru1.jejak@example.com'),
  ('siswa2.jejak@example.com', '0002', 'guru2.jejak@example.com')
) as v(siswa_email, nis, guru_email)
join public.profiles s on s.email = v.siswa_email
join public.profiles g on g.email = v.guru_email;

-- 3. Pemeriksaan: harus muncul 5 baris (admin, 2 guru, 2 siswa)
select p.full_name, p.role, p.email, g.full_name as guru_pembimbing
from public.profiles p
left join public.students st on st.profile_id = p.id
left join public.profiles g on g.id = st.guru_id
order by p.role, p.full_name;
