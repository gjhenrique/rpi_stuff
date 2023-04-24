#!/usr/bin/env sh

if [ -z "$1" ]; then
  echo "Usage: $0 <file>"
  exit 1
fi

subtitles=$(ffprobe -v error -select_streams s -show_entries stream=index:stream_tags=language -of csv=print_section=0 "$1")

while IFS=',' read -r index language; do
  if [[ "$language" == "eng" || "$language" == "por" || "$language" == "ger" ]]; then
    filename="${1%.*}"
    output_file="$filename.$index.$language.srt"
    real_index=$((index-2))
    echo "Extracting $real_index to $output_file"
    ffmpeg -nostdin -y -v error -i "$1" -map 0:s:$real_index -c:s srt "$output_file"
  fi
done <<< "$subtitles"
