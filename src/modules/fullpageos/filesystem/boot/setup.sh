#!/bin/bash
set -euo pipefail

# Defaults — überschreibbar via Env oder Flags
WRM_TOKEN="${WRM_TOKEN:-}"
EVA_API_BASE="${EVA_API_BASE:-}"   # z.B. http://192.168.39.191:8000  oder https://eva.praxis.de
EVA_UI_BASE="${EVA_UI_BASE:-}"     # z.B. http://192.168.39.191:3000  oder https://eva.praxis.de
OUTPUT_FILE="${OUTPUT_FILE:-/boot/firmware/fullpageos.txt}"
DRY_RUN="${DRY_RUN:-0}"

usage() {
  echo "Usage: $0 --token T --api-base URL --ui-base URL [--output FILE] [--dry-run]" >&2
  exit 2
}

while [ $# -gt 0 ]; do
  case "$1" in
    --token)    WRM_TOKEN="$2"; shift 2;;
    --api-base) EVA_API_BASE="$2"; shift 2;;
    --ui-base)  EVA_UI_BASE="$2"; shift 2;;
    --output)   OUTPUT_FILE="$2"; shift 2;;
    --dry-run)  DRY_RUN=1; shift;;
    -h|--help)  usage;;
    *) echo "Unbekannte Option: $1" >&2; usage;;
  esac
done

# Interaktiver Fallback nur, wenn nicht gesetzt
[ -n "$WRM_TOKEN" ]    || read -r -p "Token: " WRM_TOKEN
[ -n "$EVA_API_BASE" ] || read -r -p "eva-api Basis-URL (z.B. http://192.168.39.191:8000): " EVA_API_BASE
[ -n "$EVA_UI_BASE" ]  || read -r -p "eva-ui Basis-URL (z.B. http://192.168.39.191:3000): " EVA_UI_BASE

[ -n "$WRM_TOKEN" ]    || { echo "Token fehlt" >&2; exit 1; }
[ -n "$EVA_API_BASE" ] || { echo "eva-api Basis-URL fehlt" >&2; exit 1; }
[ -n "$EVA_UI_BASE" ]  || { echo "eva-ui Basis-URL fehlt" >&2; exit 1; }

# generate-link aufrufen, HTTP-Status separat prüfen
api_url="${EVA_API_BASE}/extern/wrm/api/v1/waitingroom-monitor/generate-link?token=${WRM_TOKEN}"
resp_file="$(mktemp)"
http_code="$(curl -sS -o "$resp_file" -w '%{http_code}' "$api_url" || echo 000)"
if [ "$http_code" != "200" ]; then
  echo "Fehler: generate-link → HTTP $http_code" >&2
  cat "$resp_file" >&2; echo >&2
  rm -f "$resp_file"; exit 1
fi

# Antwort ist ein JSON-String mit Pfad → Quotes entfernen
path="$(tr -d '"' < "$resp_file")"
rm -f "$resp_file"

# Validierung: muss /wrm/-Pfad sein, kein Error-JSON
case "$path" in
  /wrm/*) ;;
  *) echo "Unerwartete Antwort (kein /wrm/-Pfad): $path" >&2; exit 1;;
esac

final_link="${EVA_UI_BASE}${path}"
echo "Anzeige-Link: $final_link"

if [ "$DRY_RUN" = "1" ]; then
  echo "(dry-run: $OUTPUT_FILE nicht geschrieben)"
  exit 0
fi

[ -f "$OUTPUT_FILE" ] || { echo "Konfig-Datei $OUTPUT_FILE nicht gefunden" >&2; exit 1; }
echo "$final_link" > "$OUTPUT_FILE"
echo "Geschrieben nach $OUTPUT_FILE"