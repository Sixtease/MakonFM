
var MAKONFM_CONFIG = {};
[%- server = c.config.server_base; %]
MAKONFM_CONFIG.STATIC_BASE        = '[% c.config.static_base %]';
MAKONFM_CONFIG.SERVER_BASE        = '[% server %]';
MAKONFM_CONFIG.SUBTITLE_BASE      = '[% server %]/static/subs/'
MAKONFM_CONFIG.SEND_SUBTITLES_URL = '[% server %]/subsubmit/';
MAKONFM_CONFIG.SAVE_WORD_URL      = '[% server %]/saveword/';
MAKONFM_CONFIG.INIT_URL           = '[% server %]/init/';
MAKONFM_CONFIG.NOTIFY_PAGELOAD_URL= '[% server %]/req/';
MAKONFM_CONFIG.GET_HUMPART_URL    = '[% server %]/static/humpart.js';
[%- IF c.config.local %]
MAKONFM_CONFIG.MEDIA_BASE         = '/static/audio/';
MAKONFM_CONFIG.JQ_UI_URL          = '/static/jquery-ui.js';
[%- ELSE %]
MAKONFM_CONFIG.MEDIA_BASE         = 'http://commondatastorage.googleapis.com/karel-makon-mp3/';
MAKONFM_CONFIG.JQ_UI_URL          = '//ajax.googleapis.com/ajax/libs/jqueryui/1/jquery-ui.js';
//MAKONFM_CONFIG.SUBTITLE_BASE      = 'http://commondatastorage.googleapis.com/karel-makon-sub/';
[%- END -%]
