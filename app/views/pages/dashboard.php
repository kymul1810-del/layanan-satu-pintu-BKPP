<section class="card">
    <a href="/uploads/<?= basename($file['stored_path']) ?>" download>
Download
</a>
    <h3>Tiket Terbaru</h3>
    <div class="tablewrap">
        <table>
            <thead>
                <tr><th>Kode</th><th>Status</th><th>Prioritas</th><th>Bidang</th><th>Waktu</th></tr>
            </thead>
        <tbody>
            <?php foreach($rows as $r): ?><tr><td><?=h($r['code'])?></td><td><?=h($r['status'])?></td><td><?=h($r['priority'])?></td><td><?=h($r['bidang'])?></td><td><?=h($r['created_at'])?></td></tr><?php endforeach; ?>
        </tbody>
        </table>
    </div>
</section>