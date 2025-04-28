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
  M="$1"; shift
fi

[[ $# -eq 2 ]] || usage
INPUT_DIR="$1"
OUTPUT_DIR="$2"

if [[ ! -d "$INPUT_DIR" ]]; then
  echo "ERROR: входная директория '$INPUT_DIR' не найдена" >&2
  exit 1
fi
mkdir -p "$OUTPUT_DIR"

copy_with_suffix() {
  local srcpath="$1"
  local dstpath="$2"
  mkdir -p "$(dirname "$dstpath")"

  local filename="$(basename "$dstpath")"
  local base ext
  if [[ "$filename" == *.* ]]; then
    base="${filename%.*}"
    ext=".${filename##*.}"
  else
    base="$filename"
    ext=""
  fi

  local target="$dstpath"
  local i=1
  while [[ -e "$target" ]]; do
    target="$(dirname "$dstpath")/${base}_$i${ext}"
    ((i++))
  done

  cp "$srcpath" "$target"
}

export -f copy_with_suffix

find "$INPUT_DIR" -type f | while IFS= read -r file; do
  rel="${file#"$INPUT_DIR"/}"
  IFS='/' read -r -a parts <<< "$rel"
  num_dirs=$(( ${#parts[@]} - 1 ))
  depth=$(( num_dirs + 1 ))

  if (( depth <= M )); then
    dest="$OUTPUT_DIR/$rel"
  else
    strip=$(( num_dirs - (M - 1) ))
    new_parts=( "${parts[@]:strip}" )
    new_rel="$(IFS=/; echo "${new_parts[*]}")"
    dest="$OUTPUT_DIR/$new_rel"
  fi

  copy_with_suffix "$file" "$dest"
done