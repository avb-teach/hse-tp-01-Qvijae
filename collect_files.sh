#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF >&2
Usage: $0 [--max_depth N] INPUT_DIR OUTPUT_DIR
  --max_depth N   preserve directory structure up to depth N (default: 1, flat copy)
  INPUT_DIR       source directory to collect files from
  OUTPUT_DIR      target directory to copy files into
EOF
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
  mkdir -p "$(dirname "$DST")"
  local BASE=$(basename "$DST")
  local NAME EXT
  if [[ "$BASE" == *.* ]]; then
    NAME="${BASE%.*}"
    EXT=".${BASE##*.}"
  else
    NAME="$BASE"
    EXT=""
  fi
  local TGT=$DST i=1
  while [[ -e "$TGT" ]]; do
    TGT="$(dirname "$DST")/${NAME}_$i${EXT}"
    ((i++))
  done
  cp "$SRC" "$TGT"
}
export -f copy_with_suffix


find "$INPUT_DIR" -type f | while IFS= read -r file; do

  rel="${file#"$INPUT_DIR"/}"
  IFS='/' read -r -a parts <<< "$rel"
  depth=${#parts[@]}    

  if (( depth <= M )); then
    new_parts=("${parts[@]}")
  else
    drop=$(( depth - M ))
    new_parts=("${parts[@]:drop}")
  fi


  new_rel="$(IFS=/; echo "${new_parts[*]}")"
  DEST="$OUTPUT_DIR/$new_rel"
  copy_with_suffix "$file" "$DEST"
done
