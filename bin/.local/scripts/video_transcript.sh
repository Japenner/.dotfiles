#!/bin/bash

# Set the playlist URL
PLAYLIST_ID=$1
PLAYLIST_URL="https://www.youtube.com/playlist?list=$PLAYLIST_ID"

# Get video URLs from the playlist
VIDEO_URLS=$(~/.local/scripts/yt-dlp --flat-playlist --get-id "$PLAYLIST_URL")

# Loop through each video in the playlist
for VIDEO_ID in $VIDEO_URLS; do
    VIDEO_URL="https://youtu.be/$VIDEO_ID"

    # Extract the video title and format it as a filename
    VIDEO_TITLE=$(~/.local/scripts/yt-dlp --get-title "$VIDEO_URL" | tr '[:upper:]' '[:lower:]' | tr -s ' ' '_' | tr -dc '[:alnum:]_-')

    # Define the transcript filename
    TRANSCRIPT_FILE="${VIDEO_TITLE}.txt"

    echo "Processing: $VIDEO_TITLE"

    # Download subtitles and clean them up
    ~/.local/scripts/yt-dlp --skip-download --write-subs --write-auto-subs --sub-lang en --sub-format srt --output "transcript.srt" "$VIDEO_URL" && \
    sed -e '/^[0-9][0-9]:[0-9][0-9]:[0-9][0-9].[0-9][0-9][0-9] --> [0-9][0-9]:[0-9][0-9]:[0-9][0-9].[0-9][0-9][0-9]$/d' \
        -e '/^[[:digit:]]\{1,4\}$/d' \
        -e 's/<[^>]*>//g' \
        -e '/^[[:space:]]*$/d' transcript.srt > "$TRANSCRIPT_FILE" && \
    rm transcript.srt

    echo "Transcript saved as: $TRANSCRIPT_FILE"
done
