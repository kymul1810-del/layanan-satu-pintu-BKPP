<?php
require __DIR__.'/../app/bootstrap.php';

// Terima path relatif (mis. uploads/file.pdf) atau basename saja.
$file = trim((string)($_GET['file'] ?? ''));

if ($file === '') {
    http_response_code(400);
    die('File tidak valid');
}

// Normalisasi path input dan cegah traversal path.
$file = str_replace('\\', '/', $file);
$file = trim($file);
$file = ltrim($file, '/');

if ($file === '' || strpos($file, '..') !== false) {
    http_response_code(400);
    die('File tidak valid');
}

// Pastikan file hanya diambil dari dalam folder uploads.
$uploadsDir = realpath(__DIR__ . '/uploads');
if (!$uploadsDir || !is_dir($uploadsDir)) {
    http_response_code(404);
    die('Folder upload tidak ditemukan');
}

// Beberapa data lama bisa tersimpan sebagai:
// - uploads/nama.pdf
// - public/uploads/nama.pdf
// - /uploads/nama.pdf
// - full path .../public/uploads/nama.pdf
// Jadi kita coba beberapa kandidat path aman.
$candidates = [];

$normalized = $file;
$candidates[] = $normalized;

$posUploads = strrpos($normalized, 'uploads/');
if ($posUploads !== false) {
    $candidates[] = substr($normalized, $posUploads + strlen('uploads/'));
}

$candidates[] = basename($normalized);
$candidates = array_values(array_unique(array_filter($candidates)));

$path = false;
foreach ($candidates as $candidate) {
    if ($candidate === '' || strpos($candidate, '..') !== false) {
        continue;
    }

    $try = realpath($uploadsDir . DIRECTORY_SEPARATOR . $candidate);
    if ($try && is_file($try)) {
        $path = $try;
        break;
    }
}

$normBase = rtrim(str_replace('\\', '/', $uploadsDir), '/') . '/';
$normPath = $path ? str_replace('\\', '/', $path) : '';

// Cek path benar-benar ada di dalam uploads/
if (!$path || strpos($normPath, $normBase) !== 0 || !is_file($path)) {
    http_response_code(404);
    die('File tidak ditemukan');
}

$mime = mime_content_type($path) ?: 'application/octet-stream';
header('Content-Type: ' . $mime);
header('Content-Disposition: attachment; filename="' . basename($path) . '"');
header('Content-Length: ' . filesize($path));

readfile($path);
exit;