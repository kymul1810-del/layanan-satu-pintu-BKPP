<section class="card">

<h3>Riwayat Tiket</h3>

<?php if(!$rows): ?>

<p class="muted">Belum ada riwayat.</p>

<?php else: ?>

<div class="tablewrap">
<table>

<thead>
<tr>
<th>Kode</th>
<th>Layanan</th>
<th>Status</th>
<th>Tanggal</th>
</tr>
</thead>

<tbody>

<?php foreach($rows as $row): ?>

<tr>

<td><?=h($row['code'])?></td>

<td><?=h($row['layanan'])?></td>

<td><?=h($row['status'])?></td>

<td><?=h($row['updated_at'])?></td>

</tr>

<?php endforeach; ?>

</tbody>

</table>
</div>

<?php endif; ?>

</section>