<section class="card">
    <h3>Perlu Screening</h3>

    <?php if (empty($rows)): ?>
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
                    <th>Arahkan ke Bidang</th>
                    <th>Tolak</th>
                </tr>
            </thead>

            <tbody>
                <?php foreach ($rows as $row): ?>
                <tr>
                    <td><?= h($row['code']) ?></td>
                    <td><?= h($row['pemohon']) ?></td>
                    <td><?= h($row['layanan']) ?></td>

                    <td>
                        <?php if (!empty($row['file'])): ?>
                            <a href="download.php?file=<?= rawurlencode($row['file']) ?>" class="btn" target="_blank" rel="noopener">
                                Download
                            </a>
                            <div class="muted" style="margin-top:6px;font-size:12px;">
                                <?= h(basename($row['file'])) ?>
                            </div>
                        <?php else: ?>
                            <span class="muted">Tidak ada file</span>
                        <?php endif; ?>
                    </td>

                    <td>
                        <form method="post" action="?r=fo.accept" class="inline">
                            <input type="hidden" name="_csrf" value="<?= h(csrf_token()) ?>">
                            <input type="hidden" name="code" value="<?= h($row['code']) ?>">

                            <select name="bidang_id" required>
                                <option value="">-- Pilih Bidang --</option>
                                <?php foreach ($bidang as $b): ?>
                                    <option value="<?= h($b['id']) ?>"><?= h($b['name']) ?></option>
                                <?php endforeach; ?>
                            </select>

                            <button type="submit" class="btn primary">Terima</button>
                        </form>
                    </td>

                    <td>
                        <form method="post" action="?r=fo.reject" onsubmit="return confirm('Tolak tiket ini?')" class="inline">
                            <input type="hidden" name="_csrf" value="<?= h(csrf_token()) ?>">
                            <input type="hidden" name="code" value="<?= h($row['code']) ?>">
                            <input
                                type="text"
                                name="comment"
                                placeholder="Alasan penolakan (opsional)"
                                maxlength="255"
                                style="min-width:220px;"
                            >
                            <button type="submit" class="btn danger">Tolak</button>
                        </form>
                    </td>
                </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    </div>

    <?php endif; ?>
</section>