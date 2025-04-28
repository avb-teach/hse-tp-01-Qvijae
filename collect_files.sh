#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 [--max_depth N] INPUT_DIR OUTPUT_DIR" >&2
  exit 1
}

M=1
if [[ "${1:-}" == "--max_depth" ]]; then
  shift
  [[ $# -eq 3 ]] || usage
  [[ "$1" =~ ^[0-9]+$ ]] || usage
  M=$1
  shift
fi

[[ $# -eq 2 ]] || usage
INPUT="$1"; OUTPUT="$2"

[[ -d "$INPUT" ]] || { echo "ERROR: входная директория '$INPUT' не найдена" >&2; exit 1; }
mkdir -p "$OUTPUT"


copy_with_suffix() {
  local SRC="$1" DST="$2"
  mkdir -p "$(dirname "$DST")"
  local BASE="$(basename "$DST")"
  local NAME EXT
  if [[ "$BASE" == *.* ]]; then
    NAME="${BASE%.*}"
    EXT=".${BASE##*.}"
  else
    NAME="$BASE"
    EXT=""
  fi
  local TGT="$DST"
  local i=1
  while [[ -e "$TGT" ]]; do
    TGT="$(dirname "$DST")/${NAME}_${i}${EXT}"
    ((i++))
  done
  cp "$SRC" "$TGT"
}


find "$INPUT" -type f | while IFS= read -r FILE; do
  REL="${FILE#"$INPUT"/}"
  IFS='/' read -r -a PARTS <<< "$REL"
  NDIR=$(( ${#PARTS[@]} - 1 ))
  D=$(( NDIR + 1 ))

  if (( D <= M )); then
    NEW=( "${PARTS[@]}" )
  else
    DROP=$(( D - M ))
    NEW=( "${PARTS[@]:DROP}" )
  fi

  NEWREL="$(IFS=/; echo "${NEW[*]}")"
  DST="$OUTPUT/$NEWREL"
  copy_with_suffix "$FILE" "$DST"
done