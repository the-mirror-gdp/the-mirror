#!/usr/bin/env sh

NAME=macos_icon

mkdir -p $NAME.iconset

rsvg-convert -h 16 $NAME.svg > $NAME.iconset/icon_16x16.png
rsvg-convert -h 32 $NAME.svg > $NAME.iconset/icon_16x16@2x.png
rsvg-convert -h 32 $NAME.svg > $NAME.iconset/icon_32x32.png
rsvg-convert -h 64 $NAME.svg > $NAME.iconset/icon_32x32@2x.png
rsvg-convert -h 128 $NAME.svg > $NAME.iconset/icon_128x128.png
rsvg-convert -h 256 $NAME.svg > $NAME.iconset/icon_128x128@2x.png
rsvg-convert -h 256 $NAME.svg > $NAME.iconset/icon_256x256.png
rsvg-convert -h 512 $NAME.svg > $NAME.iconset/icon_256x256@2x.png
rsvg-convert -h 512 $NAME.svg > $NAME.iconset/icon_512x512.png
rsvg-convert -h 1024 $NAME.svg > $NAME.iconset/icon_512x512@2x.png

iconutil -c icns $NAME.iconset

rm -Rf $NAME.iconset
