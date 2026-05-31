<?php $role = role_code(); ?>
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>BKPP e-Front Office</title>
<link rel="stylesheet" href="assets/css/style.css">
</head>
<body>
<div class="container">
<header class="header-bkpp">
  <div class="header-left">
    <img src="assets/logo.png" alt="Logo BKPP">
    <div class="header-title">
      <h2>Badan Kepegawaian Pelatihan Dan Pendidikan</h2>
      <p>Pemerintah Kabupaten Labuhanbatu</p>
    </div>
  </div>

  <?php if (is_logged_in()): ?>
  <div class="user-info">
    <span><?=h(user()['name'])?></span>
    <span class="badge"><?=h(role_code())?></span>
  </div>
  <?php endif; ?>
</header>

<div class="navbar-bkpp">
  <nav>
    <?php if (!is_logged_in()): ?>
      <a href="?r=track">Cek Status</a>
      <a href="?r=login">Login</a>
    <?php endif; ?>

    <?php if (is_logged_in()): ?>
      <?php if ($role === 'FO'): ?>
        <a href="?r=fo/inbox">Inbox FO</a>
      <?php elseif (in_array($role, ['KOORDINATOR','KORDINATOR'], true)): ?>
        <a href="?r=kor/queue">Antrian Sekretariat</a>
      <?php elseif ($role === 'PETUGAS'): ?>
        <a href="?r=petugas/my">Tugas Petugas</a>
        <a href="?r=petugas/history">Riwayat</a>
      <?php elseif ($role === 'PIMPINAN'): ?>
        <a href="?r=pimpinan/ttd">TTE Pimpinan</a>
        <a href="?r=pimpinan/history">Riwayat</a>
      <?php endif; ?>

      <a href="?r=notifs">Notifikasi</a>
      <a href="?r=logout">Keluar</a>
    <?php endif; ?>
  </nav>
</div>