var MakonFM = {
    MEDIA_BASE:    'http://commondatastorage.googleapis.com/karel-makon-mp3/',
//    SUBTITLE_BASE: 'http://commondatastorage.googleapis.com/karel-makon-sub/',
    SUBTITLE_BASE: '/static/subs/',
    WORDS_PRE: 10,
    WORDS_POST: 10,
    CURRENT_INDEX: 0,
    subtitles: {}
};

$(document).ready(function() {
    var lh = MakonFM.SUB_LINE_HEIGHT = $('.subtitles').css('lineHeight').replace(/\D+/g, '');
    var lc = MakonFM.SUB_LINE_CNT = Math.round($('.subtitles').height() / lh);
    MakonFM.SUB_MIDDLE_LINE = Math.floor((lc+1) / 2) - 1;
});

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
};

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
    
    if (where.after) $word.before(' ');
    else             $word.after (' ');

    return $word;
};

MakonFM.upd_sub = function (ts, subs, i) {
    var $st = $('.subtitles');
    var $cur_have = $st.find('.Word.cur');
    var cur_have = $cur_have.data('timestamp');
    var next_have = $cur_have.next().data('timestamp');
    if (cur_have < ts && next_have > ts) return;
    
    var LEFT = -1;
    var RIGHT = 1;
    
    if (!subs) subs = MakonFM.subs;
    i = MakonFM._i_by_ts(ts, subs, i);
    MakonFM.CURRENT_INDEX = i;
    var sub = subs[i];
    
    var $new_cur = $st.find('.Word[data-timestamp="'+sub.timestamp+'"]');
    if ($new_cur == $cur_have) return;
    var $stopper_left = null;
    var $stopper_right = null;
    
    if ($new_cur.length == 0) {
        var $first_have = $st.find('.Word:first');
        if ($first_have.length == 0) {
            $new_cur = MakonFM._add_st_word(sub, {onhead:$st});
        }
        else {
            var first_have = $first_have.data('timestamp');
            if (sub.timestamp < first_have) {
                $new_cur = MakonFM._add_st_word(sub, {before:$first_have});
                $stopper_right = $first_have;
            }
            else {
                var $last_have = $st.find('.Word:last');
                var last_have = $last_have.data('timestamp');
                if (sub.timestamp > last_have) {
                    $new_cur = MakonFM._add_st_word(sub, {after:$last_have});
                    $stopper_left = $last_have;
                }
                else throw ('No current and not less than leftmost and not more than rightmost?');
            }
        }
        add_adjacent({ant: $new_cur, dir: LEFT,  stopper: $stopper_left });
        add_adjacent({ant: $new_cur, dir: RIGHT, stopper: $stopper_right});
    }
    else {
        var cur_lineno = MakonFM._lineno_of($new_cur);
        var lines_to_scroll = cur_lineno - MakonFM.SUB_MIDDLE_LINE;
        scroll(lines_to_scroll);
    }
    
    $st.find('.Word').removeClass('cur');
    $new_cur.addClass('cur');

    function add_adjacent(arg) {
        var dir = arg.dir;
        if (!dir) throw('No dir given to add_adjacent in arg', arg);
        var $ant = arg.ant;
        if (!$ant || !$ant.length) throw('No ant[ecedant] given to add_adjacent in arg', arg);
        var $stopper = arg.stopper;
        var j = i;
        var $added = $ant;
        if ($stopper) {
            var stop_ts = $stopper.data('timestamp');
        }
        if (dir === LEFT) {
            if ($stopper) {
                var $br = $('<br>')
                .insertAfter($stopper);
            }
            var shifted_ref_lineno = MakonFM._lineno_of($ant) + MakonFM.SUB_MIDDLE_LINE;
            while (MakonFM._lineno_of($ant) < shifted_ref_lineno) {
                j--;
                if (j<0) break;
                if (stop_ts && subs[j].timestamp == stop_ts) {
                    $br.remove();
                    break;
                }
                $added = MakonFM._add_st_word(subs[j], {before:$added});
            }
            if ($stopper) {
                if ($br) {
                    $br.prevAll().add($br).remove();
                }
                else {
                    scroll(MakonFM._lineno_of($ant) - MakonFM.SUB_MIDDLE_LINE);
                }
            }
        }
        else if (dir == RIGHT) {
            var do_add = true;
            var got_too_much = false;
            while (MakonFM._lineno_of($added) < MakonFM.SUB_LINE_CNT) {
                j++;
                if (j >= subs.length) break;
                if (!do_add) {
                    $added = $added.next();
                    $stopper = $added.next();
                    continue;
                }
                if (stop_ts && subs[j].timestamp == stop_ts) {
                    do_add = false;
                    continue;
                }
                $added = MakonFM._add_st_word(subs[j], {after:$added});
                got_too_much = true;
            }
            if (got_too_much) $added.remove();
            if ($stopper) {
                $stopper.nextAll().add($stopper).remove();
            }
        }
    }
    function scroll(n) {
        if (n == 0) return;
        if (n < 0) return scrollup(-n);
        if (n > 0) return scrolldown(n);
        console.log('bad n:',n);
    }
    function scrollup(n) {
        if (n === undefined) n = 1;
        var $start = $st.find('.Word:first');
        var i = MakonFM._i_by_ts($start.data('timestamp'), subs);
        var $added = $start;
        while (MakonFM._lineno_of($start) < n) {
            i--;
            if (i < 0) break;
            $added = MakonFM._add_st_word(subs[i], {before:$added});
        }
        var $last = $st.find('.Word:last');
        while (MakonFM._lineno_of($last) >= MakonFM.SUB_LINE_CNT) {
            var $to_remove = $last;
            $last = $last.prev();
            $to_remove.remove();
        };
    }
    function scrolldown(n) {
        if (n === undefined) n = 1;
        var $words = $st.find('.Word');
        var lines_added = 0;
        
        var $added = $words.last();
        var i = MakonFM._i_by_ts($added.data('timestamp'), subs);
        var prev_lineno;
        var cur_lineno;
        cur_lineno = prev_lineno = MakonFM._lineno_of($added);
        while (cur_lineno < MakonFM.SUB_LINE_CNT + n) {
            i++;
            if (i >= subs.length) break;
            $added = MakonFM._add_st_word(subs[i], {after:$added});
            
            cur_lineno = MakonFM._lineno_of($added);
            if (prev_lineno < cur_lineno) lines_added++;
            prev_lineno = cur_lineno;
        }
        // last line is just one word, delete it
        lines_added--;
        $added.remove();
        
        var $to_remove = $words.first();
        var i = 1;
        var $w;
        while (MakonFM._lineno_of($w=$words.eq(i++)) < lines_added) {
            $to_remove = $to_remove.add($w);
        }
        $to_remove.remove();
    }
};


