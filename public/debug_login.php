<?php
/**
 * DEBUG LOGIN - Letakkan file ini di folder public/, akses via browser
 * Hapus file ini setelah selesai debug!
 * URL: http://localhost/bkpp_fo/public/debug_login.php
 */

require __DIR__ . '/../app/bootstrap.php';

echo "<h2>Debug Login BKPP</h2>";
echo "<style>body{font-family:monospace;padding:20px} .ok{color:green} .err{color:red} table{border-collapse:collapse} td,th{border:1px solid #ccc;padding:6px 12px}</style>";

// 1. Cek koneksi DB
echo "<h3>1. Koneksi Database</h3>";
try {
    $pdo->query("SELECT 1");
    echo "<p class='ok'>✓ Koneksi ke database '<b>" . htmlspecialchars($config['db']['name']) . "</b>' berhasil</p>";
} catch (Exception $e) {
    echo "<p class='err'>✗ Gagal: " . htmlspecialchars($e->getMessage()) . "</p>";
    exit;
}

// 2. Cek kolom password ada atau tidak
echo "<h3>2. Struktur Tabel users</h3>";
$cols = $pdo->query("SHOW COLUMNS FROM users")->fetchAll(PDO::FETCH_ASSOC);
$hasPassword = false;
echo "<table><tr><th>Field</th><th>Type</th><th>Null</th><th>Default</th></tr>";
foreach ($cols as $c) {
    $highlight = $c['Field'] === 'password' ? " style='background:#efe'" : '';
    echo "<tr$highlight><td>{$c['Field']}</td><td>{$c['Type']}</td><td>{$c['Null']}</td><td>{$c['Default']}</td></tr>";
    if ($c['Field'] === 'password') $hasPassword = true;
}
echo "</table>";
if (!$hasPassword) {
    echo "<p class='err'>✗ Kolom PASSWORD tidak ditemukan! Jalankan patch_password.sql dulu.</p>";
} else {
    echo "<p class='ok'>✓ Kolom password ada</p>";
}

// 3. Cek data user
echo "<h3>3. Data Users</h3>";
$users = $pdo->query("SELECT u.id, u.name, u.email, u.is_active, 
    LEFT(u.password,7) AS hash_prefix,
    LENGTH(u.password) AS pass_len,
    r.code AS role
    FROM users u JOIN roles r ON r.id=u.role_id")->fetchAll();

echo "<table><tr><th>ID</th><th>Nama</th><th>Email</th><th>Aktif</th><th>Hash (7 char)</th><th>Panjang Hash</th><th>Role</th><th>Tes password123</th></tr>";
foreach ($users as $u) {
    // Ambil full hash untuk verifikasi
    $full = $pdo->prepare("SELECT password FROM users WHERE id=?");
    $full->execute([$u['id']]);
    $hash = $full->fetchColumn();
    $verify = password_verify('password123', $hash) ? "<span class='ok'>✓ COCOK</span>" : "<span class='err'>✗ Tidak cocok</span>";
    $aktif = $u['is_active'] ? "<span class='ok'>Ya</span>" : "<span class='err'>Tidak</span>";
    echo "<tr><td>{$u['id']}</td><td>{$u['name']}</td><td>{$u['email']}</td><td>{$aktif}</td><td>{$u['hash_prefix']}</td><td>{$u['pass_len']}</td><td>{$u['role']}</td><td>$verify</td></tr>";
}
echo "</table>";

// 4. Test login manual
echo "<h3>4. Simulasi Query Login</h3>";
$testEmail = 'fo1@example.local';
$stmt = $pdo->prepare("
    SELECT u.*, r.code AS role_code FROM users u
    JOIN roles r ON r.id=u.role_id
    LEFT JOIN bidang b ON b.id=u.bidang_id
    WHERE u.email=? AND u.is_active=1
");
$stmt->execute([$testEmail]);
$u = $stmt->fetch();
if ($u) {
    $ok = password_verify('password123', $u['password']);
    echo "<p class='ok'>✓ User '$testEmail' ditemukan di DB</p>";
    echo "<p>" . ($ok ? "<span class='ok'>✓ password_verify BERHASIL → login akan sukses</span>" : "<span class='err'>✗ password_verify GAGAL → hash tidak cocok</span>") . "</p>";
} else {
    echo "<p class='err'>✗ User '$testEmail' tidak ditemukan atau is_active=0</p>";
}

echo "<hr><p style='color:#999'>Hapus file ini setelah debug selesai!</p>";
