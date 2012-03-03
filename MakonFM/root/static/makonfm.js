var MakonFM = new (function() {
    var m = this;
//    m.MEDIA_BASE =    'http://commondatastorage.googleapis.com/karel-makon-mp3/';
    m.MEDIA_BASE =    '/static/audio/';
//    m.SUBTITLE_BASE = 'http://commondatastorage.googleapis.com/karel-makon-sub/';
    m.SUBTITLE_BASE = '/static/subs/';
    m.SEND_SUBTITLES_URL = '/subsubmit/';
    m.WORDS_PRE = 10;
    m.WORDS_POST = 10;
    m.CURRENT_INDEX = 0;
    m.subtitles = {};
    var _current_filestem = ko.observable('');
    var _no_file_str = 'nepřehrává se';
    m.current_file = ko.computed({
        read: function() {
            return _current_filestem() || _no_file_str;
        },
        write: function(fn) {
            var stem = fn.replace(/\.(mp3|ogg|sub\.js)$/, '');
            _current_filestem(stem);
        }
    });
    m.player_time = ko.observable(0);
    m.inspected_word = ko.observable(null);
    m.editation_active = ko.observable(false);
    m.edited_subtitles = ko.observable(null);
    m.edited_subtitles.str = ko.computed({
        read: function() {
            var es = m.edited_subtitles();
            if (es === null) return '';
            return $.map(
                $.makeArray(es),
                function(x) { return $(x).text(); }
            ).join(' ');
        },
        write: function(str) {
            m.editation_active(false);
            var $words = m.edited_subtitles();
            $words.addClass('corrected');   // XXX
            m._mark_subtitles_as_corrected($words);
            m.send_subtitles($words, str);
        }
    });

    m.current_file.subscribe(function(fn) {
        MakonFM.jPlayer('setMedia', {
            mp3: MakonFM.MEDIA_BASE + fn + '.mp3'
        });
        MakonFM.jPlayer('play');
        MakonFM.get_subs(fn);
    });

    m.edited_subtitles.subscribe(function($sel) {
        $('.subedit')
        .insertBefore($sel.first())
        .focus();
    });

    m.editation_active.subscribe(function(active) {
        if (active) { }
        else $('.subedit').val('').appendTo('.subedit-shed');
    });

    return m;
});

$(document).ready(function() {
    var lh = MakonFM.SUB_LINE_HEIGHT = $('.subtitles').css('lineHeight').replace(/\D+/g, '');
    var lc = MakonFM.SUB_LINE_CNT = Math.round($('.subtitles').height() / lh);
    MakonFM.SUB_MIDDLE_LINE = Math.floor((lc+1) / 2) - 1;

    MakonFM.jPlayer = function(a,b) { $('#jquery_jplayer_1').jPlayer(a,b); };
    MakonFM.jPlayer({
        swfPath: "/static",
        supplied: "mp3",
        timeupdate: function(evt) {
            MakonFM.upd_sub(evt.jPlayer.status.currentTime, MakonFM.subs);  // XXX
            MakonFM.player_time(evt.jPlayer.status.currentTime);
        }
    });

    ko.applyBindings(MakonFM);
});

$('.track-menu li').click(function(evt) {
    if ($(evt.target).is('li,li>:header')) {} else return;
    evt.stopPropagation();
    $(this).toggleClass('show');
});
$('.track-menu li>a').click(function(evt) {
    var fn = $(this).text();
    MakonFM.current_file(fn);
});

MakonFM._i_by_ts = function(ts, subs, i) {
    if (!i) i = MakonFM.CURRENT_INDEX;
    if (subs[i].timestamp == ts) return i;
    if (ts >= subs[subs.length-1].timestamp) return subs.length-1;
    while (subs[i++].timestamp < ts) { }
    while (subs[--i].timestamp > ts) { }
    return i;
};

