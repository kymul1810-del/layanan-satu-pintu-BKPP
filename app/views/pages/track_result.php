<section class="card">

<h3>Hasil Cek Status</h3>

<?php if(empty($ticket)): ?>

<p class="muted">Kode tiket tidak ditemukan.</p>

<?php else: ?>

<table class="table">

<tr>
<td><b>Kode Tiket</b></td>
<td><?=h($ticket['code'])?></td>
</tr>

<tr>
<td><b>Pemohon</b></td>
<td><?=h($ticket['applicant'])?></td>
</tr>

<tr>
<td><b>Layanan</b></td>
<td><?=h($ticket['service'])?></td>
</tr>

<tr>
<td><b>Status</b></td>
<td><?=h($ticket['status'])?></td>
</tr>

<tr>
<td><b>Dokumen TTE</b></td>
<td>

<?php if(!empty($ticket['file_tte'])): ?>

<a class="btn" 
href="download.php?file=<?= basename($ticket['file_tte']) ?>">
Download Berkas TTE
</a>

<?php else: ?>

<span class="muted">Dokumen belum tersedia</span>

<?php endif; ?>

</td>
</tr>

</table>

<h4>Riwayat Status</h4>

<?php if(empty($history)): ?>

<p class="muted">Belum ada riwayat.</p>

<?php else: ?>

<table class="table">

<thead>
<tr>
<th>Status</th>
<th>Catatan</th>
<th>Waktu</th>
</tr>
</thead>

<tbody>

<?php foreach($history as $h): ?>

<tr>
<td><?=h($h['new_status'])?></td>
<td><?=h($h['comment'])?></td>
<td><?=h($h['created_at'])?></td>
</tr>

<?php endforeach; ?>

</tbody>

</table>

<?php endif; ?>

<?php endif; ?>

</section>