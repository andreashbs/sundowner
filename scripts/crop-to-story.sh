#!/bin/bash
# Schneidet Videos aus videos-raw/ auf 9:16 (1080x1920, Story/Reels-Format) zu.
# Funktioniert egal ob das Ausgangsvideo quer oder hochkant ist — schneidet
# immer den größtmöglichen 9:16-Ausschnitt aus der Bildmitte.
#
# Nutzung:
#   1. Videos in den Ordner videos-raw/ legen
#   2. ./scripts/crop-to-story.sh ausführen
#   3. Ergebnisse liegen in videos-story/ (Endung "-story.mp4")

set -e

IN_DIR="videos-raw"
OUT_DIR="videos-story"
mkdir -p "$OUT_DIR"

shopt -s nullglob nocaseglob
files=("$IN_DIR"/*.mp4 "$IN_DIR"/*.mov "$IN_DIR"/*.m4v)

if [ ${#files[@]} -eq 0 ]; then
  echo "Keine Videos in $IN_DIR/ gefunden."
  exit 0
fi

for f in "${files[@]}"; do
  name=$(basename "$f")
  base="${name%.*}"
  out="$OUT_DIR/${base}-story.mp4"

  echo "→ Verarbeite: $name"
  ffmpeg -y -i "$f" \
    -vf "crop='min(iw,ih*9/16)':'min(ih,iw*16/9)',scale=1080:1920,setsar=1" \
    -c:v libx264 -crf 20 -preset medium \
    -c:a aac -b:a 128k \
    "$out" -loglevel error -stats

  echo "✓ Fertig: $out"
done

echo ""
echo "Alle Videos verarbeitet. Ergebnisse liegen in $OUT_DIR/"
