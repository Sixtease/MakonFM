var MakonFM = {};

MakonFM.MEDIA_BASE = 'http://commondatastorage.googleapis.com/karel-makon-mp3/';

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
    supplied: "mp3"
});

MakonFM.upd_sub = function (ts, subs, i) {
    if (!subs) subs = MakonFM.subs;
    if (!i) i = 0;
    while (subs[i++].timestamp < ts) { }
    while (subs[--i].timestamp > ts) { }
    var sub = subs[i];
    $('.subtitles .Word').removeClass('cur');
    $('.subtitles .Word[data-timestamp="'+sub.timestamp+'"]').addClass('cur');
};

$('#ts').change(function() {
    MakonFM.upd_sub($(this).val());
});

MakonFM.subs = [
    {
        timestamp: 0,
        occurrence: 'Ťuk',
        fonet: 'tj u k',
        wordform: 'ťuk'
    },
    {
        timestamp: 1.1,
        occurrence: 'ťuk!',
        fonet: 'tj u k',
        wordform: 'ťuk'
    },
    {
        timestamp: 2.2,
        occurrence: '"Takže',
        fonet: 't a k zh e',
        wordform: 'takže'
    },
    {
        timestamp: 3.3,
        occurrence: 'dobrý',
        fonet: 'd o b r ii',
        wordform: 'dobrý'
    },
    {
        timestamp: 4.4,
        occurrence: 'večer,"',
        fonet: 'v e ch e r',
        wordform: 'večer'
    },
    {
        timestamp: 5.5,
        occurrence: 'řekl',
        fonet: 'r zh e k l',
        wordform: 'řekl'
    },
    {
        timestamp: 6.6,
        occurrence: 'jelen.',
        fonet: 'j e l e ng',
        wordform: 'jelen'
    }
];
