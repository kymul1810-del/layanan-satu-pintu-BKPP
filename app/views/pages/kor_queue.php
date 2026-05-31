<section class="card">

<h3>Antrian Tiket Bidang</h3>

<?php if(!$rows): ?>

<p class="muted">Tidak ada tiket.</p>

<?php else: ?>

<div class="tablewrap">
<table>

<thead>
<tr>
<th>Kode</th>
<th>Layanan</th>
<th>Prioritas</th>
<th>Dokumen</th>
<th>Assign</th>
</tr>
</thead>

<tbody>

<?php foreach($rows as $row): ?>

<tr>

<td><?=h($row['code'])?></td>
<td><?=h($row['layanan'])?></td>
<td><?=h($row['priority'])?></td>

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

<form method="POST" action="?r=kor.assign">
    <input type="hidden" name="_csrf" value="<?= csrf_token() ?>">
    <input type="hidden" name="code" value="<?= h($row['code']) ?>">

    <select name="petugas_id" required>
        <option value="">-- Pilih Petugas --</option>
        <?php foreach($petugas as $p): ?>
            <option value="<?= h($p['id']) ?>">
                <?= h($p['name']) ?><?= !empty($p['jenis_petugas']) ? ' - '.h($p['jenis_petugas']) : '' ?>
            </option>
        <?php endforeach; ?>
    </select>

    <button type="submit" class="btn primary">Assign</button>
</form>

</td>

</tr>

<?php endforeach; ?>

</tbody>

</table>
</div>

<?php endif; ?>

</section>