<?php $canAccessDiscussion = $this->Acl->canAccess('threads', 'view') ?>
<div id="eventToggleButtons">
    <button class="btn btn-inverse toggle-left qet" id="pivots_toggle" data-toggle-type="pivots">
        <span class="fas fa-minus" title="<?php echo __('Toggle pivot graph');?>" role="button" tabindex="0" aria-label="<?php echo __('Toggle pivot graph');?>"></span><?php echo __('Pivots');?>
    </button>
    <button class="btn btn-inverse toggle qet" id="galaxies_toggle" data-toggle-type="galaxies">
        <span class="fas fa-minus" title="<?php echo __('Toggle galaxies');?>" role="button" tabindex="0" aria-label="<?php echo __('Toggle galaxies');?>"></span><?php echo __('Galaxy');?>
    </button>
    <button class="btn btn-inverse toggle qet" id="eventgraph_toggle" data-toggle-type="eventgraph">
        <span class="fas fa-plus" title="<?php echo __('Toggle Event graph');?>" role="button" tabindex="0" aria-label="<?php echo __('Toggle Event graph');?>"></span><?php echo __('Event graph');?>
    </button>
    <button class="btn btn-inverse toggle qet" id="eventtimeline_toggle" data-toggle-type="eventtimeline">
        <span class="fas fa-plus" title="<?php echo __('Toggle Event timeline');?>" role="button" tabindex="0" aria-label="<?php echo __('Toggle Event timeline');?>"></span><?php echo __('Event timeline');?>
    </button>
    <button class="btn btn-inverse toggle qet" id="correlationgraph_toggle" data-toggle-type="correlationgraph" data-load-url="<?= $baseurl ?>/events/viewGraph/<?= h($event['Event']['id']) ?>">
        <span class="fas fa-plus" title="<?php echo __('Toggle Correlation graph');?>" role="button" tabindex="0" aria-label="<?php echo __('Toggle Correlation graph');?>"></span><?php echo __('Correlation graph');?>
    </button>
    <button class="btn btn-inverse toggle qet" id="attackmatrix_toggle" data-toggle-type="attackmatrix" data-load-url="<?= $baseurl; ?>/events/viewGalaxyMatrix/<?= h($event['Event']['id']) ?>/mitre-attack/event/1/<?= $extended ? '1' : '0'?>">
        <span class="fas fa-plus" title="<?php echo __('Toggle Galaxy matrix');?>" role="button" tabindex="0" aria-label="<?php echo __('Toggle Galaxy matrix');?>"></span><?php echo __('Galaxy matrix');?>
    </button>
    <button class="btn btn-inverse toggle qet" id="eventreport_toggle" data-toggle-type="eventreport">
        <span class="fas fa-plus" title="<?php echo __('Toggle reports');?>" role="button" tabindex="0" aria-label="<?php echo __('Toggle reports');?>"></span><?php echo __('Event reports');?>
    </button>
    <button class="btn btn-inverse <?= $canAccessDiscussion ? 'toggle' : 'toggle-right' ?> qet" id="attributes_toggle" data-toggle-type="attributes">
        <span class="fas fa-minus" title="<?php echo __('Toggle attributes');?>" role="button" tabindex="0" aria-label="<?php echo __('Toggle attributes');?>"></span><?php echo __('Attributes');?>
    </button>
    <?php if ($canAccessDiscussion): ?>
    <button class="btn btn-inverse toggle-right qet" id="discussions_toggle" data-toggle-type="discussions">
        <span class="fas fa-minus" title="<?php echo __('Toggle discussions');?>" role="button" tabindex="0" aria-label="<?php echo __('Toggle discussions');?>"></span><?php echo __('Discussion');?>
    </button>
    <?php endif; ?>
    <span style="display:inline-flex;align-items:center;margin-left:8px;gap:5px;">
        <button class="btn btn-inverse" id="audio_explain_btn"
                title="<?= __('Explain this event as audio') ?>"
                onclick="explainEventAsAudio()">
            <span class="fas fa-volume-up" id="audio_explain_icon"
                  role="button" tabindex="0"
                  aria-label="<?= __('Explain this event as audio') ?>"></span><?= __('Explain') ?>
        </button>
        <span style="display:inline-flex;align-items:center;gap:4px;
                     font-size:11px;color:#ccc;vertical-align:middle;">
            <span><?= __('Tmpl') ?></span>
            <label style="position:relative;display:inline-block;
                          width:34px;height:18px;margin:0;cursor:pointer;"
                   title="<?= __('Switch between template and LLM explanation') ?>">
                <input type="checkbox" id="audio_llm_mode"
                       style="opacity:0;width:0;height:0;position:absolute;">
                <span id="audio_mode_track"
                      style="position:absolute;top:0;left:0;right:0;bottom:0;
                             background:#555;border-radius:18px;transition:.25s;">
                    <span id="audio_mode_knob"
                          style="position:absolute;height:12px;width:12px;
                                 left:3px;bottom:3px;background:#fff;
                                 border-radius:50%;transition:.25s;"></span>
                </span>
            </label>
            <span><?= __('LLM') ?></span>
            <span id="audio_llm_status"
                  style="display:inline-block;width:8px;height:8px;
                         border-radius:50%;background:#555;
                         vertical-align:middle;cursor:default;"
                  title="<?= __('LLM status unknown — click Explain to test') ?>"></span>
        </span>
    </span>
