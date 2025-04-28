#!/usr/bin/env bash

set -euo pipefail

MAX_DEPTH=""
if [[ "$1" == "--max_depth" ]]; then
  MAX_DEPTH="-maxdepth $2"
  shift 2
fi
INPUT_DIR="$1"
OUTPUT_DIR="$2"

if [[ ! -d "$INPUT_DIR" ]]; then
  echo "ERROR: входная директория '$INPUT_DIR' не найдена" >&2
  exit 1
fi
mkdir -p "$OUTPUT_DIR"

copy_with_suffix() {
  local src="$1"
  local dst_dir="$2"
  local base=$(basename "$src")
  local name="${base%.*}"
  local ext="${base#*.}"
  local target="$dst_dir/$base"
  local i=1
  while [[ -e "$target" ]]; do
    target="$dst_dir/${name}_$i.${ext}"
    ((i++))
  done
  cp "$src" "$target"
}

find "$INPUT_DIR" $MAX_DEPTH -type f | while read -r file; do
  copy_with_suffix "$file" "$OUTPUT_DIR"
done
