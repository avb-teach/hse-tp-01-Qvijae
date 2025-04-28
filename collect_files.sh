#!/usr/bin/env bash
set -euo pipefail


usage() {
  cat <<EOF >&2
Usage: $0 [--max_depth N] INPUT_DIR OUTPUT_DIR
  --max_depth N   preserve directory structure up to depth N (default: flatten all)
  INPUT_DIR       source directory
  OUTPUT_DIR      destination directory
EOF
  exit 1
}


M=0
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
  local DIR BASE NAME EXT TGT i
  DIR=$(dirname "$DST")
  BASE=$(basename "$DST")
  if [[ "$BASE" == *.* ]]; then
    NAME="${BASE%.*}"
    EXT=".${BASE##*.}"
  else
    NAME="$BASE"
    EXT=""
  fi
  mkdir -p "$DIR"
  TGT="$DST"; i=1
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
  keep=$(( M + 1 ))       

  if (( len <= keep )); then
    new_parts=("${parts[@]}")
  else
    drop=$(( len - keep ))
    new_parts=("${parts[@]:drop}")
  fi

  new_rel="$(IFS=/; echo "${new_parts[*]}")"
  dst="$OUTPUT_DIR/$new_rel"
  copy_with_suffix "$file" "$dst"
done