</div>
<br>
<br>
<div id="pivots_div">
    <?php if (count($allPivots) > 1) echo $this->element('pivot'); ?>
</div>
<div id="galaxies_div">
    <span class="title-section"><?= __('Galaxies') ?></span>
    <?= $this->element('galaxyQuickViewNew', [
        'data' => $event['Galaxy'],
        'event' => $event,
        'target_id' => $event['Event']['id'],
        'target_type' => 'event'
    ]); ?>
</div>
<div id="eventgraph_div" class="info_container_eventgraph_network" style="display: none;" data-fullscreen="false">
    <?php echo $this->element('view_event_graph'); ?>
</div>
<div id="eventtimeline_div" class="info_container_eventtimeline" style="display: none;" data-fullscreen="false">
    <?php echo $this->element('view_timeline'); ?>
</div>
<div id="correlationgraph_div" class="info_container_eventgraph_network" style="display: none;" data-fullscreen="false">
</div>
<div id="attackmatrix_div" class="info_container_eventgraph_network" style="display: none; overflow: hidden;" data-fullscreen="false">
</div>
<div id="eventreport_div" style="display: none;">
    <span class="report-title-section"><?php echo __('Event Reports');?></span>
    <div id="eventreport_content"></div>
</div>
<div id="clusterrelation_div" class="info_container_eventgraph_network" style="display: none;" data-fullscreen="false">
</div>
<div id="attributes_div">
    <?= $this->element('eventattribute'); ?>
</div>
<div id="discussions_div">
</div>
</div>
<script>
$(function () {
<?php
    if (!Configure::check('MISP.disable_event_locks') || !Configure::read('MISP.disable_event_locks')) {
        echo sprintf(
            "queryEventLock(%s, %s);",
            (int)$event['Event']['id'],
            (int)$event['Event']['timestamp']
        );
    }
?>
$(document.body).tooltip({
    selector: 'span[title], td[title], time[title]',
    placement: 'top',
    container: 'body',
    delay: { show: 500, hide: 100 }
}).on('shown', function() {
    $('.tooltip').not(":last").remove();
});

<?php if ($this->Acl->canAccess('threads', 'view')): ?>
$.get("<?php echo $baseurl; ?>/threads/view/<?php echo h($event['Event']['id']); ?>/true", function(data) {
    $("#discussions_div").html(data);
});
<?php endif; ?>

$.get("<?php echo $baseurl; ?>/eventReports/index/event_id:<?= h($event['Event']['id']); ?>/index_for_event:1<?= $extended ? '/extended_event:1' : ''?><?= $extending ? '/extending_event:1' : ''?>", function(data) {
    $("#eventreport_content").html(data);
    if ($('#eventreport_content table tbody > tr').length) { // open if contain a report
        $('#eventreport_toggle').click()
    }
});
});

// Toggle slider knob animation
$('#audio_llm_mode').on('change', function() {
    var on = this.checked;
    $('#audio_mode_knob').css('left', on ? '19px' : '3px');
    $('#audio_mode_track').css('background', on ? '#5bc0de' : '#555');
});

