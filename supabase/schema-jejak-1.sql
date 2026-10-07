-- =====================================================================
-- JEJAK - Skema database tahap 1 (6 tabel untuk fitur wajib)
-- Tempel SELURUH isi file ini di Supabase > SQL Editor, lalu tekan Run.
-- Tabel lain (documents, portfolios, portfolio_journals, reports)
-- ditambahkan nanti, hanya kalau waktunya cukup.
-- =====================================================================

-- 1. profiles: data dasar semua akun (siswa, guru, admin)
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  role text not null check (role in ('siswa', 'guru', 'admin')),
  email text,
  created_at timestamptz not null default now()
);

-- 2. students: data siswa + penempatan PKL + guru pembimbing
create table public.students (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null unique references public.profiles(id) on delete cascade,
  nis text,
  class_name text,
  major text,
  guru_id uuid references public.profiles(id),
  company_name text,
  industry_supervisor text,
  pkl_start_date date,
  pkl_end_date date,
  created_at timestamptz not null default now()
);

-- 3. attendance: kehadiran, satu catatan per siswa per tanggal
--    Tanggal memakai zona waktu Papua (WIT) supaya check-in pagi tidak salah hari.
create table public.attendance (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  attendance_date date not null default ((now() at time zone 'Asia/Jayapura')::date),
  check_in timestamptz default now(),
  status text not null check (status in ('hadir', 'izin', 'sakit', 'alpa')),
  reason text,
  set_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  unique (student_id, attendance_date)
);

-- 4. journals: jejak kegiatan + refleksi
create table public.journals (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  activity_date date not null default ((now() at time zone 'Asia/Jayapura')::date),
  activity_title text not null,
  activity_description text not null,
  location text,
  what_learned text not null,
  what_not_understood text,
  interesting_part text,
  difficult_part text,
  understanding_level text not null check (understanding_level in ('belum_paham', 'cukup', 'paham')),
  want_to_learn_more boolean not null default false,
  feeling text,
  send_to_teacher boolean not null default false,
  understood boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 5. journal_photos: foto/bukti yang menempel pada satu jurnal
create table public.journal_photos (
  id uuid primary key default gen_random_uuid(),
  journal_id uuid not null references public.journals(id) on delete cascade,
  file_url text not null,
  caption text,
  created_at timestamptz not null default now()
);

-- 6. feedback: tanggapan guru pada jurnal (satu jurnal boleh punya banyak tanggapan)
create table public.feedback (
  id uuid primary key default gen_random_uuid(),
  journal_id uuid not null references public.journals(id) on delete cascade,
  responder_id uuid not null references public.profiles(id),
  response text not null,
  created_at timestamptz not null default now()
);

-- =====================================================================
-- KEAMANAN: aktifkan Row Level Security (RLS) di semua tabel.
-- Selama belum ada aturan (policy), tidak ada yang bisa membaca atau
-- menulis data lewat aplikasi. Ini sengaja: aman dulu, aturan akses
-- ditambahkan di langkah berikutnya.
-- =====================================================================
alter table public.profiles       enable row level security;
alter table public.students       enable row level security;
alter table public.attendance     enable row level security;
alter table public.journals       enable row level security;
alter table public.journal_photos enable row level security;
alter table public.feedback       enable row level security;
