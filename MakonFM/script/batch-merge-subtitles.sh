#!/bin/bash

usage() {
    echo "$0 -h dir_with_humanic_subs -r dir_with_recognized_subs -o output_dir"
    exit 1
}

PATH="$PATH:"`dirname "$0"`

while getopts 'h:r:o:' OPTION; do
    case "$OPTION" in
        h)  HUMDIR="$OPTARG" ;;
        r)  RECDIR="$OPTARG" ;;
        o)  OUTDIR="$OPTARG" ;;
        ?)  usage
    esac
done
if [ -z "$HUMDIR" ]; then usage; fi
if [ -z "$RECDIR" ]; then usage; fi
if [ -z "$OUTDIR" ]; then usage; fi

cp "$HUMDIR"/*.sub.js "$OUTDIR/"

for s in "$RECDIR"/*.sub.js; do
    if (( `stat -c %s "$s"` < 1000 )); then continue; fi
    stem=`basename "$s"`
    echo $stem
    if [ -e "$HUMDIR/$stem" ]; then
        if merge_subtitles.pl "$s" "$HUMDIR/$stem" > "$OUTDIR/tmp"; then
            mv "$OUTDIR/tmp" "$OUTDIR/$stem"
        else
            rm "$OUTDIR/tmp"
        fi
    else
        cp "$s" "$OUTDIR/"
    fi
done
