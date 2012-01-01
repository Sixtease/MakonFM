var MakonFM = {
    MEDIA_BASE: 'http://commondatastorage.googleapis.com/karel-makon-mp3/',
    WORDS_PRE: 10,
    WORDS_POST: 10,
    CURRENT_INDEX: 0
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
    var first_need = subs[Math.max(0,i-10)].timestamp;
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
    var last_need = subs[Math.min(i+10,subs.length-1)].timestamp;
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

MakonFM.subs = [
    {
        timestamp: 0,
        occurrence: "Jářku.",
        fonet: "j aa rsh k u sp",
        wordform: "jářku"
    },

    {
        timestamp: 1.44067033907232,
        occurrence: "Nikdy",
        fonet: "nj i g d i sp",
        wordform: "nikdy"
    },

    {
        timestamp: 3.22101619080872,
        occurrence: "nestačí",
        fonet: "n e s t a ch ii sp",
        wordform: "nestačí"
    },

    {
        timestamp: 5.783850995763,
        occurrence: "uvést",
        fonet: "u v ee s t sp",
        wordform: "uvést"
    },

    {
        timestamp: 7.84958440496403,
        occurrence: "nějaké",
        fonet: "nj e j a k ee sp",
        wordform: "nějaké"
    },

    {
        timestamp: 8.99040496060959,
        occurrence: "zařízení",
        fonet: "z a rzh ii z e nj ii sp",
        wordform: "zařízení"
    },

    {
        timestamp: 10.1316055072214,
        occurrence: "do",
        fonet: "d o ",
        wordform: "do"
    },

    {
        timestamp: 12.9752787041161,
        occurrence: "provozu",
        fonet: "p r o v o z u sp",
        wordform: "provozu"
    },

    {
        timestamp: 14.0235074113626,
        occurrence: "a",
        fonet: "a sp",
        wordform: "a"
    },

    {
        timestamp: 16.2860551674247,
        occurrence: "odejít",
        fonet: "o d e j ii t sp",
        wordform: "odejít"
    },

    {
        timestamp: 19.0168830630013,
        occurrence: "od",
        fonet: "o t ",
        wordform: "od"
    },

    {
        timestamp: 21.8433354258505,
        occurrence: "něj.",
        fonet: "nj e j sp",
        wordform: "něj"
    },

    {
        timestamp: 23.0621728672422,
        occurrence: "Kdyby",
        fonet: "g d i b i sp",
        wordform: "kdyby"
    },

    {
        timestamp: 24.196696470436,
        occurrence: "se",
        fonet: "s e sp",
        wordform: "se"
    },

    {
        timestamp: 26.298575856365,
        occurrence: "to",
        fonet: "t o sp",
        wordform: "to"
    },

    {
        timestamp: 27.619372656823,
        occurrence: "stalo,",
        fonet: "s t a l o sp",
        wordform: "stalo"
    },

    {
        timestamp: 29.0507893506071,
        occurrence: "brzy",
        fonet: "b r z i sp",
        wordform: "brzy"
    },

    {
        timestamp: 32.0052703147752,
        occurrence: "by",
        fonet: "b i sp",
        wordform: "by"
    },

    {
        timestamp: 34.1084971801823,
        occurrence: "bylo",
        fonet: "b i l o sp",
        wordform: "bylo"
    },

    {
        timestamp: 37.0036308879828,
        occurrence: "k",
        fonet: "k ",
        wordform: "k"
    },

    {
        timestamp: 38.0612911795672,
        occurrence: "nepotřebě.",
        fonet: "n e p o t rsh e b j e sp",
        wordform: "nepotřebě"
    },

    {
        timestamp: 39.1884432887546,
        occurrence: "Chybně",
        fonet: "x i b nj e sp",
        wordform: "chybně"
    },

    {
        timestamp: 40.1926089783112,
        occurrence: "bychom",
        fonet: "b i x o m sp",
        wordform: "bychom"
    },

    {
        timestamp: 43.1081955663562,
        occurrence: "vinili",
        fonet: "v i nj i l i sp",
        wordform: "vinili"
    },

    {
        timestamp: 44.3584008554269,
        occurrence: "konstruktéra,",
        fonet: "k o n s t r u k t ee r a sp",
        wordform: "konstruktéra"
    },

    {
        timestamp: 46.8014697121209,
        occurrence: "že",
        fonet: "zh e sp",
        wordform: "že"
    },

    {
        timestamp: 48.9551279895894,
        occurrence: "vymyslel",
        fonet: "v i m i s l e l sp",
        wordform: "vymyslel"
    },

    {
        timestamp: 51.3745838514515,
        occurrence: "špatný",
        fonet: "sh p a t n ii sp",
        wordform: "špatný"
    },

    {
        timestamp: 53.6505106149153,
        occurrence: "stroj.",
        fonet: "s t r o j sp",
        wordform: "stroj"
    },

    {
        timestamp: 56.5197490165181,
        occurrence: "Jedinou",
        fonet: "j e dj i n ow sp",
        wordform: "jedinou"
    },

    {
        timestamp: 57.8986827547955,
        occurrence: "jeho",
        fonet: "j e h o sp",
        wordform: "jeho"
    },

    {
        timestamp: 60.473577614127,
        occurrence: "chybou",
        fonet: "x i b ow sp",
        wordform: "chybou"
    },

    {
        timestamp: 62.8942387920519,
        occurrence: "bylo,",
        fonet: "b i l o sp",
        wordform: "bylo"
    },

    {
        timestamp: 65.8822442914158,
        occurrence: "pokud",
        fonet: "p o k u t sp",
        wordform: "pokud"
    },

    {
        timestamp: 67.8109633000457,
        occurrence: "to",
        fonet: "t o sp",
        wordform: "to"
    },

    {
        timestamp: 69.3056873968174,
        occurrence: "bylo",
        fonet: "b i l o sp",
        wordform: "bylo"
    },

    {
        timestamp: 71.8300938843526,
        occurrence: "v",
        fonet: "f ",
        wordform: "v"
    },

    {
        timestamp: 74.4820378505655,
        occurrence: "jeho",
        fonet: "j e h o sp",
        wordform: "jeho"
    },

    {
        timestamp: 75.8065278900532,
        occurrence: "moci,",
        fonet: "m o c i sp",
        wordform: "moci"
    },

    {
        timestamp: 78.5124010817245,
        occurrence: "že",
        fonet: "zh e sp",
        wordform: "že"
    },

    {
        timestamp: 80.0898548009713,
        occurrence: "nenařídil",
        fonet: "n e n a rzh ii dj i l sp",
        wordform: "nenařídil"
    },

    {
        timestamp: 82.4137585210952,
        occurrence: "provádět",
        fonet: "p r o v aa dj e t sp",
        wordform: "provádět"
    },

    {
        timestamp: 83.6953596351771,
        occurrence: "odbornou",
        fonet: "o d b o r n ow sp",
        wordform: "odbornou"
    },

    {
        timestamp: 85.1911983908941,
        occurrence: "údržbu",
        fonet: "uu d r zh b u sp",
        wordform: "údržbu"
    },

    {
        timestamp: 87.9204364606734,
        occurrence: "zařízení,",
        fonet: "z a rzh ii z e nj ii sp",
        wordform: "zařízení"
    },

    {
        timestamp: 90.0225759133833,
        occurrence: "stálé",
        fonet: "s t aa l ee sp",
        wordform: "stálé"
    },

    {
        timestamp: 92.2380054059889,
        occurrence: "jeho",
        fonet: "j e h o sp",
        wordform: "jeho"
    },

    {
        timestamp: 95.1771941627854,
        occurrence: "opravy",
        fonet: "o p r a v i sp",
        wordform: "opravy"
    },

    {
        timestamp: 97.7277299240242,
        occurrence: "a",
        fonet: "a sp",
        wordform: "a"
    },

    {
        timestamp: 100.234509038617,
        occurrence: "výhledově",
        fonet: "v ii h l e d o v j e sp",
        wordform: "výhledově"
    },

    {
        timestamp: 101.835973426931,
        occurrence: "i",
        fonet: "i sp",
        wordform: "i"
    },

    {
        timestamp: 103.668143207721,
        occurrence: "úpravy,",
        fonet: "uu p r a v i sp",
        wordform: "úpravy"
    },

    {
        timestamp: 105.912947305572,
        occurrence: "aby",
        fonet: "a b i sp",
        wordform: "aby"
    },

    {
        timestamp: 107.710967646189,
        occurrence: "odpovídalo",
        fonet: "o t p o v ii d a l o sp",
        wordform: "odpovídalo"
    },

    {
        timestamp: 109.200494555285,
        occurrence: "technické",
        fonet: "t e x n i c k ee sp",
        wordform: "technické"
    },

    {
        timestamp: 111.820268533256,
        occurrence: "úrovni",
        fonet: "uu r o v nj i sp",
        wordform: "úrovni"
    },

    {
        timestamp: 114.626313036877,
        occurrence: "své",
        fonet: "s v ee sp",
        wordform: "své"
    },

    {
        timestamp: 116.263199398572,
        occurrence: "doby.",
        fonet: "d o b i sp",
        wordform: "doby"
    },

    {
        timestamp: 117.452433571857,
        occurrence: "Kolik",
        fonet: "k o l i k sp",
        wordform: "kolik"
    },

    {
        timestamp: 119.633771443767,
        occurrence: "cenných",
        fonet: "c e n ii x sp",
        wordform: "cenných"
    },

    {
        timestamp: 122.363661358746,
        occurrence: "zařízení",
        fonet: "z a rzh ii z e nj ii sp",
        wordform: "zařízení"
    },

    {
        timestamp: 124.534556830772,
        occurrence: "přišlo",
        fonet: "p rsh i sh l o sp",
        wordform: "přišlo"
    },

    {
        timestamp: 127.520426284281,
        occurrence: "pro",
        fonet: "p r o ",
        wordform: "pro"
    },

    {
        timestamp: 130.468692550163,
        occurrence: "tento",
        fonet: "t e n t o sp",
        wordform: "tento"
    },

    {
        timestamp: 132.412949429667,
        occurrence: "nedostatek",
        fonet: "n e d o s t a t e k sp",
        wordform: "nedostatek"
    },

    {
        timestamp: 135.083564798671,
        occurrence: "do",
        fonet: "d o ",
        wordform: "do"
    },

    {
        timestamp: 137.767258841361,
        occurrence: "šrotu.",
        fonet: "sh r o t u sp",
        wordform: "šrotu"
    },
];
