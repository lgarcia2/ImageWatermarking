#!/bin/bash
set -e
if [[ "$#" != 2 ]]; then
	echo "This is a script for watermarking images:"
	echo "To use this please provide as arguments:"
	echo "    1. The path to a directory containing only the image files you wish to watermark"
	echo "    2. The path to the image to use as a watermark."
	echo "USAGE:"
	echo "./watermark.sh {DirectoryOfImages} {PathToWatermarkFile}"
	echo "EXAMPLE"
	echo "./watermark.sh ../../images/sourceImages ../../images/watermark.png"
	exit 1
fi

IMAGEDIR=$1
WATERMARK=$2
WATERMARKSCALE=(1/4)
OUTPUTRELDIR="watermarked"

FFPROBEOUT=$(./ffmpeg/ffprobe.exe -i "$WATERMARK" -v error -hide_banner -select_streams v:0 -show_entries stream=width,height -of default=nw=1)

WATERMARKWIDTH=$(echo "$FFPROBEOUT" | grep width | cut -d '=' -f 2)
WATERMARKHEIGHT=$(echo "$FFPROBEOUT" | grep height | cut -d '=' -f 2)

if ! [ -d "$IMAGEDIR\\$OUTPUTRELDIR" ]; then
	mkdir $IMAGEDIR\\$OUTPUTRELDIR
fi

for IMAGE in $(ls -p $IMAGEDIR | grep -v /)
do
	IMAGEFULLPATH="$IMAGEDIR\\$IMAGE"
	echo "Attempting to Watermark $IMAGEFULLPATH ..."
	FFPROBEOUT=$(./ffmpeg/ffprobe.exe -i "$IMAGEFULLPATH" -v error -hide_banner -select_streams v:0 -show_entries stream=width,height -of default=nw=1)
	IMAGEWIDTH=$(echo "$FFPROBEOUT" | grep width | cut -d '=' -f 2)
	IMAGEHEIGHT=$(echo "$FFPROBEOUT" | grep height | cut -d '=' -f 2)
	
	if [ $IMAGEWIDTH -gt $IMAGEHEIGHT ]; then
		SCALEHEIGHT=$(( $IMAGEHEIGHT*$WATERMARKSCALE ))
		SCALEWIDTH=$(( ($SCALEHEIGHT*$WATERMARKWIDTH)/$WATERMARKHEIGHT ))
	else
		SCALEWIDTH=$(( $IMAGEWIDTH*$WATERMARKSCALE ))
		SCALEHEIGHT=$(( ($SCALEWIDTH*$WATERMARKHEIGHT)/$WATERMARKWIDTH ))
	fi
	
	OUTPUT=$IMAGEDIR\\$OUTPUTRELDIR\\$IMAGE
	
	./ffmpeg/ffmpeg.exe -v error -hide_banner -i "$IMAGEFULLPATH" -i "$WATERMARK" -filter_complex "[1:v]scale=$SCALEWIDTH:$SCALEHEIGHT,colorchannelmixer=aa=0.5[opacity];[0:v][opacity]overlay=main_w-overlay_w:main_h-overlay_h" "$OUTPUT"
	echo "Watermark Complete for: $IMAGEFULLPATH ..."
done

echo "All files found in directory watermarked successfully."