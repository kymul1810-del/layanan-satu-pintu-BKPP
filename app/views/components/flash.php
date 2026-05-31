<?php if($m=flash('ok')): ?>
  <div class="flash ok"><?=h($m)?></div>
<?php endif; ?>

<?php if($m=flash('err')): ?>
  <div class="flash err"><?=h($m)?></div>
<?php endif; ?>