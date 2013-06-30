$.ajaxSetup({ cache: true });

function MakonFM_constructor(instance_name) {
    var m = this;
    $.extend(this, MAKONFM_CONFIG);
    m.CURRENT_INDEX = 0;
    m.name = instance_name;

    m.subtitles = {};
    var _current_filestem = ko.observable('');
    var _no_file_str = 'nepřehrává se';
    m._requested_position = ko.observable(0);
    m.requested_position = ko.computed({
        read: function() { return m._requested_position(); },
        write: function(pos) {
            if (!_current_filestem()) {
                return;
            }
            m._requested_position(+pos);
            var new_hash = [m.current_file(), pos].join('#');
            m.set_hash(new_hash);
        }
    });
    m.current_file = ko.computed({
        read: function() {
            return _current_filestem() || _no_file_str;
        },
        write: function(fnpos) {
            var fp = fnpos.split('#');
            var fn  = fp[0];
            var pos = fp[1];
            var stem = fn.replace(/\.(mp3|ogg|sub\.js)$/, '');
            if (pos) m._requested_position(+pos);
            else {
                pos = 0;
                m._requested_position(0);
            }
            if (location.hash.split('#')[1] !== stem) {
                var new_hash = stem;
                if (pos !== undefined) new_hash += '#' + pos;
                m.set_hash(new_hash);
            }
            
            if (_current_filestem() != stem) {
                m.jPlayer('setMedia', {
                    mp3: m.MEDIA_BASE + stem + '.mp3',
                    oga: m.MEDIA_BASE + stem + '.ogg'
                });
                _current_filestem(stem);
                m.get_subs(stem);
            }
            
            // FIXME
            //m.jPlayer('play', +pos);
            if (pos > m.jp.status.duration) {
                m.jPlayer('pause', +pos);
                // FIXME: don't use literal ID but bind jPlayer to MakonFM instance
                $('#jquery_jplayer_1').one($.jPlayer.event.seeked, function() {
                    m.jPlayer('play');
                });
            }
            else {
                m.jPlayer('play', +pos);
            }
        },
        owner: m
    });
    m.file_selected = ko.computed( function() {
        return _current_filestem() ? true : false;
    });

    m.player_time = ko.observable(0);
    m.playback_active = function() {
        return m.jp.status.paused ? false : true;
    }

    m.inspected_word = ko.observable(null);

    m.edited_subtitles = ko.observable([]);
    m.edited_subtitles_backup = [];
    m.edited_subtitles_str = ko.computed({
        read: function() {
            var es = m.edited_subtitles();
            if (es.length === 0) return '';
            return $.map(
                es,
                function(x) { return ko.utils.unwrapObservable(x.occurrence); }
            ).join(' ');
        },
        owner: m
    });
    m.editation_active = ko.computed({
        read: function() {
            return (m.edited_subtitles().length > 0);
        },
        write: function(is_active) {
            if (is_active) {
                ;;; console.log('editation_active was explicitly switched on, wtf?');
            }
            else {
                m.edited_subtitles([]);
            }
        }
    });

    m._current_word = ko.observable(null);
    m.current_word = ko.computed({
        read: function() { return m._current_word() },
        write: function(w) {
            if (m._current_word()) m._current_word().current(false);
            w.current(true);
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
    m._get_word_els_span = function(start_sub,end_sub) {
        if (!start_sub) return $();
        var $start = m._get_word_el(start_sub);
        var $end   = m._get_word_el(  end_sub);
        return $start.add($start.nextUntil($end)).add($end);
    };
    
    m.medium_loaded = ko.observable(false);
    
    _current_filestem.subscribe(function() {
        m.medium_loaded(false);
    });
    m.edited_subtitles.subscribe(function(new_edited_subs) {
        $.each(m.edited_subtitles_backup, function(i,s) {
            s.selected(false);
        });
        m.edited_subtitles_backup = new_edited_subs;
        
        if (new_edited_subs.length) {
            $.each(new_edited_subs, function(i,s) {
                s.selected(true);
            });
            
            m._limit_playback_to_editation_span();
            
            $('.js-subedit').focus();
            
            m.jPlayer('play');
        }
        else {
            m._cancel_playback_limit();
        }
    });

    m.editation_active.subscribe(function() {
        _clear_selection();
    });

    m.cancel_editation = function() { m.editation_active(false); };

    m.window_start = ko.observable(null);
    m.window_end   = ko.observable(null);
    (function() {
        function autostop_cb(evt) {
            var d = m.window_end() - evt.jPlayer.status.currentTime;
            if (d < 0) {
                m.jPlayer('pause', m.window_start());
            }
            else if (d < 0.25) {
                setTimeout( function() {
                    m.jPlayer('pause', m.window_start());
                }, 1000*d);
            }
        }
/*        function override_stop_cb(evt) {
            $(document).one( function(evt) {
                
            });
        }*/
        m._limit_playback_to_editation_span = function() {
            m.jPlayer('pause');
            var edited_subs = m.edited_subtitles();
            if (edited_subs[0]) {
                var first_sub = edited_subs[0];
                m.window_start(first_sub.timestamp);
                var last_sub  = edited_subs[ edited_subs.length - 1 ];
                var last_sub_i = m._i_by_ts(last_sub.timestamp, m.subs);
                var after_last_sub = m.subs[ last_sub_i + 1 ];
                if (after_last_sub) {
                    m._dont_play_end = true;
                    m.window_end(after_last_sub.timestamp);
                }
                m.jPlayer('pause', m.window_start());
            }
            else {
                ;;; console.log('editation activated but no edited subs?');
                return;
            }
            if (m.window_end() !== null) {
                $(document).bind($.jPlayer.event.timeupdate, autostop_cb);
            }
        };
        m._cancel_playback_limit = function() {
            $(document).unbind($.jPlayer.event.timeupdate, autostop_cb);
            var end = m.window_end();
            m.window_start(null);
            m.window_end(null);
            // set head after the edited window
            m.jPlayer('pause', +end);
        };
    })();

    m._window_step = 0.2;
    m.inc_window_start = function() {
        move_window(m.window_start, 1);
    };
    m.dec_window_start = function() {
        move_window(m.window_start, -1);
    };
    m.inc_window_end = function() {
        move_window(m.window_end, 1);
    };
    m.dec_window_end = function() {
        move_window(m.window_end, -1);
    };
    function move_window(obs, dir) {
        obs( obs() + dir * m._window_step );
    }
    m._minimum_window_length = 0.5;
    m.window_start.subscribe(function (v) {
        if (m.window_end() - v < m._minimum_window_length) {
            m._dont_play_end = true;
            m.window_end( v + m._minimum_window_length + 0.1 );
        }
    });
    var end_play_timeout;
    m.window_end.subscribe(function(v) {
        if (v - m.window_start() < m._minimum_window_length) {
            m.window_start( v - m._minimum_window_length - 0.1 );
        }
        
        var dont = m._dont_play_end;
        delete m._dont_play_end;
        if (dont) { return }
        
        if (end_play_timeout) clearTimeout(end_play_timeout);
        end_play_timeout = setTimeout(play_end, 500);
    });
    m.window_start.formatted = ko.computed({
        read: _format_time_this,
        write: parse_formatted_time,
        owner: m.window_start
    });
    m.window_end.formatted = ko.computed({
        read: _format_time_this,
        write: parse_formatted_time,
        owner: m.window_end
    });
    function _format_time_this() {
        return format_time(this());
    }
    function format_time(t) {
        var rv = Math.floor(t / 60) + ':';
        var min = t % 60;
        var pre_min = '';
        if (min < 10) pre_min = '0';
        rv += pre_min + min.toFixed(2);
        return rv;
    }
    m.format_time = format_time;
    function parse_formatted_time(str) {
        var fields = str.split(':');
        fields.reverse();
        var t = 0;
        var order = 1;
        $.each(fields, function(i,v) {
            t += order * v;
            order *= 60;
        });
        if (isNaN(t)) {
            this.valueHasMutated(); // to restore the previous digits in the field
            return;
        }
        this(t);
    }

    function play_end() {
        var end = m.window_end();
        if (!end) return;
        m.jPlayer('play', end - m._minimum_window_length);
        end_play_timeout = null;
    }

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
    
    m.medium_loaded.subscribe(function(state) {
        if (state === true) {
            place_humanic_markers(m.subs);
        }
    });

    m._ignore_hashchange = 0;

    m.uncertainty_lookahead = 10;
    m.max_autostop_window_length = 15;  // seconds
    m.min_autostop_window_length = 3;
    
    m.next_autostop = [];
    m.do_autostop = ko.observable(true);
    m.autostop_timeout;
    if (m.do_autostop()) {
        m.autostop_timeout = setTimeout(function(){m.autostop()},1000);
    }
    m.do_autostop.subscribe(function(active) {
        if (active) {
            m.autostop();
        }
        else {
            clearTimeout(m.autostop_timeout);
        }
    });

    return m;
}
var MakonFMp = MakonFM_constructor.prototype;
var MakonFM = new MakonFM_constructor('MakonFM');

MakonFMp._i_by_ts = function(ts, subs, i) {
    var m = this;
    
    if (isNaN(i)) i = m.CURRENT_INDEX;
    if (i < 0) i = 0;
    if (i >= subs.length) i = subs.length - 1;
    
    if (subs[i].timestamp == ts) return i;
    if (ts <= subs[0].timestamp) return 0;
    if (ts >= subs[subs.length-1].timestamp) return subs.length-1;
    
    while (subs[i++].timestamp < ts) { }
    while (subs[--i].timestamp > ts) { }
    
    return i;
};

MakonFMp.upd_sub = function (ts, subs, i) {
    var m = this;
    
    if (!m.subs || m.subs.length == 0) return;

    var vs = m.visible_subs;
    var _vs = vs(); // underlying real array of ko.observableArray
    
    var cur_have = m.current_word();
    if (cur_have) {
        var cur_have_idx = m.current_visible_word_index();
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
    
    if (!subs) subs = m.subs;
    i = m._i_by_ts(ts, subs, i);
    m.CURRENT_INDEX = i;
    var sub = subs[i];
    var $new_cur = m._get_word_el(sub);
    
    if (_vs.length == 0) {
        vs.push(Word(sub));
        $new_cur = m._get_word_el(sub);
        add_adjacent({ant: sub, "$ant": $new_cur, dir: LEFT});
        add_adjacent({ant: sub, "$ant": $new_cur, dir: RIGHT});
    }
    else if ($new_cur.length == 0) {
        var first_have = _vs[0];
        var first_have_ts = first_have.timestamp;
        var stopper_left = null;
        var stopper_right = null;
        
        if (sub.timestamp < first_have_ts) {
            vs.unshift(Word(sub));
            $new_cur = m._get_word_el(sub);
            stopper_right = first_have;
        }
        else {
            var last_have = _vs[ _vs.length - 1 ];
            var last_have_ts = last_have.timestamp;
            if (sub.timestamp > last_have_ts) {
                vs.push(Word(sub));
                $new_cur = m._get_word_el(sub);
                stopper_left = last_have;
            }
            else throw ('Neither a current nor less than leftmost nor more than rightmost?');
        }
        add_adjacent({ant: sub, "$ant": $new_cur, dir: LEFT,  stopper: stopper_left });
        add_adjacent({ant: sub, "$ant": $new_cur, dir: RIGHT, stopper: stopper_right});
    }
    else {
        while (m._lineno_of(m._get_word_el(_vs[ _vs.length - 1 ])) > m.SUB_LINE_CNT-1) {
            vs.pop();
        }
        var cur_lineno = m._lineno_of($new_cur);
        var lines_to_scroll;
/*        if (cur_lineno >= 0 && cur_lineno <= m.SUB_MIDDLE_LINE) {
            lines_to_scroll = 0;
        }
        else {*/
            lines_to_scroll = cur_lineno - m.SUB_MIDDLE_LINE;
//        }
        scroll(lines_to_scroll);
    }
    
    m.current_word(sub);

    function add_adjacent(arg) {
        var dir = arg.dir;
        if (!dir) throw('No dir given to add_adjacent in arg', arg);
        var ant = arg.ant;
        var $ant = arg.$ant;
        if (!$ant || !$ant.length) throw('No ant[ecedant] given to add_adjacent in arg', arg);
        var stopper = arg.stopper;
        var $stopper = m._get_word_el(stopper);
        var j = i;
        var $added = $ant;
        var added = ant;
        var added_idx = vs.indexOf(added);
        if (stopper) {
            var stop_ts = stopper.timestamp;
        }
        if (dir === LEFT) {
            var have_br = false;
            if (stopper) {
                have_br = true;
                $stopper.css({display: 'block'});
            }
            var shifted_ref_lineno = m._lineno_of($ant) + m.SUB_MIDDLE_LINE;
            while (m._lineno_of($ant) < shifted_ref_lineno) {
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
                    var aln = m._lineno_of($ant);
                    scroll(aln - m.SUB_MIDDLE_LINE);
                }
            }
        }
        else if (dir == RIGHT) {
            var do_add = true;
            var got_too_much = false;
            while (m._lineno_of($added) < m.SUB_LINE_CNT) {
                j++;
                if (j >= subs.length) break;
                
                if (!do_add) {
                    added = _vs[ ++added_idx ];
                    $added = m._get_word_el(added);
                    stopper = _vs[ added_idx + 1 ];
                    $stopper = m._get_word_el(stopper);
                    continue;
                }
                if (stop_ts && subs[j].timestamp == stop_ts) {
                    do_add = false;
                    continue;
                }
                
                vs.splice( ++added_idx, 0, Word(subs[j]) );
                added = subs[j];
                $added = m._get_word_el(added);
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
        var $start = m._get_word_el(start);
        var i = m._i_by_ts(start.timestamp, subs);
        while (m._lineno_of($start) < n) {
            i--;
            if (i < 0) break;
            vs.unshift(Word(subs[i]));
        }
        var last = _vs[ _vs.length - 1 ];
        var $last = m._get_word_el(last);
        while (m._lineno_of($last) >= m.SUB_LINE_CNT) {
            vs.splice( _vs.length-1, 1 );
            last = _vs[ _vs.length - 1 ];
            $last = m._get_word_el(last);
        };
    }
    function scrolldown(n) {
        if (n === undefined) n = 1;
        var lines_added = 0;
        
        var added = _vs[ _vs.length - 1 ];
        var $added = m._get_word_el(added);
        var i = m._i_by_ts(added.timestamp, subs);
        var prev_lineno;
        var cur_lineno;
        cur_lineno = prev_lineno = m._lineno_of($added);
        while (cur_lineno < m.SUB_LINE_CNT + n) {
            i++;
            if (i >= subs.length) break;
            
            vs.push(Word(subs[i]));
            added = subs[i];
            $added = m._get_word_el(added);
            
            cur_lineno = m._lineno_of($added);
            if (prev_lineno < cur_lineno) lines_added++;
            prev_lineno = cur_lineno;
        }
        // last line is just one word, delete it
        lines_added--;
        vs.pop();
        
        var i = 1;
        var $w;
        while (m._lineno_of(m._get_word_el(_vs[i])) < lines_added) {
            i++;
        }
        vs.splice(0, i);
    }
};


MakonFMp._lineno_of = function($word, lh) {
    var m = this;
    
    if (lh === undefined) {
        lh = m.SUB_LINE_HEIGHT;
    }
    var pos = $word.position().top;
    return Math.floor((pos+lh/2)/lh);
};

MakonFMp.clear_subs = function() {
    var m = this;
    
    m.subs = [];
    m.visible_subs.removeAll();
    clear_humanic_markers();
};

MakonFMp.show_word_info = function(word) {
    var m = this;
    
    var subs = m.subs;
    var ts;
    if ($.isNumeric(word)) {
        ts = word;
    }
    else if ((word instanceof Element) || (word instanceof jQuery)) {
        ts = $(word).data('timestamp');
    }
    if (ts !== undefined) {
        var i = m._i_by_ts(ts, subs);
        word = subs[i];
    }
    init_for_inspection(word);
    m.inspected_word(word);
    return word;
};

MakonFMp.merge_subtitles = function(new_subs, old_subs) {
    var m = this;
    
    if (!old_subs) {
        old_subs = m.subtitles[new_subs.filestem];
    }
    if (!old_subs) {
        throw 'No old subs to receive editation';
    }
    
    var s = new_subs.data;
    $.each(s, function(i,w) {
        Word(w);
    });
    
    var start = m._i_by_ts(new_subs.start, old_subs);
    var end   = m._i_by_ts(new_subs.end  , old_subs, start);
    var how_many = end - start;
    old_subs.splice.apply(old_subs, [start, how_many].concat(s));
    
    // if other subs are displayed than have been edited, don't update visible_subs
    if (m.subs == old_subs) {
        var vs = m.visible_subs;
        start = m._i_by_ts(new_subs.start, vs());
        end   = m._i_by_ts(new_subs.end  , vs());
        how_many = end - start; // in practice, it should be safe to reuse how_many but just to be sure...
        vs.splice.apply(vs, [start, how_many].concat(s));
    }
};

MakonFMp.get_subs = function(stem) {
    var m = this;
    
    if (m.subtitles[stem]) {
        m.subs = m.subtitles[stem];
        return;
    }
    m.clear_subs();
    
    $('<script>')
    .attr({
        type: 'text/javascript',
        src: m.SUBTITLE_BASE + stem + '.sub.js?v=' + (SUB_VERSION[stem]||0)
    })
    .appendTo('body')
    .remove();
};

MakonFMp.send_subtitles = function(submitted, subs) {
    var m = this;
    
    if (typeof submitted !== 'string') throw ('send_subtitles needs string of new subtitles');
    if (!subs) subs = m.subs;
    
    var start_ts = m.window_start();
    if (!$.isNumeric(start_ts)) throw ('invalid start timestamp');
    
    var end_ts = m.window_end();
    if (!$.isNumeric(end_ts)) throw ('Failed to get end timestamp');
    
    _xreq({
        url: m.SEND_SUBTITLES_URL,
        type: 'post',
        cache: false,
        dataType: 'json',
        data: {
            filestem: m.current_file(),
            start: start_ts,
            end: end_ts,
            trans: submitted,
            author: $.cookie('author'),
            session: $.cookie('session'),
        }
    }).done( function(new_subs) {
        //;;; console.log('new subs:', new_subs);
        if (new_subs && new_subs.success === 1) {
            m.merge_subtitles(new_subs);
        }
        else if (new_subs && new_subs.success === 0) {
            throw 'Failed matching'; // TODO: negotiate for better transcription
        }
        else {
            throw 'unexpected new subs';
        }
    });
};

MakonFMp.get_selected_words = function() {
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
        else while (sc && sc.nodeType == 3) { // type 3 is textNode
            sc = sc.nextSibling;
            if ($rv = try_el($(sc))) break;
        }
        if (!$rv) {
            ;;; console.log('range:',range);
            throw ('Failed to find start word');
        }
        
        var ec = range.endContainer;
        var $end;
        if      ($end = try_el($(ec))) { }
        else if ($end = try_el($(ec).parent())) {
            if (range.endOffset == 0) $end = $end.prev();
        }
        else while (ec && ec.nodeType == 3) {
            ec = ec.previousSibling;
            if ($end = try_el($(ec))) break;
        }
        if (!$end) {
            ;;; console.log('range:',range);
            throw ('Failed to find end word');
        }
        
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

MakonFMp.play_window = function() {
    var m = this;
    m.jPlayer('play', +m.window_start());
};
MakonFMp.stop_window = function() {
    var m = this;
    m.jPlayer('pause', +m.window_start());
};

MakonFMp.save_editation = function() {
    var m = this;
    var str = $('.js-subedit').val();
    var words = m.edited_subtitles();
    $.each(words, function(i,w) { w.corrected(true) });
    m.send_subtitles(str);
    m.editation_active(false);
};

MakonFMp.play_from_word = function(w) {
    var m = this;
    m.jPlayer('play', w.timestamp);
};

MakonFMp.toggle_playback = function() {
    var m = this;
    if (m.playback_active()) {
        m.jPlayer('pause');
        if (m.editation_active()) {} else {
            m.requested_position(m.jp.status.currentTime);
        }
    }
    else {
        m.jPlayer('play');
    }
};

MakonFMp.set_hash = function(hash) {
    var m = this;
    m._ignore_hashchange++;
    location.hash = hash;
};

MakonFMp.get_next_uncertain_sentence = function(ts) {
    var m = this;
    var lookahead = m.uncertainty_lookahead;
    var max_len = m.max_autostop_window_length;
    var min_len = m.min_autostop_window_length;
    if (!$.isNumeric(ts)) {
        ts = m.jp.status.currentTime;
    }
    var sents = new Array(lookahead);
    sents[0] = [];
    var subs = m.subs;
    var i = m._i_by_ts(ts, subs);   // word index
    var si = -1;    // sentence index
    var w;
    while (i < subs.length) {
        w = subs[i];
        if (sentence_boundary(subs,i++)) {
            var discard_sentence = false;
            if (si >= 0) {
                if (sents[si].do_discard) { discard_sentence = true }
                var time_len = sents[si][sents[si].length-1].timestamp - sents[si][0].timestamp;
                if (time_len < min_len) { discard_sentence = true }
                if (time_len > max_len) { discard_sentence = true }
            }
            
            if (!discard_sentence) {
                si++;
                if (si >= sents.length) {
                    break;
                }
            }
            sents[si] = [];
        }
        if (si < 0) {
            continue;
        }
        
        if (!w.cmscore) {
            sents[si].do_discard = true;
        }
        if (w.autostopped) {
            sents[si].do_discard = true;
        }
        
        sents[si].push(w);
    }
    
    if (si === 0) {
        return [];
    }
    
    var cmss = new Array(si); // confidence measure scores (of the looked-ahead sentences)
    for (var j = 0; j < si; j++) {
        var cm_sorted = $.map(sents[j],function(e){return e.cmscore}).sort(function(a,b) { return a-b; });
        // take 33th percentile because we want a sentence where the lows are low but not interested in outliers
        cmss[j] = cm_sorted[ Math.floor(cm_sorted.length / 3) ];
    }
    
    var winner_i = -1;
    var winner_cm = Infinity;
    for (j = 0; j < cmss.length; j++) {
        if (cmss[j] < winner_cm) {
            winner_cm = cmss[j];
            winner_i = j;
        }
    }
    
    return sents[winner_i];
    
    
    function sentence_boundary(subs,i) {
        if (i === 0) return false;
        var w = subs[i];
        if (!w) { return; }
        var wo = ko.utils.unwrapObservable(w.occurrence);
        var p = subs[i-1];
        if (!w) { return null; }
        var po = ko.utils.unwrapObservable(p.occurrence);
        if ( ! /[.!?:;]\W*$/.test(po) ) { return false; }
        if (wo.charAt(0).toUpperCase() !== wo.charAt(0)) { return false; }
        return true;
    }
};

MakonFMp.edit_uncertainty_window = function(win) {
    var m = this;
    if (!win || !win.length) { console.log('no window'); return null; }
    var time_left = win[0].timestamp - m.jp.status.currentTime;
    if (time_left < -0.5 || time_left > 0.2) {
        return time_left;
    }
    $.each(win, function(i,w) {
        w.autostopped = true;
    });
    m.edited_subtitles(win);
    return true;
};

MakonFMp.autostop = function() {
    var m = this;
    var ast = m.next_autostop;
    var editing;
    
    if (m.jp.status.paused || m.editation_active()) {
        editing = 1;
    }
    else if (ast.length) {
        editing = m.edit_uncertainty_window(ast);
        ;;; console.log('autostop',editing);
        if (editing === true) {
            ast.length = 0;
        }
        else if (editing < 0) {
            m.next_autostop = m.get_next_uncertain_sentence();
        }
    }
    else {
        m.next_autostop = m.get_next_uncertain_sentence();
    }
    
    var timeout = 1;
    if ($.isNumeric(editing) && editing < 1) {
        timeout = editing;
    }
    m.autostop_timeout = setTimeout(function() { m.autostop() }, 1000*timeout);
};

MakonFM.get_subs_by_els = function($els, subs) {
    var m = this;
    if (!subs) subs = m.subs;
    if (!$els || $els.length == 0) { return []; }
    var start_ts  = $els.filter(':first').data('timestamp');
    var   end_ts  = $els.filter(':last' ).data('timestamp');
    var start_idx = m._i_by_ts(start_ts, subs);
    var   end_idx = m._i_by_ts(  end_ts, subs);
    return subs.slice(start_idx, end_idx+1);
};

$(document).on({

    ready: function() {
        var lh = MakonFMp.SUB_LINE_HEIGHT = _get_line_height_of($('.subtitles'));
        var lc = MakonFMp.SUB_LINE_CNT = Math.round($('.subtitles').height() / lh);
        MakonFMp.SUB_MIDDLE_LINE = Math.floor((lc+1) / 2) - 1;

        MakonFM.jPlayer = function(a,b) { $('#jquery_jplayer_1').jPlayer(a,b); };
        MakonFM.jPlayer({
            swfPath: MakonFM.STATIC_BASE,
            supplied: "mp3",
            solution: 'flash,html',
            timeupdate: function(evt) {
                if (MakonFM.editation_active()) return;
                try {
                    MakonFM.upd_sub(evt.jPlayer.status.currentTime, MakonFM.subs);  // XXX
                } catch(e) {
                    ;;; console.log(e);
                }
                MakonFM.player_time(evt.jPlayer.status.currentTime);
            },
            ready: function() {
                if (location.hash.length > 1) {
                    var fn = location.hash.substr(1);
                    MakonFM.current_file(fn);
                }
            },
            progress: function(data) {
                if (data.jPlayer.status.seekPercent == 100) {
                    if (!MakonFM.medium_loaded()) {
                        MakonFM.medium_loaded(true);
                    }
                }
            },
            loadeddata: function() {
                if (!MakonFM.medium_loaded()) {
                    MakonFM.medium_loaded(true);
                }
            }
        });
        MakonFM.jp = $('#jquery_jplayer_1').data('jPlayer');

        ko.applyBindings(MakonFM);

        setTimeout(function() { $('input.js-set-name').val( $.cookie('author') ) }, 300);
    },

    'got_subtitles.MakonFM': function(evt, arg) {
        if (_string_starts_with(MakonFM.current_file(), arg.filestem)) {
            MakonFM.subs = arg.data;
            //place_humanic_markers(arg.data);
        }
        MakonFM.subtitles[arg.filestem] = arg.data;
    },

    keyup: function(evt) {
        if (evt.ctrlKey && evt.keyCode == 32) { // ctrl+space
            evt.preventDefault();
            MakonFM.toggle_playback();
        }
        if (evt.ctrlKey && (evt.keyCode == 10 || evt.keyCode == 13)) { // ctrl-enter
            if (MakonFM.editation_active()) {
                MakonFM.save_editation();
            }
        }
    }
});

$(window).on({
    unload: function() {
        MakonFM.requested_position(MakonFM.jp.status.currentTime);
    },
    hashchange: function(evt) {
        if (MakonFM._ignore_hashchange) {
            MakonFM._ignore_hashchange--;
            return;
        }
        var fn = location.hash.substr(1);
        MakonFM.current_file(fn);
    }
});

$('.track-menu li').click(function(evt) {
    if (evt.button != 0) return;
    if ($(evt.target).is('li,li>:header')) {} else return;
    evt.stopPropagation();
    $(this).toggleClass('show');
});
$('.track-menu li>a').click(function(evt) {
    if (evt.button != 0) return;
    var fn = $(this)
    .text()
    .replace(/ě/,'e')
    .replace(/š/,'s')
    .replace(/č/,'c')
    .replace(/ř/,'r')
    .replace(/ž/,'z')
    .replace(/ý/,'y')
    .replace(/á/,'a')
    .replace(/í/,'i')
    .replace(/é/,'e')
    .replace(/ú/,'u')
    .replace(/ů/,'u')
    .replace(/ď/,'d')
    .replace(/ť/,'t')
    .replace(/ň/,'n')
    .replace(/Ě/,'E')
    .replace(/Š/,'S')
    .replace(/Č/,'C')
    .replace(/Ř/,'R')
    .replace(/Ž/,'Z')
    .replace(/Ý/,'Y')
    .replace(/Á/,'A')
    .replace(/Í/,'I')
    .replace(/É/,'E')
    .replace(/Ú/,'U')
    .replace(/Ů/,'U')
    .replace(/Ď/,'D')
    .replace(/Ť/,'T')
    .replace(/Ň/,'N')
    ;
    MakonFM.current_file(fn);
    $('.track-menu>li').removeClass('show');
});

$(document).on('click', '.subtitles .word', function(evt) {
    if (evt.button != 0) return;
    var word = MakonFM.show_word_info(evt.target);
    MakonFM.jPlayer('pause', word.timestamp);
    MakonFM.requested_position(MakonFM.jp.status.currentTime);
});

$('.subtitles').on({
    mouseup: function(evt) {
        var $sel = MakonFM.get_selected_words();
        if ($sel && $sel.length) {} else return;
        MakonFM.edited_subtitles(MakonFM.get_subs_by_els($sel));
    }
});
$(document).on({
    keyup: function(evt) {
        switch (evt.keyCode) {
            case 27:
                MakonFM.editation_active(false);
                break;
        }
    }
});
function rnd(arr) {
    return arr[ Math.floor( Math.random() * arr.length ) ];
}
$('.play.Button').on('click', function(evt) {
    if (evt.button != 0) return;
    if (MakonFM.file_selected()) {}
    else {
        var file = rnd( $.makeArray( $('.track-menu a') ) );
        var fn = $(file).text();
        MakonFM.current_file(fn);
    }
});
$('.pause.Button').on('click', function(evt) {
    if (evt.button != 0) return;
    MakonFM.requested_position(MakonFM.jp.status.currentTime);
});

$('input.js-set-name').on('blur', function(evt) {
    $.cookie('author', $(evt.target).val(), { path: '/', expires: 365 });
});

$('.curword').on('change', 'input', function(evt) {
    var timestamp = $(this).data('timestamp');
    var subs = MakonFM.subs;
    var i = MakonFM._i_by_ts(timestamp, subs);
    var word = subs[i];
    word.dirty = true;
    var prev_timeout = word.save_timeout;
    if (prev_timeout) { clearTimeout(prev_timeout); }
    var save_timeout = setTimeout(save_word_fn(word), 300);
    word.save_timeout = save_timeout;
});
$('.curword').on('focusout', 'input', function(evt) {
    var timestamp = $(this).data('timestamp');
    var subs = MakonFM.subs;
    var i = MakonFM._i_by_ts(timestamp, subs);
    var word = subs[i];
    if (!word.dirty) { return; }
    var prev_timeout = word.save_timeout;
    if (prev_timeout) { clearTimeout(prev_timeout); }
    var save_timeout = setTimeout(save_word_fn(word), 300);
    word.save_timeout = save_timeout;
});
$('.curword').on('focusin', 'input', function(evt) {
    var timestamp = $(this).data('timestamp');
    var subs = MakonFM.subs;
    var i = MakonFM._i_by_ts(timestamp, subs);
    var word = subs[i];
    var prev_timeout = word.save_timeout;
    if (prev_timeout) { clearTimeout(prev_timeout); }
    delete word.save_timeout;
});

function Word(w) {
    if (w.winitd) { return w; }
    w.winitd = true;
    _to_observable(w, 'current');
    _to_observable(w, 'corrected');
    _to_observable(w, 'humanic');
    _to_observable(w, 'selected');
    return w;
}
function init_for_inspection(w) {
    if (w.iinitd) { return w; }
    w.iinitd = true;
    _to_observable(w, 'occurrence');
    _to_observable(w, 'wordform');
    w.fonet_human = Phonet.to_human(w.fonet).str;
    w.occurrence.subscribe(_update_wordform, w);
    return w;
}
function _to_observable(obj, field_name) {
    obj[field_name] = ko.observable(obj[field_name]);
}
function _update_wordform(occurrence) {
    if (typeof occurrence !== 'string') { return; }
    var lc = occurrence.toLowerCase();
    var wordform;
    
    // \W matches multibyte letters :-(
    var match = /\W+$/.exec(lc);
    if (match) {
        var bW = match[0];
        var i = bW.length;
        var l = 0;
        while (bW.charCodeAt(i-1) < 128) {
            i--;
            l++;
        }
        wordform = lc.substr(0, lc.length - l);
    }
    else {
        wordform = lc;
    }
    
    var old_wf = this.wordform();
    if (old_wf !== wordform) {
        this.wordform(wordform);
        yft($('dd.wordform'));
    }
}

var SUB_VERSION = {};
$(document).one('init_arrived', function(evt, data) {
    SUB_VERSION = data.subversions;
    $('.js-set-name').val(data.author);
});
$('<script>')
.attr({
    src: MakonFM.INIT_URL + '?v=' + new Date().getTime(),
    type: 'text/javascript'
})
.appendTo('body')
.remove();


function _get_line_height_of($el) {
    var lh = $el.css('line-height');
    var re = /\d+/;
    var match = re.exec(lh);
    if (match) {
        return +match[0];
    }
    var fs = $el.css('font-size');
    match = re.exec(fs);
    if (match) {
        return ((+match) * 1.5);
    }
    ;;; console.log('failed to find line height of', $el, 'with line-height', lh, 'and font-size', fs);
    throw 'Failed to find line-height';
}

function _xreq(opt) {
    if ($('.ua-ie8').length && window.XDomainRequest) {
        jQuery.support.cors = true;
        // Use Microsoft XDR
        var xdr = new XDomainRequest();
        xdr.open(opt.type, opt.url);
        var promise = new $.Deferred();
        promise.xdr = xdr;
        xdr.onload = function() {
            promise.resolve($.parseJSON(xdr.responseText));
        };
        xdr.onerror = function() {
            promise.reject();
        };
        xdr.ontimeout = function() {
            promise.reject();
        };
        xdr.send($.param(opt.data));
        return promise;
    } else {
        return $.ajax(opt);
    }
}

function _clear_selection() {
    if (window.getSelection) {
        try {
            var sel = getSelection();
            if (sel) { sel.collapseToStart() }
        } catch(e) {
            ;;; console.log('getSelection().collapseToStart() failed:', e);
        }
    }
    else if (document.selection) {
//        document.selection.clear();   // crashes IE8/WXP
    }
    else {
        ;;; console.log('cannot clear selection: neither getSelection nor document.selection present');
    }
}

function _string_starts_with(string, startsWith) {
    string = string || "";
    if (startsWith.length > string.length)
        return false;
    return string.substring(0, startsWith.length) === startsWith;
}

function place_humanic_markers(subs) {
    var chunks = [];
    var in_humanic = false;
    var cur_chunk = {};
    var dur = MakonFM.jp.status.duration;
    for (var i = 0; i < subs.length; i++) {
        var sub = subs[i];
        if      ( in_humanic && (( sub.humanic === 1) || ($.isFunction(sub.humanic) && sub.humanic()))) {
            cur_chunk.end = subs[i].timestamp;
        }
        else if ( in_humanic && ( !sub.humanic        || ($.isFunction(sub.humanic) && sub.humanic()))) {
            in_humanic = false;
            chunks.push(cur_chunk);
            cur_chunk = {};
        }
        else if (!in_humanic && (( sub.humanic === 1) || ($.isFunction(sub.humanic) && sub.humanic()))) {
            in_humanic = true;
            cur_chunk.start = sub.timestamp;
            cur_chunk.end = sub.timestamp;
        }
    }
    var $seek_bar = $('.jp-seek-bar');
    clear_humanic_markers();
    $.map(chunks, function(chunk) {
        var left  = 100 * chunk.start / dur + '%';
        var width = 100 * (chunk.end - chunk.start) / dur + '%';
        $('<div>')
        .addClass('jpx-marker')
        .css({
            left:  left,
            width: width
        })
        .appendTo('.jp-seek-bar');
    });
}
function clear_humanic_markers() {
    $('.jpx-marker').remove();
}

function yft(el) {
    var me = this;
    var args = arguments;
    if (!$.ui) {
        return $.getScript(MAKONFM_CONFIG.JQ_UI_URL)
        .done(function() { yft.apply(me, args); });
    }
    $(el)
    .css('background-color', 'yellow')
    .animate({'background-color': 'transparent'}, {duration: 2000});
}

function save_word(word) {
    delete word.save_timeout;
    delete word.dirty;
    word.corrected(true);
    _xreq({
        url: MakonFM.SAVE_WORD_URL,
        type: 'post',
        cache: false,
        dataType: 'json',
        data: {
            stem: MakonFM.current_file(),
            wordform: word.wordform(),
            occurrence: word.occurrence(),
            fonet: word.fonet,
            timestamp: word.timestamp
        }
    }).done( function(result) {
        if (result && result.success === 1) {
            word.corrected(false);
        }
        else {
            throw 'saving word failed';
        }
    });
}

function save_word_fn(word) {
    return function() { save_word(word); };
}

if ($.cookie('session')) { } else {
    var sess = new Date().getTime() + '_' + (Math.random()+'').substr(2);
    $.cookie('session', sess, { path: '/', expires: 365 });
}
