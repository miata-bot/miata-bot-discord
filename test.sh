#!/bin/bash

convert -seed $RANDOM -size 493x658 xc: +noise random -colorspace gray -blur 0x3  -edge 10  mask.png
convert back.jpg mask.png \
\( -clone 0 -alpha extract \) \
\( -clone 1 -clone 2 -alpha off -compose copy_opacity -composite -alpha on -channel a -evaluate multiply 0.1 +channel \) \
-delete 1,2 -compose overlay -composite result.png
convert result.png -quality 1% result3.jpg