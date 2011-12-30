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


