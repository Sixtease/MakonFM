var MakonFM = new (function(instance_name) {
    var m = this;
//    m.MEDIA_BASE =    'http://commondatastorage.googleapis.com/karel-makon-mp3/';
    m.MEDIA_BASE =    '/static/audio/';
//    m.SUBTITLE_BASE = 'http://commondatastorage.googleapis.com/karel-makon-sub/';
    m.SUBTITLE_BASE = '/static/subs/';
    m.SEND_SUBTITLES_URL = '/subsubmit/';
    m.WORDS_PRE = 10;
    m.WORDS_POST = 10;
    m.CURRENT_INDEX = 0;
    m.name = instance_name;

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
        },
        owner: m
    });

    m.player_time = ko.observable(0);

    m.inspected_word = ko.observable(null);

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
            var $words = m.edited_subtitles();
            var start_idx = MakonFM._i_by_ts($words.first().data('timestamp'), MakonFM.subs);
            var end_idx   = MakonFM._i_by_ts($words.last ().data('timestamp'), MakonFM.subs);
            var words = m.subs.slice(start_idx, end_idx+1);
            if (words.length != $words.length) {
                ;;; console.log('words and $words differ in length', words, $words);
            }
            $.each(words, function(i,w) { w.is_corrected(true) });
            m.send_subtitles($words, str);
            m.edited_subtitles(null);
        },
        owner: m
    });
    m.editation_active = ko.computed(function() {
        return m.edited_subtitles() !== null;
    });

    m._current_word = ko.observable(null);
    m.current_word = ko.computed({
        read: function() { return m._current_word() },
        write: function(w) {
            if (m._current_word()) m._current_word().is_current(false);
            w.is_current(true);
            m._current_word(w);
        },
        owner: m
    });
    m.visible_subs = ko.observableArray();
    m._get_word_el_by_ts = function(ts) {
        return $(document.getElementById(m.name + '-word-ts-' + ts));
    };
    m._get_word_el = function(sub) {
        if (!sub) return $();
        return m._get_word_el_by_ts(sub.timestamp);
    };

    m.current_file.subscribe(function(fn) {
        MakonFM.jPlayer('setMedia', {
            mp3: MakonFM.MEDIA_BASE + fn + '.mp3'
        });
        MakonFM.jPlayer('play');
        MakonFM.get_subs(fn);
    });

    m.edited_subtitles.subscribe(function($sel) {
        if ($sel) {
            $('.subedit')
            .insertBefore($sel.first())
            .focus();
        }
        else {
            $('.subedit').appendTo('.subedit-shed');
        }
    });

    m._current_visible_word_index = ko.observable(NaN);
    m.current_visible_word_index = ko.computed({
        read: function() {
            return m._current_visible_word_index();
        },
        write: function(i) {
            m.current_word(m.visible_subs()[i]);
        }
    });
    m.current_word.subscribe(function(w) {
        m._current_visible_word_index(m._i_by_ts(w.timestamp, m.visible_subs(), m.current_visible_word_index()));
    });

    return m;
}) ('MakonFM');

