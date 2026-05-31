<?php
function send_mail_smtp(array $cfg, string $to, string $subject, string $html, ?string $attachAbsPath=null){
  global $mailerAvailable;
  if (!$mailerAvailable) return false;
  try{
    $m = new \PHPMailer\PHPMailer\PHPMailer(true);
    $m->isSMTP(); $m->Host=$cfg['host']; $m->SMTPAuth=true; $m->Username=$cfg['username']; $m->Password=$cfg['password'];
    $m->SMTPSecure=\PHPMailer\PHPMailer\PHPMailer::ENCRYPTION_STARTTLS; $m->Port=$cfg['port']; $m->CharSet='UTF-8';
    $m->setFrom($cfg['from_email'],$cfg['from_name']); $m->addAddress($to);
    $m->isHTML(true); $m->Subject=$subject; $m->Body=$html;
    if ($attachAbsPath && is_file($attachAbsPath)) $m->addAttachment($attachAbsPath);
    $m->send(); return true;
  }catch(Throwable $e){ return false; }
}
