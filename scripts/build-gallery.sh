#!/bin/bash
# Verarbeitet Fotos & Videos aus gallery/stop-1 .. gallery/stop-6 für die Website:
# - verkleinert große Fotos auf max. 1600px Breite (spart Ladezeit)
# - erzeugt Thumbnails (400px) für die Übersichts-Kacheln
# - erzeugt für Videos ein Vorschaubild aus dem ersten Frame
# - baut gallery/manifest.json, das die Website zum Anzeigen nutzt
#
# Nutzung:
#   1. Fotos in gallery/stop-1/, gallery/stop-2/ usw. legen (jpg/jpeg/png)
#   2. Optional: ein paar fertige Story-Videos (aus videos-story/) in den
#      gleichen Ordner kopieren (.mp4) — sie werden automatisch in die
#      Galerie-Lightbox eingebunden und abspielbar gemacht.
#   3. ./scripts/build-gallery.sh ausführen
#   4. git add, commit, push — fertig sind Fotos & Videos live
#
# Titelbild festlegen: die Datei, die als Kachel-Vorschaubild auf der
# Website erscheinen soll, mit "cover_" umbenennen (z.B. cover_IMG_4050.jpeg).
# Das Präfix wird auf der Website automatisch ausgeblendet.

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
  videos=("$dir"/*.mp4)
  shopt -u nocaseglob

  cover_entries=()
  entries=()

  for photo in "${photos[@]}"; do
    name=$(basename "$photo")

    # Große Version verkleinern — über eine Temp-Datei + atomaren mv,
    # damit iCloud Drive (oder andere Sync-Dienste) beim gleichzeitigen
    # Zugriff keine Konfliktkopien ("Name 2.jpg") erzeugen können.
    tmp_big="$dir/.tmp_${name}"
    cp "$photo" "$tmp_big"
    sips -Z 1600 "$tmp_big" >/dev/null 2>&1
    mv "$tmp_big" "$photo"

    # Thumbnail erzeugen (ebenfalls atomar)
    thumb="$dir/thumbs/$name"
    tmp_thumb="$dir/thumbs/.tmp_${name}"
    sips -Z 400 "$photo" --out "$tmp_thumb" >/dev/null 2>&1
    mv "$tmp_thumb" "$thumb"

    if [[ "$name" == cover_* ]]; then
      cover_entries+=("\"$name\"")
      echo "  ✓ $stop/$name (Original verkleinert + Thumbnail erstellt) [TITELBILD]"
    else
      entries+=("\"$name\"")
      echo "  ✓ $stop/$name (Original verkleinert + Thumbnail erstellt)"
    fi
  done

  for video in "${videos[@]}"; do
    name=$(basename "$video")
    base="${name%.mp4}"

    # Vorschaubild aus dem ersten Frame erzeugen (400px, wie Foto-Thumbs, atomar)
    thumb="$dir/thumbs/${base}.jpg"
    tmp_thumb="$dir/thumbs/.tmp_${base}.jpg"
    ffmpeg -y -i "$video" -vf "scale=400:-1" -vframes 1 "$tmp_thumb" -loglevel error
    mv "$tmp_thumb" "$thumb"

    if [[ "$name" == cover_* ]]; then
      cover_entries+=("\"$name\"")
      echo "  ✓ $stop/$name (Video-Vorschaubild erstellt) [TITELBILD]"
    else
      entries+=("\"$name\"")
      echo "  ✓ $stop/$name (Video-Vorschaubild erstellt)"
    fi
  done

  # Titelbild(er) an den Anfang stellen
  entries=("${cover_entries[@]}" "${entries[@]}")

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