MakonFM._lineno_of = function($word, lh) {
    if (lh === undefined) {
        lh = MakonFM.SUB_LINE_HEIGHT;
    }
    var pos = $word.position().top;
    return Math.floor((pos+lh/2)/lh);
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

MakonFM.get_selected_words = function() {
    var $rv;
    var range;
    if (window.getSelection) {
        var sel = getSelection();
        var sel_str = sel.toString();
        if (sel_str.length == 0) return;
        if (!/\S/.test(sel_str)) return;
        
        range = sel.getRangeAt(0);
        
        var sc = range.startContainer;
        function try_el($el,l) {
            if ($el.is('.Word')) {console.log(l,$el);return $el;}
            else return false;
        }
        if      ($rv = try_el($(sc),'sc')) { }
        else if ($rv = try_el($(sc).parent(),'scparent')) { }
        else if ($rv = try_el($(sc.nextSibling),'scnext')) { }
        else throw ('Failed to find start word');
        
        var ec = range.endContainer;
        var $end;
        if      ($end = try_el($(ec),'ec')) { }
        else if ($end = try_el($(ec).parent(),'ecparent')) {
            if (range.endOffset == 0) $end = $end.prev();
        }
        else if ($end = try_el($(ec.previousSibling),'ecprev')) { }
        else throw ('Failed to find end word');
        
        var end_ts = $end.data('timestamp');
        if (!end_ts) throw ('No end timestamp');
        if ($rv.data('timestamp') <= end_ts) { }
        else throw ("start word does't have lesser timestamp than end word");
        
        for (var $last = $rv.last(); !$last.is($end); $last = $next) {
            var $next = $last.next();
            if ($next.length == 0) {
                throw ('seek-selection-end reached subtitle end');
            }
            if ($next.data('timestamp') > end_ts) {
                throw ('seek-selection-end reached beyond end node');
            }
            $rv = $rv.add($next);
        }
    }
    /*else if (document.getSelection) {
        t = document.getSelection();
    }*/
    else if (document.selection) {
        $rv = $(document.selection.createRange().htmlText).filter('.Word');
    }
    return $rv;
};

$('.subtitles').bind('mouseup', function(evt) {
    var $sel = MakonFM.get_selected_words();
    if ($sel && $sel.length) {} else return;
    $sel.hide();
    var $ta = $('<textarea>')
    .addClass('subedit')
    .val($.map($.makeArray($sel),function(x){return $(x).text()}).join(' '))
    .insertBefore($sel.first())
    .blur(function(){
        $(this).remove();
        $sel.show();
        $('.subtitles').removeClass('edited');
    });
    $('.subtitles').addClass('edited');
});
