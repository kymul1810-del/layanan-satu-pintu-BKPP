<?php
if (session_status() === PHP_SESSION_NONE) session_start();
function h($s){ return htmlspecialchars($s ?? '', ENT_QUOTES, 'UTF-8'); }
function csrf_token(){ if (empty($_SESSION['_csrf'])) $_SESSION['_csrf']=bin2hex(random_bytes(16)); return $_SESSION['_csrf']; }
function ensure_csrf(){ if (($_POST['_csrf'] ?? '') !== ($_SESSION['_csrf'] ?? '')) { http_response_code(400); exit('CSRF token mismatch'); } }
function flash($k,$v=null){ if($v!==null){$_SESSION['flash'][$k]=$v; return;} $val=$_SESSION['flash'][$k]??null; unset($_SESSION['flash'][$k]); return $val; }
function user(){ return $_SESSION['user'] ?? null; }
function role_code(){ return $_SESSION['role_code'] ?? null; }
function has_role(array $roles): bool { return in_array((string) role_code(), $roles, true); }
function is_logged_in(){ return !empty($_SESSION['user']); }
function require_login(){ if(!is_logged_in()){ header('Location: ?r=login'); exit; } }
function call_sp(PDO $pdo, string $name, array $params=[]){ $place = implode(',', array_fill(0, count($params), '?')); $stmt=$pdo->prepare("CALL $name($place)"); $stmt->execute(array_values($params)); while($stmt->nextRowset()){} }
function render(string $view, array $data=[]){ extract($data); include __DIR__.'/views/layouts/header.php'; include __DIR__.'/views/components/flash.php'; include __DIR__.'/views/pages/'.$view.'.php'; include __DIR__.'/views/layouts/footer.php'; }