var mispEventAudio = (function() {
    var threatLevels = {1: 'High', 2: 'Medium', 3: 'Low', 4: 'Undefined'};
    var distributions = {
        0: 'your organisation only',
        1: 'this community only',
        2: 'connected communities',
        3: 'all communities',
        4: 'a sharing group'
    };
    var d = {
        id:             <?= (int)$event['Event']['id'] ?>,
        info:           <?= json_encode(h($event['Event']['info'])) ?>,
        date:           <?= json_encode(h($event['Event']['date'])) ?>,
        orgc:           <?= json_encode(h($event['Event']['Orgc']['name'])) ?>,
        threatLevel:    <?= (int)$event['Event']['threat_level_id'] ?>,
        distribution:   <?= (int)$event['Event']['distribution'] ?>,
        attributeCount: <?= (int)($event['Event']['attribute_count'] ?? 0) ?>,
        objectCount:    <?= (int)count($event['Object'] ?? []) ?>
    };

    function buildSummary() {
        var s = 'Event ' + d.id + ': ' + d.info + '. ';
        s += 'Created on ' + d.date + ' by ' + d.orgc + '. ';
        s += 'Threat level: ' + (threatLevels[d.threatLevel] || 'unknown') + '. ';
        s += 'Distribution: ' + (distributions[d.distribution] || 'unknown') + '. ';
        if (d.attributeCount > 0) {
            s += 'Contains ' + d.attributeCount + ' attribute' +
                (d.attributeCount !== 1 ? 's' : '') + '. ';
        }
        if (d.objectCount > 0) {
            s += d.objectCount + ' object' +
                (d.objectCount !== 1 ? 's' : '') + '. ';
        }
        return s;
    }

    return {
        buildSummary: buildSummary,
        getId: function() { return d.id; }
    };
})();

function explainEventAsAudio() {
    if (!window.speechSynthesis) {
        showMessage('warning',
            <?= json_encode(__('Your browser does not support speech synthesis.')) ?>);
        return;
    }

    var $icon = $('#audio_explain_icon');
    var $btn  = $('#audio_explain_btn');

    // Stop if already speaking
    if (window.speechSynthesis.speaking) {
        window.speechSynthesis.cancel();
        $icon.removeClass('fa-stop fa-spinner fa-spin').addClass('fa-volume-up');
        $btn.attr('title', <?= json_encode(__('Explain this event as audio')) ?>);
        return;
    }

    function speak(text) {
        var utt = new SpeechSynthesisUtterance(text);
        utt.onend = utt.onerror = function() {
            $icon.removeClass('fa-stop').addClass('fa-volume-up');
            $btn.attr('title', <?= json_encode(__('Explain this event as audio')) ?>);
        };
        $icon.removeClass('fa-volume-up fa-spinner fa-spin').addClass('fa-stop');
        $btn.attr('title', <?= json_encode(__('Stop audio')) ?>);
        window.speechSynthesis.speak(utt);
    }

    // Update the persistent status dot next to the LLM label.
    // state: 'idle' | 'connecting' | 'ok' | 'error'
    function setLlmStatus(state, message) {
        var $dot = $('#audio_llm_status');
        var colors = {idle: '#555', connecting: '#5bc0de', ok: '#5cb85c', error: '#d9534f'};
        var titles = {
            idle:       <?= json_encode(__('LLM status unknown — click Explain to test')) ?>,
            connecting: <?= json_encode(__('Connecting to Ollama…')) ?>,
            ok:         <?= json_encode(__('LLM responded successfully')) ?>,
            error:      message || <?= json_encode(__('LLM connection failed')) ?>
        };
        $dot.css('background', colors[state] || colors.idle)
            .attr('title', titles[state] || titles.idle);
    }

    var useLlm = $('#audio_llm_mode').prop('checked');
    if (useLlm) {
        $icon.removeClass('fa-volume-up').addClass('fa-spinner fa-spin');
        setLlmStatus('connecting');
        $.ajax({
            url: baseurl + '/events/explainAsAudio/' + mispEventAudio.getId()
                + '?mode=llm',
            type: 'GET',
            dataType: 'json',
            success: function(data) {
                $icon.removeClass('fa-spinner fa-spin').addClass('fa-volume-up');
                if (data && data.error) {
                    setLlmStatus('error', data.error);
                    showMessage('warning', data.error);
                    return;
                }
                setLlmStatus('ok');
                speak(data.text);
            },
            error: function(xhr) {
                $icon.removeClass('fa-spinner fa-spin').addClass('fa-volume-up');
                var msg = <?= json_encode(__('Could not reach the LLM endpoint.')) ?>;
                setLlmStatus('error', msg);
                showMessage('warning', msg);
            }
        });
    } else {
        speak(mispEventAudio.buildSummary());
    }
}
</script>
