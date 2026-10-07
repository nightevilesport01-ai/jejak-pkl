// Dipakai semua halaman setelah login.
const db = supabase.createClient(SUPABASE_URL, SUPABASE_KEY);
const HALAMAN = { siswa: "siswa.html", guru: "guru.html", admin: "admin.html" };

// Ambil nama dan role akun yang sedang login. Kalau belum login, kembali ke halaman login.
async function ambilProfil() {
  const { data: { session } } = await db.auth.getSession();
  if (!session) { location.href = "index.html"; return null; }
  const { data, error } = await db.from("profiles").select("full_name, role").eq("id", session.user.id).single();
  if (error || !data) { await db.auth.signOut(); location.href = "index.html"; return null; }
  return data;
}

// Pastikan halaman ini hanya dibuka oleh role yang tepat; role lain dialihkan ke halamannya sendiri.
async function wajibRole(role) {
  const p = await ambilProfil();
  if (!p) return null;
  if (p.role !== role) { location.href = HALAMAN[p.role]; return null; }
  document.getElementById("nama").textContent = p.full_name;
  return p;
}

async function keluar() {
  await db.auth.signOut();
  location.href = "index.html";
}
