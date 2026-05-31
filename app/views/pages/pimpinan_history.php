<section class="card">

<h3>Riwayat TTE</h3>

<?php if(!$rows): ?>

<p class="muted">Belum ada riwayat.</p>

<?php else: ?>

<div class="tablewrap">
<table>

<thead>
<tr>
<th>Kode</th>
<th>Pemohon</th>
<th>Layanan</th>
<th>Dokumen TTE</th>
<th>Tanggal</th>
</tr>
</thead>

<tbody>

<?php foreach($rows as $row): ?>

<tr>

<td><?=h($row['code'])?></td>
<td><?=h($row['pemohon'])?></td>
<td><?=h($row['layanan'])?></td>

<td>

<a class="btn"
href="download.php?file=<?=rawurlencode($row['tte_signed_path'])?>">
Download
</a>

</td>

<td><?=h($row['updated_at'])?></td>

</tr>

<?php endforeach; ?>

</tbody>

</table>
</div>

<?php endif; ?>

</section>