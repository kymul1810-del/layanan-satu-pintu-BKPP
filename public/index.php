<?php
session_start();

require __DIR__ . '/../app/bootstrap.php';
require __DIR__ . '/../app/helpers.php';
require __DIR__ . '/../app/mail.php';
require __DIR__ . '/../app/controllers/main.php';

$r      = $_GET['r'] ?? 'home';
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

switch ($r) {

    case 'track':
        require __DIR__ . '/../app/controllers/track.php';
        track_page($pdo);
        break;

    case 'track/search':
        require __DIR__ . '/../app/controllers/track.php';
        track_search($pdo);
        break;

    case 'home':
        home_ctrl($pdo);
        break;

    case 'login':
        if ($method === 'POST') {
            login_post_ctrl($pdo);
        } else {
            login_get_ctrl();
        }
        break;

    case 'logout':
        logout_ctrl();
        break;

    case 'apply':
        if ($method === 'POST') {
            apply_post_ctrl($pdo);
        } else {
            apply_get_ctrl($pdo);
        }
        break;

    case 'fo/inbox':
        fo_inbox_ctrl($pdo);
        break;

    case 'fo.accept':
        if ($method === 'POST') {
            fo_accept_post_ctrl($pdo);
        } else {
            header('Location: ?r=fo/inbox');
            exit;
        }
        break;

    case 'fo.reject':
        if ($method === 'POST') {
            fo_reject_post_ctrl($pdo);
        } else {
            header('Location: ?r=fo/inbox');
            exit;
        }
        break;

    case 'kor/queue':
        kor_queue_ctrl($pdo);
        break;

    case 'kor.assign':
        if ($method === 'POST') {
            kor_assign_post_ctrl($pdo);
        } else {
            header('Location: ?r=kor/queue');
            exit;
        }
        break;

    case 'petugas/my':
        petugas_my_ctrl($pdo);
        break;

    case 'petugas/history':
        petugas_history_ctrl($pdo);
        break;

    case 'petugas.needdata':
        if ($method === 'POST') {
            petugas_needdata_post_ctrl($pdo);
        } else {
            header('Location: ?r=petugas/my');
            exit;
        }
        break;

    case 'ticket.upd':
        if ($method === 'POST') {
            ticket_upd_post_ctrl($pdo);
        } else {
            header('Location: ?r=dashboard');
            exit;
        }
        break;

    case 'pimpinan/ttd':
        pimpinan_ttd_ctrl($pdo);
        break;

    case 'pimpinan/history':
        pimpinan_history_ctrl($pdo);
        break;

    case 'tte.upload':
        if ($method === 'POST') {
            tte_upload_post_ctrl($pdo, $config);
        } else {
            header('Location: ?r=pimpinan/ttd');
            exit;
        }
        break;

    case 'notifs':
        notifs_ctrl($pdo);
        break;

    default:
        header('Location: ?r=home');
        exit;
}