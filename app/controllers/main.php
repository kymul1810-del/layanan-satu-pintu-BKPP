<?php
function home_ctrl(PDO $pdo){ render('home'); }
function login_get_ctrl(){ render('login'); }
function login_post_ctrl(PDO $pdo){
  ensure_csrf();

  $email = trim($_POST['email'] ?? '');
  $password = $_POST['password'] ?? '';

  $stmt = $pdo->prepare("
    SELECT u.id, u.name, u.email, u.password, u.bidang_id, u.jenis_petugas,
           r.code AS role_code, r.name AS role_name,
           b.name AS bidang_name
    FROM users u
    JOIN roles r ON r.id = u.role_id
    LEFT JOIN bidang b ON b.id = u.bidang_id
    WHERE u.email = ? AND u.is_active = 1
    LIMIT 1
  ");
  $stmt->execute([$email]);
  $u = $stmt->fetch(PDO::FETCH_ASSOC);

  // 🔍 DEBUG (hapus nanti kalau sudah jalan)
  if (!$u) {
    flash('err','User tidak ditemukan');
    header('Location: ?r=login');
    exit;
  }

  if (!password_verify($password, $u['password'])) {
    flash('err','Password salah');
    header('Location: ?r=login');
    exit;
  }

  // ✅ SET SESSION
  $_SESSION['user'] = [
    'id' => $u['id'],
    'name' => $u['name'],
    'email' => $u['email'],
    'bidang_id' => $u['bidang_id'],
    'bidang_name' => $u['bidang_name'],
    'jenis_petugas' => $u['jenis_petugas']
  ];

  $_SESSION['role_code'] = $u['role_code'];

  // ✅ REDIRECT SESUAI ROLE
  $dest = [
    'FO'          => 'fo/inbox',
    'KOORDINATOR' => 'kor/queue',
    'KORDINATOR'  => 'kor/queue',
    'PETUGAS'     => 'petugas/my',
    'PIMPINAN'    => 'pimpinan/ttd',
  ][$u['role_code']] ?? 'home';

  flash('ok', 'Login sebagai '.$u['role_name']);
  header('Location: ?r='.$dest);
  exit;
}
function logout_ctrl(){ session_destroy(); header('Location:?r=home'); exit; }

function apply_get_ctrl(PDO $pdo){ $sv=$pdo->query("SELECT id,name,sla_hours FROM services ORDER BY name")->fetchAll(); render('apply',['services'=>$sv]); }
function apply_post_ctrl(PDO $pdo){

ensure_csrf();

$name  = trim($_POST['name'] ?? '');
$email = trim($_POST['email'] ?? '');
$phone = trim($_POST['phone'] ?? '');
$addr  = trim($_POST['address'] ?? '');
$service_id = intval($_POST['service_id'] ?? 0);

if($name=='' || $service_id===0){
  flash('err','Nama & layanan wajib diisi');
  header('Location:?r=apply');
  exit;
}

$pdo->beginTransaction();

try{

  // cek apakah pemohon sudah ada
  $st = $pdo->prepare("SELECT id FROM applicants WHERE email=?");
  $st->execute([$email]);
  $appl_id = $st->fetchColumn();

  // jika belum ada → buat baru
  if(!$appl_id){
    $st = $pdo->prepare("
      INSERT INTO applicants(name,email,phone,address)
      VALUES (?,?,?,?)
    ");
    $st->execute([$name,$email,$phone,$addr]);
    $appl_id = $pdo->lastInsertId();
  }

  // buat kode tiket
  $code = 'TCK-'.date('Ymd').'-'.str_pad((string)random_int(1,9999),4,'0',STR_PAD_LEFT);

  // simpan tiket
  $st = $pdo->prepare("
    INSERT INTO tickets(code,service_id,applicant_id,status,priority)
    VALUES (?,?,?,?,?)
  ");

  $st->execute([
    $code,
    $service_id,
    $appl_id,
    'DIAJUKAN',
    'NORMAL'
  ]);

  // ambil id tiket
  $ticket_id = $pdo->lastInsertId();

  // simpan riwayat status
  $st = $pdo->prepare("
    INSERT INTO status_history(ticket_id,old_status,new_status,changed_by,comment)
    VALUES (?,?,?,?,?)
  ");

  $st->execute([
    $ticket_id,
    null,
    'DIAJUKAN',
    null,
    'Pengajuan via web'
  ]);

  // upload file
  if(!empty($_FILES['files']['name'][0])){

    $updir = __DIR__.'/../../public/uploads';

    if(!is_dir($updir)){
      mkdir($updir,0777,true);
    }

    foreach($_FILES['files']['name'] as $i=>$orig){

      if($_FILES['files']['error'][$i] === UPLOAD_ERR_OK){

        $tmp = $_FILES['files']['tmp_name'][$i];

        $basename = uniqid('f_').'_'.preg_replace('/[^A-Za-z0-9_\.-]/','_',$orig);

        move_uploaded_file($tmp,$updir.'/'.$basename);

        $st = $pdo->prepare("
          INSERT INTO ticket_files(ticket_id,uploaded_by_applicant,original_name,stored_path)
          VALUES (?,?,?,?)
        ");

        $st->execute([
          $ticket_id,
          1,
          $orig,
          'uploads/'.$basename
        ]);

      }

    }

  }

  $pdo->commit();

  flash('ok','Pengajuan terkirim. Kode: '.$code);

}catch(Throwable $e){

  $pdo->rollBack();
  flash('err','Gagal: '.$e->getMessage());

}

header('Location:?r=apply');
exit;

}
function fo_inbox_ctrl(PDO $pdo){
    require_login();

    if (role_code() !== 'FO') {
        http_response_code(403);
        exit('Forbidden');
    }

    $stmt = $pdo->query("
        SELECT
            t.id,
            t.code,
            a.name AS pemohon,
            sv.name AS layanan,
            (
                SELECT tf.stored_path
                FROM ticket_files tf
                WHERE tf.ticket_id = t.id
                ORDER BY tf.id DESC
                LIMIT 1
            ) AS file
        FROM tickets t
        JOIN applicants a ON a.id = t.applicant_id
        JOIN services sv ON sv.id = t.service_id
        WHERE t.status = 'DIAJUKAN'
        ORDER BY t.created_at ASC
    ");
    $rows = $stmt->fetchAll();

    $stmt = $pdo->query("
        SELECT id, name
        FROM bidang
        WHERE code <> 'FO'
        ORDER BY name
    ");
    $bidang = $stmt->fetchAll();

    render('fo_inbox', [
        'rows'   => $rows,
        'bidang' => $bidang
    ]);
}
function fo_accept_post_ctrl(PDO $pdo){
    require_login();
    ensure_csrf();

    if (role_code() !== 'FO') {
        http_response_code(403);
        exit('Forbidden');
    }

    $code      = trim($_POST['code'] ?? '');
    $bidang_id = (int)($_POST['bidang_id'] ?? 0);

    if ($code === '' || $bidang_id <= 0) {
        flash('err', 'Data pengiriman tidak valid.');
        header('Location:?r=fo/inbox');
        exit;
    }

    try {
        $pdo->beginTransaction();

        $stmt = $pdo->prepare("
            SELECT id, status
            FROM tickets
            WHERE code = ?
            FOR UPDATE
        ");
        $stmt->execute([$code]);
        $ticket = $stmt->fetch();

        if (!$ticket) {
            throw new Exception('Tiket tidak ditemukan.');
        }

        if ($ticket['status'] !== 'DIAJUKAN') {
            throw new Exception('Tiket ini sudah diproses sebelumnya.');
        }

        $stmt = $pdo->prepare("
            SELECT u.id, u.name
            FROM users u
            JOIN roles r ON r.id = u.role_id
            WHERE r.code = 'KOORDINATOR'
              AND u.bidang_id = ?
              AND u.is_active = 1
            ORDER BY u.id ASC
            LIMIT 1
        ");
        $stmt->execute([$bidang_id]);
        $koord = $stmt->fetch();

        if (!$koord) {
            throw new Exception('Tidak ada koordinator aktif di bidang yang dipilih.');
        }

        $stmt = $pdo->prepare("
            UPDATE tickets
            SET status = 'DITERIMA_FO',
                current_bidang_id = ?,
                updated_at = NOW()
            WHERE id = ?
        ");
        $stmt->execute([$bidang_id, $ticket['id']]);

        $stmt = $pdo->prepare("
            INSERT INTO status_history(ticket_id, old_status, new_status, changed_by, comment)
            VALUES (?, ?, ?, ?, ?)
        ");
        $stmt->execute([
            $ticket['id'],
            'DIAJUKAN',
            'DITERIMA_FO',
            user()['id'],
            'Screening FO lulus dan diteruskan ke koordinator'
        ]);

        $stmt = $pdo->prepare("
            INSERT INTO assignments(ticket_id, assigned_to_user_id, assigned_by_user_id, status, note, assigned_at)
            VALUES (?, ?, ?, ?, ?, NOW())
        ");
        $stmt->execute([
            $ticket['id'],
            $koord['id'],
            user()['id'],
            'IN_PROGRESS',
            'Menunggu penugasan koordinator'
        ]);

        $stmt = $pdo->prepare("
            INSERT INTO notifications(recipient_user_id, type, ref_ticket_id, message)
            VALUES (?, ?, ?, ?)
        ");
        $stmt->execute([
            $koord['id'],
            'STATUS_CHANGE',
            $ticket['id'],
            'Tiket ' . $code . ' diterima FO dan masuk antrian bidang'
        ]);

        $pdo->commit();

        flash('ok', 'Tiket ' . $code . ' berhasil dikirim ke koordinator.');
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }

        flash('err', 'Gagal mengirim tiket: ' . $e->getMessage());
    }

    header('Location:?r=fo/inbox');
    exit;
}
function fo_reject_post_ctrl(PDO $pdo){
    require_login();
    ensure_csrf();

    if (role_code() !== 'FO') {
        http_response_code(403);
        exit('Forbidden');
    }

    $code    = trim($_POST['code'] ?? '');
    $comment = trim($_POST['comment'] ?? '');

    if ($code === '') {
        flash('err', 'Kode tiket tidak valid.');
        header('Location:?r=fo/inbox');
        exit;
    }

    if ($comment === '') {
        $comment = 'Ditolak saat screening FO';
    }

    try {
        $pdo->beginTransaction();

        $stmt = $pdo->prepare("
            SELECT id, applicant_id, status
            FROM tickets
            WHERE code = ?
            FOR UPDATE
        ");
        $stmt->execute([$code]);
        $ticket = $stmt->fetch();

        if (!$ticket) {
            throw new Exception('Tiket tidak ditemukan.');
        }

        if ($ticket['status'] !== 'DIAJUKAN') {
            throw new Exception('Tiket ini tidak bisa ditolak karena statusnya sudah berubah.');
        }

        $stmt = $pdo->prepare("
            UPDATE tickets
            SET status = 'DITOLAK',
                updated_at = NOW()
            WHERE id = ?
        ");
        $stmt->execute([$ticket['id']]);

        $stmt = $pdo->prepare("
            INSERT INTO status_history(ticket_id, old_status, new_status, changed_by, comment)
            VALUES (?, ?, ?, ?, ?)
        ");
        $stmt->execute([
            $ticket['id'],
            'DIAJUKAN',
            'DITOLAK',
            user()['id'],
            $comment
        ]);

        $stmt = $pdo->prepare("
            INSERT INTO notifications(recipient_applicant_id, type, ref_ticket_id, message)
            VALUES (?, ?, ?, ?)
        ");
        $stmt->execute([
            $ticket['applicant_id'],
            'STATUS_CHANGE',
            $ticket['id'],
            'Status tiket DITOLAK: ' . mb_substr($comment, 0, 200)
        ]);

        $pdo->commit();

        flash('ok', 'Tiket ' . $code . ' berhasil ditolak.');
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }

        flash('err', 'Gagal menolak tiket: ' . $e->getMessage());
    }

    header('Location:?r=fo/inbox');
    exit;
}
function kor_queue_ctrl(PDO $pdo){
    require_login();

    if(role_code()!=='KOORDINATOR'){
        http_response_code(403);
        exit('Forbidden');
    }

    $bidang_id = user()['bidang_id'];

    $stmt=$pdo->prepare("
    SELECT 
    t.id,
    t.code,
    sv.name AS layanan,
    t.priority
    FROM tickets t
    JOIN services sv ON sv.id=t.service_id
    WHERE t.current_bidang_id=?
    AND t.status='DITERIMA_FO'
    ORDER BY t.priority DESC, t.created_at ASC
    ");

    $stmt->execute([$bidang_id]);
    $rows=$stmt->fetchAll();

    foreach($rows as &$r){
        $f=$pdo->prepare("
        SELECT original_name, stored_path 
        FROM ticket_files 
        WHERE ticket_id=?
        ");
        $f->execute([$r['id']]);
        $r['files']=$f->fetchAll();
    }

    /* ambil petugas */
    $petugas = $pdo->prepare("
    SELECT id, name, jenis_petugas, bidang_id
    FROM users
    WHERE role_id = (SELECT id FROM roles WHERE code='PETUGAS')
      AND is_active = 1
    ORDER BY bidang_id, name
");
$petugas->execute();
$pt = $petugas->fetchAll();

    render('kor_queue',[
        'rows'=>$rows,
        'petugas'=>$pt
    ]);
}
function kor_assign_post_ctrl(PDO $pdo){
    require_login();
    ensure_csrf();

    if(role_code()!=='KOORDINATOR'){
        http_response_code(403);
        exit('Forbidden');
    }

    $code = $_POST['code'] ?? '';
    $petugas_id = (int)($_POST['petugas_id'] ?? 0);

    if($petugas_id <= 0){
        flash('err','Pilih petugas dulu');
        header('Location:?r=kor/queue');
        exit;
    }

    $stmt = $pdo->prepare("SELECT id FROM tickets WHERE code=?");
    $stmt->execute([$code]);
    $t = $stmt->fetch();

    if(!$t){
        flash('err','Tiket tidak ditemukan');
        header('Location:?r=kor/queue');
        exit;
    }

    $ticket_id = $t['id'];

    $stmt = $pdo->prepare("
    SELECT id, name, jenis_petugas, bidang_id
    FROM users 
    WHERE role_id = (SELECT id FROM roles WHERE code='PETUGAS')
      AND id = ?
      AND is_active = 1
    LIMIT 1
");
$stmt->execute([$petugas_id]);
    $u = $stmt->fetch();

    if(!$u){
        flash('err','Petugas tidak valid untuk bidang ini');
        header('Location:?r=kor/queue');
        exit;
    }

    $stmt = $pdo->prepare("
        INSERT INTO assignments (
            ticket_id, assigned_to_user_id, assigned_by_user_id, status, note, assigned_at
        ) VALUES (?, ?, ?, 'IN_PROGRESS', 'Diproses petugas', NOW())
    ");
    $stmt->execute([$ticket_id, $u['id'], user()['id']]);

    $stmt = $pdo->prepare("
        UPDATE tickets
        SET tujuan_petugas = ?, status = 'DIKERJAKAN', updated_at = NOW()
        WHERE id = ?
    ");
    $stmt->execute([$u['jenis_petugas'], $ticket_id]);

    flash('ok','Tiket dikirim ke '.$u['name']);
    header('Location:?r=kor/queue');
    exit;
}
function petugas_my_ctrl(PDO $pdo){

require_login();

if(role_code()!=='PETUGAS'){
 http_response_code(403);
 exit('Forbidden');
}

$jenis = user()['jenis_petugas'] ?? '';

$stmt=$pdo->prepare("
SELECT 
t.id,
t.code,
t.status,
sv.name AS layanan
FROM tickets t
JOIN services sv ON sv.id=t.service_id
WHERE t.tujuan_petugas = ?
AND t.status = 'DIKERJAKAN'
ORDER BY t.updated_at DESC
");

$stmt->execute([$jenis]);

$rows=$stmt->fetchAll();

/* ambil file */
foreach($rows as &$r){

$f=$pdo->prepare("
SELECT original_name, stored_path
FROM ticket_files
WHERE ticket_id=?
");

$f->execute([$r['id']]);

$r['files']=$f->fetchAll();

}

render('petugas_my',['rows'=>$rows]);

}
function petugas_history_ctrl(PDO $pdo){

require_login();

if(role_code()!=='PETUGAS'){
 http_response_code(403);
 exit('Forbidden');
}

$stmt=$pdo->prepare("
SELECT 
t.id,
t.code,
t.status,
sv.name AS layanan,
t.updated_at,
tf.original_name,
tf.stored_path
FROM assignments a
JOIN tickets t ON t.id = a.ticket_id
JOIN services sv ON sv.id = t.service_id
LEFT JOIN ticket_files tf ON tf.ticket_id = t.id
WHERE a.assigned_to_user_id=?
AND a.unassigned_at IS NULL
AND t.status IN ('DIKERJAKAN','SIAP_TTD','DITOLAK','SELESAI')
ORDER BY t.updated_at DESC
");

$stmt->execute([ user()['id'] ]);

$data = [];

while($r = $stmt->fetch()){
    $id = $r['id'];

    if(!isset($data[$id])){
        $data[$id] = $r;
        $data[$id]['files'] = [];
    }

    if(!empty($r['original_name'])){
        $data[$id]['files'][] = [
            'original_name' => $r['original_name'],
            'stored_path' => $r['stored_path']
        ];
    }
}

$rows = $data;

render('petugas_history',['rows'=>$rows]);

}
function petugas_needdata_post_ctrl(PDO $pdo){ ensure_csrf(); if(role_code()!=='PETUGAS'){ http_response_code(403); exit('Forbidden'); } $code=$_POST['code']??''; $comment=trim($_POST['comment']??'Mohon lengkapi data'); call_sp($pdo,'sp_ticket_request_more_data',[ $code, user()['id'], $comment ]); flash('ok','Permintaan data dikirim untuk '.$code); header('Location:?r=petugas/my'); exit; }
function ticket_upd_post_ctrl(PDO $pdo){
  ensure_csrf();

  if(!is_logged_in()){
    http_response_code(403);
    exit('Forbidden');
  }

  if(role_code()!=='PETUGAS'){
    http_response_code(403);
    exit('Forbidden');
  }

  $code = trim($_POST['code'] ?? '');
  $cmt  = trim($_POST['comment'] ?? '');
  $new  = trim($_POST['new_status'] ?? 'SIAP_TTD');
  $back = trim($_POST['_back'] ?? 'petugas/my');

  if($code === ''){
    flash('err','Kode tiket tidak valid');
    header('Location:?r='.$back);
    exit;
  }

  if(!in_array($new, ['SIAP_TTD','DITOLAK'], true)){
    flash('err','Status tidak diizinkan');
    header('Location:?r='.$back);
    exit;
  }

  call_sp($pdo,'sp_ticket_update_status',[
    $code,
    $new,
    user()['id'],
    $cmt
  ]);

  if($new === 'SIAP_TTD'){
    $stmt = $pdo->query("
      SELECT u.id
      FROM users u
      JOIN roles r ON r.id = u.role_id
      WHERE r.code = 'PIMPINAN'
      AND u.is_active = 1
      ORDER BY u.id ASC
      LIMIT 1
    ");
    $pimpinan = $stmt->fetch();

    if(!$pimpinan){
      flash('err','Pimpinan aktif tidak ditemukan');
      header('Location:?r='.$back);
      exit;
    }

    $pdo->prepare("
      INSERT INTO assignments (ticket_id, assigned_to_user_id)
      SELECT id, ?
      FROM tickets
      WHERE code = ?
    ")->execute([$pimpinan['id'], $code]);

    flash('ok','Tiket dikirim ke pimpinan');
  }else{
    flash('ok','Tiket ditolak');
  }

  header('Location:?r='.$back);
  exit;
}
function pimpinan_ttd_ctrl(PDO $pdo){

require_login();

if(role_code()!=='PIMPINAN'){
 http_response_code(403);
 exit('Forbidden');
}

$stmt=$pdo->prepare("
SELECT 
t.id,
t.code,
t.status,
sv.name AS layanan,
ap.name AS pemohon,
t.updated_at,
tf.original_name,
tf.stored_path
FROM assignments asn
JOIN tickets t ON t.id = asn.ticket_id
JOIN services sv ON sv.id = t.service_id
JOIN applicants ap ON ap.id = t.applicant_id
LEFT JOIN ticket_files tf ON tf.ticket_id = t.id
WHERE asn.assigned_to_user_id=?
AND asn.unassigned_at IS NULL
AND t.status='SIAP_TTD'
ORDER BY t.updated_at ASC
");

$stmt->execute([user()['id']]);

$rows=$stmt->fetchAll();


/* ambil dokumen pemohon */

foreach($rows as &$r){

$f=$pdo->prepare("
SELECT original_name, stored_path
FROM ticket_files
WHERE ticket_id=?
");

$f->execute([$r['id']]);

$r['files']=$f->fetchAll();

}

render('pimpinan_ttd',['rows'=>$rows]);

}
function tte_upload_post_ctrl(PDO $pdo, array $cfg){

ensure_csrf();

if(role_code()!=='PIMPINAN'){
 http_response_code(403);
 exit('Forbidden');
}

$code=$_POST['code']??'';

if(!empty($_FILES['file_tte']['name']) && $_FILES['file_tte']['error']===UPLOAD_ERR_OK){

$updir=__DIR__.'/../../public/uploads';
if(!is_dir($updir)) mkdir($updir,0777,true);

$orig=$_FILES['file_tte']['name'];
$tmp=$_FILES['file_tte']['tmp_name'];

$dest='tte_'.uniqid().'_'.preg_replace('/[^A-Za-z0-9_\.-]/','_',$orig);

$abs=$updir.'/'.$dest;
$rel='uploads/'.$dest;

move_uploaded_file($tmp,$abs);

$get=$pdo->prepare("
SELECT 
t.id AS tid,
a.email,
a.name
FROM tickets t
JOIN applicants a ON a.id=t.applicant_id
WHERE t.code=?
");

$get->execute([$code]);
$row=$get->fetch();

$tid=$row['tid']??null;

/* simpan dokumen TTE */

$stmt=$pdo->prepare("
INSERT INTO documents_out(ticket_id,tte_provider,tte_signed_path)
VALUES (?,?,?)
");

$stmt->execute([$tid,'DevProvider',$rel]);

/* kirim email */

if(!empty($row['email'])){

$link = base_url().'/'.$rel;

$subject = "Dokumen Layanan Selesai [$code]";

$body = '
<h3>Dokumen Anda telah selesai diproses</h3>

<p>Yth. '.$row['name'].',</p>

<p>Dokumen layanan Anda sudah selesai ditandatangani.</p>

<p>Silakan download dokumen melalui tombol berikut:</p>

<p>
<a style="
background:#2d7ef7;
color:white;
padding:10px 20px;
text-decoration:none;
border-radius:6px;
" href="'.$link.'">
Download Dokumen
</a>
</p>

<p>Terima kasih.</p>
';

send_mail_smtp($cfg['mail'],$row['email'],$subject,$body);

}

/* notifikasi sistem */

$pdo->prepare("
INSERT INTO notifications(recipient_applicant_id,type,ref_ticket_id,message)
SELECT applicant_id,'RESULT_READY', ?, CONCAT('Hasil tersedia: ', ?)
FROM tickets
WHERE id=?
")->execute([$tid,$rel,$tid]);

flash('ok','TTE berhasil diupload dan email dikirim.');

}else{

flash('err','File belum dipilih');

}

header('Location:?r=pimpinan/ttd');
exit;

}
function notifs_ctrl(PDO $pdo){ require_login(); $rows=$pdo->query("SELECT n.created_at,t.code AS ticket,n.type,n.message,d.tte_signed_path AS path FROM notifications n LEFT JOIN tickets t ON t.id=n.ref_ticket_id LEFT JOIN documents_out d ON d.ticket_id=n.ref_ticket_id ORDER BY n.created_at DESC LIMIT 50")->fetchAll(); render('notifs',['rows'=>$rows]); }
function pimpinan_history_ctrl(PDO $pdo){

require_login();

if(role_code()!=='PIMPINAN'){
 http_response_code(403);
 exit('Forbidden');
}

$stmt=$pdo->query("
SELECT 
t.code,
sv.name AS layanan,
a.name AS pemohon,
d.tte_signed_path,
t.updated_at
FROM documents_out d
JOIN tickets t ON t.id=d.ticket_id
JOIN services sv ON sv.id=t.service_id
JOIN applicants a ON a.id=t.applicant_id
ORDER BY t.updated_at DESC
");

$rows=$stmt->fetchAll();

render('pimpinan_history',['rows'=>$rows]);

}

