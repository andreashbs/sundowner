#!/bin/bash
# Verarbeitet Fotos aus gallery/stop-1 .. gallery/stop-6 für die Website:
# - verkleinert große Fotos auf max. 1600px Breite (spart Ladezeit)
# - erzeugt Thumbnails (400px) für die Übersichts-Kacheln
# - baut gallery/manifest.json, das die Website zum Anzeigen der Fotos nutzt
#
# Nutzung:
#   1. Fotos in gallery/stop-1/, gallery/stop-2/ usw. legen (jpg/jpeg/png)
#   2. ./scripts/build-gallery.sh ausführen
#   3. git add, commit, push — fertig sind die Fotos live

set -e

GALLERY_DIR="gallery"
STOPS=(stop-1 stop-2 stop-3 stop-4 stop-5 stop-6)
MANIFEST="$GALLERY_DIR/manifest.json"

echo "{" > "$MANIFEST"
first_stop=true

for stop in "${STOPS[@]}"; do
  dir="$GALLERY_DIR/$stop"
  mkdir -p "$dir/thumbs"

  shopt -s nullglob nocaseglob
  photos=("$dir"/*.jpg "$dir"/*.jpeg "$dir"/*.png)
  shopt -u nocaseglob

  entries=()

  for photo in "${photos[@]}"; do
    name=$(basename "$photo")

    # Große Version verkleinern (in-place, max 1600px Breite)
    sips -Z 1600 "$photo" >/dev/null 2>&1

    # Thumbnail erzeugen
    thumb="$dir/thumbs/$name"
    sips -Z 400 "$photo" --out "$thumb" >/dev/null 2>&1

    entries+=("\"$name\"")
    echo "  ✓ $stop/$name (Original verkleinert + Thumbnail erstellt)"
  done

  if [ "$first_stop" = true ]; then
    first_stop=false
  else
    echo "," >> "$MANIFEST"
  fi

  # JSON-Array-Zeile für diesen Stop schreiben
  joined=$(IFS=,; echo "${entries[*]}")
  printf '  "%s": [%s]' "$stop" "$joined" >> "$MANIFEST"
done

echo "" >> "$MANIFEST"
echo "}" >> "$MANIFEST"

echo ""
echo "Fertig. gallery/manifest.json wurde aktualisiert."
echo "Jetzt committen & pushen:"
echo "  git add gallery/"
echo "  git commit -m 'Fotos hinzugefügt'"
echo "  git push"