$(document).ready(function() {
    var lh = MakonFM.SUB_LINE_HEIGHT = $('.subtitles').css('lineHeight').replace(/\D+/g, '');
    var lc = MakonFM.SUB_LINE_CNT = Math.round($('.subtitles').height() / lh);
    MakonFM.SUB_MIDDLE_LINE = Math.floor((lc+1) / 2) - 1;

    MakonFM.jPlayer = function(a,b) { $('#jquery_jplayer_1').jPlayer(a,b); };
    MakonFM.jPlayer({
        swfPath: "/static",
        supplied: "mp3",
        timeupdate: function(evt) {
            try {
                MakonFM.upd_sub(evt.jPlayer.status.currentTime, MakonFM.subs);  // XXX
            } catch(e) {
                ;;; console.log(e);
            }
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
    if (isNaN(i)) i = MakonFM.CURRENT_INDEX;
    if (i < 0) i = 0;
    if (i >= subs.length) i = subs.length - 1;
    
    if (subs[i].timestamp == ts) return i;
    if (ts <= subs[0].timestamp) return 0;
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

MakonFM.upd_sub = function (ts, subs, i) {
    if (!MakonFM.subs) return;

    var vs = MakonFM.visible_subs;
    var _vs = vs(); // underlying real array of ko.observableArray
    
    var cur_have = MakonFM.current_word();
    if (cur_have) {
        var cur_have_idx = MakonFM.current_visible_word_index();
        if (cur_have_idx >= 0) {
            var next_have_idx = cur_have_idx + 1;
            var next_have = _vs[ next_have_idx ];
            if (next_have) {
                if (cur_have.timestamp < ts && next_have.timestamp > ts) return;
            }
        }
    }
    
    var LEFT = -1;
    var RIGHT = 1;
    
    if (!subs) subs = MakonFM.subs;
    i = MakonFM._i_by_ts(ts, subs, i);
    MakonFM.CURRENT_INDEX = i;
    var sub = subs[i];
    var $new_cur = MakonFM._get_word_el(sub);
    
    if (_vs.length == 0) {
        vs.push(Word(sub));
        $new_cur = MakonFM._get_word_el(sub);
        add_adjacent({ant: sub, "$ant": $new_cur, dir: LEFT});
        add_adjacent({ant: sub, "$ant": $new_cur, dir: RIGHT});
    }
    else if ($new_cur.length == 0) {
        var first_have = _vs[0];
        var first_have_ts = first_have.timestamp;
        var $first_have = MakonFM._get_word_el_by_ts(first_have_ts);
        var stopper_left = null;
        var $stopper_left = null;
        var stopper_right = null;
        var $stopper_right = null;
        
        if (sub.timestamp < first_have_ts) {
            vs.unshift(Word(sub));
            $new_cur = MakonFM._get_word_el(sub);
            $stopper_right = $first_have;
            stopper_right = first_have;
        }
        else {
            var last_have = _vs[ _vs.length - 1 ];
            var last_have_ts = last_have.timestamp;
            var $last_have = MakonFM._get_word_el_by_ts(last_have_ts);
            if (sub.timestamp > last_have_ts) {
                vs.push(Word(sub));
                $new_cur = MakonFM._get_word_el(sub);
                $stopper_left = $last_have;
                stopper_left = last_have;
            }
            else throw ('Neither a current nor less than leftmost nor more than rightmost?');
        }
        add_adjacent({ant: sub, "$ant": $new_cur, dir: LEFT,  stopper: stopper_left,  "$stopper": $stopper_left });
        add_adjacent({ant: sub, "$ant": $new_cur, dir: RIGHT, stopper: stopper_right, "$stopper": $stopper_right});
    }
    else {
        var cur_lineno = MakonFM._lineno_of($new_cur);
        var lines_to_scroll = cur_lineno - MakonFM.SUB_MIDDLE_LINE;
        scroll(lines_to_scroll);
    }
    
    MakonFM.current_word(sub);

    function add_adjacent(arg) {
        var dir = arg.dir;
        if (!dir) throw('No dir given to add_adjacent in arg', arg);
        var ant = arg.ant;
        var $ant = arg.$ant;
        if (!$ant || !$ant.length) throw('No ant[ecedant] given to add_adjacent in arg', arg);
        var $stopper = arg.$stopper;
        var stopper = arg.stopper;
        var j = i;
        var $added = $ant;
        var added = ant;
        var added_idx = vs.indexOf(added);
        if ($stopper) {
            var stop_ts = stopper.timestamp;
        }
        if (dir === LEFT) {
            var have_br = false;
            if ($stopper) {
                have_br = true;
                $stopper.css({display: 'block'});
            }
            var shifted_ref_lineno = MakonFM._lineno_of($ant) + MakonFM.SUB_MIDDLE_LINE;
            while (MakonFM._lineno_of($ant) < shifted_ref_lineno) {
                j--;
                if (j<0) break;
                if (stop_ts && subs[j].timestamp == stop_ts) {
                    have_br = false;
                    $stopper.css({display: ''});
                    break;
                }
                vs.splice(added_idx, 0, Word(subs[j]));
                added = subs[j];
                // not updating added_idx because it stays unchanged
            }
            if (stopper) {
                if (have_br) {
                    vs.splice( 0, vs.indexOf(stopper)+1 )
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
                    added = _vs[ ++added_idx ];
                    $added = MakonFM._get_word_el(added);
                    stopper = _vs[ added_idx + 1 ];
                    $stopper = MakonFM._get_word_el(stopper);
                    continue;
                }
                if (stop_ts && subs[j].timestamp == stop_ts) {
                    do_add = false;
                    continue;
                }
                
                vs.splice( ++added_idx, 0, Word(subs[j]) );
                added = subs[j];
                $added = MakonFM._get_word_el(added);
                got_too_much = true;
            }
            if (got_too_much) vs.splice(added_idx, 1);
            if (stopper) {
                vs.splice( vs.indexOf(stopper), _vs.length );
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
        var start = _vs[0];
        var $start = MakonFM._get_word_el(start);
        var i = MakonFM._i_by_ts(start.timestamp, subs);
        while (MakonFM._lineno_of($start) < n) {
            i--;
            if (i < 0) break;
            vs.unshift(Word(subs[i]));
        }
        var last = _vs[ _vs.length - 1 ];
        var $last = MakonFM._get_word_el(last);
        while (MakonFM._lineno_of($last) >= MakonFM.SUB_LINE_CNT) {
            vs.splice( _vs.length-1, 1 );
            last = _vs[ _vs.length - 1 ];
            $last = MakonFM._get_word_el(last);
        };
    }
    function scrolldown(n) {
        if (n === undefined) n = 1;
        var lines_added = 0;
        
        var added = _vs[ _vs.length - 1 ];
        var $added = MakonFM._get_word_el(added);
        var i = MakonFM._i_by_ts(added.timestamp, subs);
        var prev_lineno;
        var cur_lineno;
        cur_lineno = prev_lineno = MakonFM._lineno_of($added);
        while (cur_lineno < MakonFM.SUB_LINE_CNT + n) {
            i++;
            if (i >= subs.length) break;
            
            vs.push(Word(subs[i]));
            added = subs[i];
            $added = MakonFM._get_word_el(added);
            
            cur_lineno = MakonFM._lineno_of($added);
            if (prev_lineno < cur_lineno) lines_added++;
            prev_lineno = cur_lineno;
        }
        // last line is just one word, delete it
        lines_added--;
        vs.pop();
        
        var i = 1;
        var $w;
        while (MakonFM._lineno_of(MakonFM._get_word_el(_vs[i])) < lines_added) {
            i++;
        }
        vs.splice(0, i);
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
        filestem: MakonFM.current_file(),
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

var Word = new function() {
    function get_lazy_observable(field_name, default_value) {
        if (!field_name) throw "field_name not given";
        if (arguments.length < 2) default_value = false;
        return function() {
            if (field_name in this) {
                return this[field_name].apply(this, arguments);
            }
            if (arguments.length == 0) {
                this[field_name] = ko.observable(default_value);
                return this[field_name].apply(this, arguments);
            }
            return this[field_name] = ko.observable.apply(ko, arguments);
        };
    }
    
    var word = {};
    word.is_current   = get_lazy_observable('current');
    word.is_corrected = get_lazy_observable('corrected');
    word.is_humanic   = get_lazy_observable('humanic');
    word.is_selected  = get_lazy_observable('selected');
    
    return function(w) {
        return $.extend(w, word);
    };
};
