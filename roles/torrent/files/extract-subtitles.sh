#!/usr/bin/env sh

LOG_FILE="/media/subtitle_extract.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a "$LOG_FILE" >&2
}

if [ -n "$1" ]; then
    file_path="$1"
else
    file_path="${radarr_moviefile_path:-$sonarr_episodefile_paths}"
    if [ -z "$file_path" ]; then
        echo "No file path provided as argument or found in environment variables"
        exit 1
    fi
fi

log "Using file path: $file_path"

subtitles=$(ffprobe -v error -select_streams s -show_entries stream=index:stream_tags=language -of csv=print_section=0 "$file_path" 2>> "$LOG_FILE")

while IFS=',' read -r index language; do
  if [[ "$language" == "eng" || "$language" == "por" || "$language" == "ger" ]]; then
    filename="${file_path%.*}"
    output_file="$filename.$index.$language.srt"
    real_index=$((index-2))
    log "Extracting $real_index to $output_file"

    ffmpeg_output=$(ffmpeg -nostdin -y -v error -i "$file_path" -map 0:s:$real_index -c:s srt "$output_file" 2>&1)
    if [ $? -ne 0 ]; then
        log_error "Failed to extract subtitle: $ffmpeg_output"
    else
        log "Successfully extracted subtitle to: $output_file"
    fi
  fi
done <<< "$subtitles"

log "Successful"
