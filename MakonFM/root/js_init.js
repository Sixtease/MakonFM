
var MAKONFM_CONFIG = {};
MAKONFM_CONFIG.STATIC_BASE        = '[% c.config.static_base %]';
MAKONFM_CONFIG.SUBTITLE_BASE      = '[% c.config.server_base %]/static/subs/'
MAKONFM_CONFIG.SEND_SUBTITLES_URL = '[% c.config.server_base %]/subsubmit/';
MAKONFM_CONFIG.SUBVERSIONS_URL    = '[% c.config.server_base %]/subversions/';
MAKONFM_CONFIG.SETNAME_URL        = '[% c.config.server_base %]/setname/';
[%- IF c.config.local %]
MAKONFM_CONFIG.MEDIA_BASE         = '/static/audio/';
[%- ELSE %]
MAKONFM_CONFIG.MEDIA_BASE         = 'http://commondatastorage.googleapis.com/karel-makon-mp3/';
//MAKONFM_CONFIG.SUBTITLE_BASE      = 'http://commondatastorage.googleapis.com/karel-makon-sub/';
[%- END -%]
