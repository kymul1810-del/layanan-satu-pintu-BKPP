<?php
require __DIR__.'/../app/bootstrap.php';

$hash = password_hash('123456', PASSWORD_DEFAULT);

$pdo->prepare("UPDATE users SET password=? WHERE email=?")
    ->execute([$hash, 'pimpinan@example.local']);

echo "Password berhasil direset";