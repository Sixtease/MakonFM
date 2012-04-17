
var MAKONFM_CONFIG = {};
[%- IF c.config.local %]
MAKONFM_CONFIG.MEDIA_BASE    = '/static/audio/';
MAKONFM_CONFIG.SUBTITLE_BASE = '/static/subs/';
MAKONFM_CONFIG.SEND_SUBTITLES_URL = '/subsubmit/';
MAKONFM_CONFIG.SUBVERSIONS_URL    = '/subversions/';
[%- ELSE %]
MAKONFM_CONFIG.MEDIA_BASE    = 'http://commondatastorage.googleapis.com/karel-makon-mp3/';
MAKONFM_CONFIG.SUBTITLE_BASE = 'http://commondatastorage.googleapis.com/karel-makon-sub/';
MAKONFM_CONFIG.SEND_SUBTITLES_URL = '[% c.config.server_base %]/subsubmit/';
MAKONFM_CONFIG.SUBVERSIONS_URL    = '[% c.config.server_base %]/subversions/';
[%- END -%]
MAKONFM_CONFIG.STATIC_BASE = '[% c.config.static_base %]';
