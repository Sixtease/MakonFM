#!/bin/bash

echo "jsonp_humpart({\"modified\":\"`date '+%FT%T%:::z'`\",\"data\":{"; for s in "$1"/*.sub.js; do echo "\"`basename $s | sed 's/.sub.js//'`\":{\"human\":" `grep -w humanic "$s" | wc -l` ',"total":' `grep -w occurrence "$s" | wc -l` '},'; done; echo '}});'
