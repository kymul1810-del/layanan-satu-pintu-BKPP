<section class="card">

<h3>Tiket Siap TTE</h3>

<?php if(!$rows): ?>

<p class="muted">Tidak ada tiket.</p>

<?php else: ?>

<div class="tablewrap">
<table>

<thead>
<tr>
<th>Kode</th>
<th>Pemohon</th>
<th>Layanan</th>
<th>Dokumen</th>
<th>Upload TTE</th>
</tr>
</thead>

<tbody>

<?php foreach($rows as $row): ?>

<tr>

<td><?=h($row['code'])?></td>
<td><?=h($row['pemohon'])?></td>
<td><?=h($row['layanan'])?></td>

<td>

<?php if(!empty($row['files'])): ?>

<?php foreach($row['files'] as $f): ?>

<a class="btn"
href="download.php?file=<?=rawurlencode($f['stored_path'])?>">
Download <?=h($f['original_name'])?>
</a>
<br>

<?php endforeach; ?>

<?php else: ?>

<span class="muted">Tidak ada file</span>

<?php endif; ?>

</td>

<td>

<form method="POST" action="?r=tte.upload" enctype="multipart/form-data">

<input type="hidden" name="_csrf" value="<?= csrf_token() ?>">
<input type="hidden" name="code" value="<?= $row['code'] ?>">

<input type="file" name="file_tte" accept=".pdf" required>

<button type="submit">Upload TTE</button>

</form>

</td>

</tr>

<?php endforeach; ?>

</tbody>

</table>
</div>

<?php endif; ?>

</section>