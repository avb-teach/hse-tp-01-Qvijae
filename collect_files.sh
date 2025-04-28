#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 [--max_depth N] INPUT_DIR OUTPUT_DIR" >&2
  exit 1
}

M=1
if [[ "${1:-}" == "--max_depth" ]]; then
  shift
  [[ $# -ge 1 && "$1" =~ ^[0-9]+$ ]] || usage
  M=$1
  shift
fi

[[ $# -eq 2 ]] || usage
INPUT_DIR=$1
OUTPUT_DIR=$2

[[ -d "$INPUT_DIR" ]] || { echo "ERROR: входная директория '$INPUT_DIR' не найдена" >&2; exit 1; }
mkdir -p "$OUTPUT_DIR"


copy_with_suffix() {
  local SRC=$1 DST=$2
  local DIR=$(dirname "$DST")
  local BASE=$(basename "$DST")
  local NAME EXT
  if [[ "$BASE" == *.* ]]; then
    NAME="${BASE%.*}"
    EXT=".${BASE##*.}"
  else
    NAME="$BASE"
    EXT=""
  fi
  mkdir -p "$DIR"
  local TGT="$DST" i=1
  while [[ -e "$TGT" ]]; do
    TGT="$DIR/${NAME}_$i${EXT}"
    ((i++))
  done
  cp "$SRC" "$TGT"
}

find "$INPUT_DIR" -type f | while IFS= read -r file; do
  rel="${file#"$INPUT_DIR"/}"
  IFS='/' read -ra parts <<< "$rel"
  len=${#parts[@]}

  if (( len <= M )); then
    new_parts=( "${parts[@]}" )
  else
    start=$(( len - M ))
    new_parts=( "${parts[@]:start}" )
  fi

  new_rel="$(IFS=/; echo "${new_parts[*]}")"
  dst="$OUTPUT_DIR/$new_rel"
  copy_with_suffix "$file" "$dst"
done