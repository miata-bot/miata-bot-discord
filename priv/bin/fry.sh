#!/bin/bash
set -e

INPUT=$1
OUTPUT=$2
WIDTH=$(identify -format "%w" $INPUT)
HEIGHT=$(identify -format "%h" $INPUT)
SATURATED=saturated.png
MASK=mask.png
RESULT=result.png

convert -seed $RANDOM -size ${WIDTH}x${HEIGHT} xc: +noise random -colorspace gray -blur 0x3  -edge 10 $MASK

convert $INPUT $MASK \
\( -clone 0 -alpha extract \) \
\( -clone 1 -clone 2 -alpha off -compose copy_opacity -composite -alpha on -channel a -evaluate multiply 0.3 +channel \) \
-delete 1,2 -compose overlay -composite $RESULT
convert $RESULT -modulate 100,500,100 $SATURATED
convert $SATURATED -quality 5% $OUTPUT
rm $MASK $RESULT $SATURATED
