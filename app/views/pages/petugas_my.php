<section class="card">

<h3>Tiket Saya</h3>

<?php if(!$rows): ?>

<p class="muted">Tidak ada tiket.</p>

<?php else: ?>

<div class="tablewrap">
<table>

<thead>
<tr>
<th>Kode</th>
<th>Layanan</th>
<th>Status</th>
<th>Dokumen</th>
<th>Aksi</th>
</tr>
</thead>

<tbody>

<?php foreach($rows as $row): ?>

<tr>

<td><?=h($row['code'])?></td>

<td><?=h($row['layanan'])?></td>

<td><?=h($row['status'])?></td>

<td>

<?php if(!empty($row['files'])): ?>

<?php foreach($row['files'] as $f): ?>

<a class="btn"
href="download.php?file=<?=basename($f['stored_path'])?>">
Download <?=h($f['original_name'])?>
</a>
<br>

<?php endforeach; ?>

<?php else: ?>

<span class="muted">Tidak ada file</span>

<?php endif; ?>

</td>

<td>

<!-- SIAP TTE -->

<form method="post" action="?r=ticket.upd" class="inline">

<input type="hidden" name="_csrf" value="<?=h(csrf_token())?>">

<input type="hidden" name="code" value="<?=h($row['code'])?>">

<input type="hidden" name="new_status" value="SIAP_TTD">

<input type="hidden" name="_back" value="petugas/my">

<button class="btn primary">Siap TTE</button>

</form>


<!-- TOLAK -->

<form method="post" action="?r=ticket.upd"
onsubmit="return confirm('Tolak tiket ini?')"
class="inline">

<input type="hidden" name="_csrf" value="<?=h(csrf_token())?>">

<input type="hidden" name="code" value="<?=h($row['code'])?>">

<input type="hidden" name="new_status" value="DITOLAK">

<input type="hidden" name="_back" value="petugas/my">

<button class="btn danger">Tolak</button>

</form>

</td>

</tr>

<?php endforeach; ?>

</tbody>

</table>
</div>

<?php endif; ?>

</section>