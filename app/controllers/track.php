<?php

function track_page(PDO $pdo){

    render('track_form');

}

function track_search(PDO $pdo){

    $code = trim($_POST['code'] ?? '');

    $ticket = null;
    $history = [];

    if($code !== ''){

        $stmt = $pdo->prepare("
           SELECT 
           t.id,
           t.code,
           t.status,
           d.tte_signed_path AS file_tte,
           s.name AS service,
           a.name AS applicant
           FROM tickets t
           LEFT JOIN services s ON t.service_id = s.id
           LEFT JOIN applicants a ON t.applicant_id = a.id
           LEFT JOIN documents_out d ON d.ticket_id = t.id
           WHERE t.code = ?
           LIMIT 1
        ");

        $stmt->execute([$code]);

        $ticket = $stmt->fetch(PDO::FETCH_ASSOC);

        if($ticket && isset($ticket['id'])){

            $st = $pdo->prepare("
            SELECT 
                new_status,
                comment,
                created_at
            FROM status_history
            WHERE ticket_id = ?
            ORDER BY created_at ASC
            ");

            $st->execute([$ticket['id']]);

            $history = $st->fetchAll(PDO::FETCH_ASSOC);

        }

    }

    render('track_result',[
        'ticket'=>$ticket,
        'history'=>$history
    ]);

}