// XXX
MakonFM._add_st_word = function(sub, where) {
    var $word = $('<span>')
    .addClass('word')
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

// XXX buďto subscribnout k observablu nebo udělat binding? nebo třeba to půjde rychle naivně
MakonFM.upd_sub = function (ts, subs, i) {
    var $st = $('.subtitles');
    var $cur_have = $st.find('.word.cur');
    var cur_have = $cur_have.data('timestamp');
    var next_have = $cur_have.next().data('timestamp');
    if (cur_have < ts && next_have > ts) return;
    
    var LEFT = -1;
    var RIGHT = 1;
    
    if (!subs) subs = MakonFM.subs;
    i = MakonFM._i_by_ts(ts, subs, i);
    MakonFM.CURRENT_INDEX = i;
    var sub = subs[i];
    
    var $new_cur = $st.find('.word[data-timestamp="'+sub.timestamp+'"]');
    if ($new_cur == $cur_have) return;
    var $stopper_left = null;
    var $stopper_right = null;
    
    if ($new_cur.length == 0) {
        var $first_have = $st.find('.word:first');
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
                var $last_have = $st.find('.word:last');
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
    
    $st.find('.word').removeClass('cur');
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
        var $start = $st.find('.word:first');
        var i = MakonFM._i_by_ts($start.data('timestamp'), subs);
        var $added = $start;
        while (MakonFM._lineno_of($start) < n) {
            i--;
            if (i < 0) break;
            $added = MakonFM._add_st_word(subs[i], {before:$added});
        }
        var $last = $st.find('.word:last');
        while (MakonFM._lineno_of($last) >= MakonFM.SUB_LINE_CNT) {
            var $to_remove = $last;
            $last = $last.prev();
            $to_remove.remove();
        };
    }
    function scrolldown(n) {
        if (n === undefined) n = 1;
        var $words = $st.find('.word');
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

// XXX
MakonFM.clear_subs = function() {
    MakonFM.subs = [];
    $('.subtitles').empty();
};

MakonFM.show_word_info = function(word, $cont, subs) {
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
    MakonFM.inspected_word(word);
};

$('.subtitles .word').live('click', function(evt) {
    if (evt.button != 0) return;
    MakonFM.show_word_info(evt.target);
});

MakonFM.get_subs = function(stem) {
    if (MakonFM.subtitles[stem]) {
        MakonFM.subs = MakonFM.subtitles[stem];
        return;
    }
    MakonFM.clear_subs();
    
    $('<script>')
    .attr({
        type: 'text/javascript',
        src: MakonFM.SUBTITLE_BASE + stem + '.sub.js' //FIXME: add sub version
    })
    .appendTo('body')
    .remove();
};
$(document).bind('got_subtitles.MakonFM', function(evt, arg) {
    if (ko.utils.stringStartsWith(MakonFM.current_file(), arg.fn)) {
        MakonFM.subs = arg.data;
    }
    MakonFM.subtitles[arg.fn] = arg.data;
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
        function try_el($el) {
            if ($el.is('.word')) return $el;
            else return false;
        }
        if      ($rv = try_el($(sc))) { }
        else if ($rv = try_el($(sc).parent())) { }
        else if ($rv = try_el($(sc.nextSibling))) { }
        else throw ('Failed to find start word');
        
        var ec = range.endContainer;
        var $end;
        if      ($end = try_el($(ec))) { }
        else if ($end = try_el($(ec).parent())) {
            if (range.endOffset == 0) $end = $end.prev();
        }
        else if ($end = try_el($(ec.previousSibling))) { }
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
        $rv = $(document.selection.createRange().htmlText).filter('.word');
    }
    return $rv;
};

$('.subtitles').bind({
    mouseup: function(evt) {
        var $sel = MakonFM.get_selected_words();
        if ($sel && $sel.length) {} else return;
        
        $sel.addClass('selected');
        MakonFM.editation_active(true);
        MakonFM.edited_subtitles($sel);
    }
});

MakonFM.send_subtitles = function($orig, submitted, subs) {
    if (!$orig) throw ('send_subtitles needs original words');
    if ($orig.length == 0) throw ('send_subtitles needs more than 0 original words');
    if ($orig.filter('.word').length < $orig.length) throw ("send_subtitles needs original .word's");
    if (typeof submitted !== 'string') throw ('send_subtitles needs string of new subtitles');
    if (!subs) subs = MakonFM.subs;
    
    var start_ts = $orig.first().data('timestamp');
    if (!$.isNumeric(start_ts)) throw ('invalid start timestamp');
    
    var end_ts;
    var i = MakonFM._i_by_ts($orig.last().data('timestamp'), subs);
    if (!i) throw ('send_subtitles failed to get index of last selected word');
    i++;
    if (i == subs.length) end_ts = Infinity;
    else if (i < subs.length) {
        end_ts = subs[i].timestamp;
    }
    else throw ('Something smells about indices here in send_subtitles');
    if (!$.isNumeric(end_ts)) throw ('Failed to get end timestamp');
    
    $.post(MakonFM.SEND_SUBTITLES_URL, {
        filestem: MakonFM.current_file,
        start: start_ts,
        end: end_ts,
        trans: submitted
    }).success( function(new_subs) {
        ;;; console.log('new subs:', new_subs);
        if (new_subs && new_subs.success === 1) {
            MakonFM.merge_subtitles(new_subs);
        }
        else if (new_subs && new_subs.success === 0) {
            throw 'Failed matching'; // TODO: negotiate for better transcription
        }
        else {
            throw 'unexpected new subs';
        }
    });
};

MakonFM.merge_subtitles = function(new_subs, old_subs) {
    if (!old_subs) {
        old_subs = MakonFM.subtitles[new_subs.filestem];
    }
    if (!old_subs) {
        throw 'No old subs to receive editation';
    }
    
    var s = new_subs.subs;
    for (var i = 0; i < s.length; i++) {
        s[i].humanic = true;
    }
    
    var start = MakonFM._i_by_ts(new_subs.start, old_subs);
    var  end  = MakonFM._i_by_ts(new_subs. end , old_subs);
    var how_many = 1 + end - start;
    old_subs.splice.apply(old_subs, [start, how_many].concat(s));
    
    var $old_subs = $('.word.corrected[data-timestamp="' + new_subs.start + '"]');
    if ($old_subs.length > 0) {
        $old_subs = $old_subs.add($old_subs.nextAll('.corrected'));
        var $last_added = $old_subs.last();
        var $added = $();
        for (var i = 0; i < s.length; i++) {
            $last_added = MakonFM._add_st_word(s[i], {after: $last_added});
            $added = $added.add($last_added);
        }
        $added.addClass('humanic');
        $old_subs.remove();
    }
};

MakonFM._mark_subtitles_as_corrected = function($words) {
    var start_ts = $words.first().data('timestamp');
    var   end_ts = $words. last().data('timestamp');
    var start = MakonFM._i_by_ts(start_ts, MakonFM.subs);
    var   end = MakonFM._i_by_ts(  end_ts, MakonFM.subs);
    for (var i = start; i <= end; i++) {
        MakonFM.subs[i].corrected = true;
    }
};
