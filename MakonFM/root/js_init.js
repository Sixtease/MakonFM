
var MAKONFM_CONFIG = {};
[%- server = c.config.server_base; %]
MAKONFM_CONFIG.STATIC_BASE        = '[% c.config.static_base %]';
MAKONFM_CONFIG.SERVER_BASE        = '[% server %]';
MAKONFM_CONFIG.SUBTITLE_BASE      = '[% server %]/static/subs/'
MAKONFM_CONFIG.SEND_SUBTITLES_URL = '[% server %]/subsubmit/';
MAKONFM_CONFIG.INIT_URL           = '[% server %]/init/';
[%- IF c.config.local %]
MAKONFM_CONFIG.MEDIA_BASE         = '/static/audio/';
[%- ELSE %]
MAKONFM_CONFIG.MEDIA_BASE         = 'http://commondatastorage.googleapis.com/karel-makon-mp3/';
//MAKONFM_CONFIG.SUBTITLE_BASE      = 'http://commondatastorage.googleapis.com/karel-makon-sub/';
[%- END -%]
