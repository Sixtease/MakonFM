var MakonFM = {
    MEDIA_BASE:    'http://commondatastorage.googleapis.com/karel-makon-mp3/',
//    SUBTITLE_BASE: 'http://commondatastorage.googleapis.com/karel-makon-sub/',
    SUBTITLE_BASE: '/static/subs/',
    WORDS_PRE: 10,
    WORDS_POST: 10,
    CURRENT_INDEX: 0,
    subtitles: {}
};


$('.track-menu li').click(function(evt) {
    if ($(evt.target).is('li,li>:header')) {} else return;
    evt.stopPropagation();
    $(this).toggleClass('show');
});
$('.track-menu li>a').click(function(evt) {
    var fn = $(this).text();
    $('.jp-title li').text(fn);
    $('#jquery_jplayer_1').jPlayer('setMedia', {
        mp3: MakonFM.MEDIA_BASE + fn
    });
    $('#jquery_jplayer_1').jPlayer('play');
    MakonFM.get_subs(fn);
});

$("#jquery_jplayer_1").jPlayer({
    swfPath: "/static",
    supplied: "mp3",
    timeupdate: function(evt) {
        MakonFM.upd_sub(evt.jPlayer.status.currentTime, MakonFM.subs);
        ;;; $('#ts').val(evt.jPlayer.status.currentTime);
    }
});

MakonFM._i_by_ts = function(ts, subs, i) {
    if (!i) i = MakonFM.CURRENT_INDEX;
    if (subs[i].timestamp == ts) return i;
    if (ts >= subs[subs.length-1].timestamp) return subs.length-1;
    while (subs[i++].timestamp < ts) { }
    while (subs[--i].timestamp > ts) { }
    return i;
}

MakonFM._add_st_word = function(sub, where) {
    var $word = $('<span>')
    .addClass('Word')
    .attr('data-timestamp', sub.timestamp)
    .text(sub.occurrence);
    
    if      (where.onhead) $word.prependTo   (where.onhead);
    else if (where.ontail) $word.appendTo    (where.ontail);
    else if (where.after)  $word.insertAfter (where.after );
    else if (where.before) $word.insertBefore(where.before);
    else throw ('no where specified to _add_st_word');
    
    $word.after(' ');
}

MakonFM.upd_sub = function (ts, subs, i) {
    var $st = $('.subtitles');
    var $cur_have = $st.find('.Word.cur');
    var cur_have = $cur_have.data('timestamp');
    var next_have = $cur_have.next().data('timestamp');
    if (cur_have > ts && next_have < ts) return;
    if (!subs) subs = MakonFM.subs;
    i = MakonFM._i_by_ts(ts, subs, i);
    MakonFM.CURRENT_INDEX = i;
    var sub = subs[i];
    
    var first_have = $st.find('.Word:first').data('timestamp');
    if (first_have === undefined) {
        MakonFM._add_st_word(sub, {onhead:$st});
        first_have = sub.timestamp;
    }
    var first_need = subs[Math.max(0,i-MakonFM.WORDS_PRE)].timestamp;
    var first_have_i = MakonFM._i_by_ts(first_have, subs, i);
    var new_first;
    
    // unshift words missing on start
    while (first_need < first_have) {
        if (--first_have_i < 0) break;
        new_first = subs[first_have_i];
        MakonFM._add_st_word(new_first, {onhead:$st});
        first_have = new_first.timestamp;
    }
    
    // shift words redundant on start
    while (first_need > first_have) {
        $st.find('.Word:first').remove();
        new_first = $st.find('.Word:first');
        if (new_first.length == 0) break;
        first_have = new_first.data('timestamp');
    }
    
    var last_have = $st.find('.Word:last' ).data('timestamp');
    var last_need = subs[Math.min(i+MakonFM.WORDS_POST,subs.length-1)].timestamp;
    var last_have_i = MakonFM._i_by_ts(last_have, subs, i);
    var new_last;
    
    // push words missing on end
    while (last_need > last_have) {
        if (++last_have_i > subs.length-1) break;
        new_last = subs[last_have_i];
        MakonFM._add_st_word(new_last, {ontail:$st});
        last_have = new_last.timestamp;
    }
    
    // pop words redundant on end
    while (last_need < last_have) {
        $st.find('.Word:last').remove();
        new_last = $st.find('.Word:last');
        if (new_last.length == 0) break;
        last_have = new_last.data('timestamp');
    }
    
    $st.find('.Word').removeClass('cur');
    $st.find('.Word[data-timestamp="'+sub.timestamp+'"]').addClass('cur');
};
MakonFM.clear_subs = function() {
    MakonFM.subs = [];
    $('.subtitles').empty();
};

MakonFM.show_word_info = function(word, $cont, subs) {
    if (!$cont || !$cont.length) {
        $cont = $('.curword');
    }
    if (!subs) subs = MakonFM.subs;
    var ts;
    if ($.isNumeric(word)) {
        ts = word;
    }
    else if ((word instanceof HTMLElement) || (word instanceof jQuery)) {
        ts = $(word).data('timestamp');
    }
    if (ts !== undefined) {
        var i = MakonFM._i_by_ts(ts, subs);
        word = subs[i];
    }
    $cont.find('dd.occurrence').text(word.occurrence);
    $cont.find('dd.fonet'     ).text(word.fonet     );
    $cont.find('dd.wordform  ').text(word.wordform  );
};

$('.subtitles .Word').live('click', function(evt) {
    if (evt.button != 0) return;
    var ts = $(evt.target).data('timestamp');
    MakonFM.show_word_info(evt.target);
});

MakonFM.get_subs = function(fn) {
    var stem = fn.replace(/(?:\.(?:mp3|ogg|sub(?:\.js)?))?$/, '');
    if (MakonFM.subtitles[stem]) {
        MakonFM.subs = MakonFM.subtitles[stem];
        return;
    }
    MakonFM.clear_subs();
    
    $('<script>')
    .attr({
        type: 'text/javascript',
        src: MakonFM.SUBTITLE_BASE + stem + '.sub.js'
    })
    .appendTo('body')
    .remove();
};
$(document).bind('got_subtitles.MakonFM', function(evt, arg) {
    MakonFM.subtitles[arg.fn] = MakonFM.subs = arg.data;
});
