<?php
$config = require __DIR__ . '/../config.php';
function base_url(): string {
  $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS']!=='off') ? 'https' : 'http';
  $host   = $_SERVER['HTTP_HOST'] ?? 'localhost';
  $path   = rtrim(dirname($_SERVER['SCRIPT_NAME'] ?? '/'), '/');
  return $scheme.'://'.$host.$path;
}
$db = $config['db'] + ['charset'=>'utf8mb4'];
$dsn = sprintf('mysql:host=%s;dbname=%s;charset=%s', $db['host'], $db['name'], $db['charset']);
try{
  $pdo = new PDO(
    $dsn,
    $db['user'],
    $db['pass'],
    [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC
    ]
);

$pdo->exec("SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci");
$pdo->exec("SET collation_connection = utf8mb4_unicode_ci");
  $pdo->exec("SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci");
}catch(Throwable $e){ http_response_code(500); echo 'DB error: '.htmlspecialchars($e->getMessage()); exit; }
$mailerAvailable=false; $autoload=__DIR__.'/../vendor/autoload.php';
if (is_file($autoload)) { require $autoload; $mailerAvailable = class_exists(\PHPMailer\PHPMailer\PHPMailer::class); }
$config['mail'] = [
 'host' => 'smtp.gmail.com',
 'port' => 587,
 'username' => 'emailgmail@gmail.com',
 'password' => 'gzwr ecmo qdvj jznu',
 'from_email' => 'emailgmail@gmail.com',
 'from_name' => 'BKPP e-Front Office'
];