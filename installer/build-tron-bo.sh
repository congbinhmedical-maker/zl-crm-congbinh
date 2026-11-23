#!/usr/bin/env bash
# Tao 1 file zip tron goi: bo cai .exe + toan bo ma nguon + huong dan.
#   bash installer/build-tron-bo.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/dist-installer}"
VER="$(git -C "$ROOT" rev-parse --short HEAD)"
STAGE="$(mktemp -d)"
trap 'rm -rf -- "$STAGE"' EXIT

bash "$ROOT/installer/build-windows.sh" "$OUT" >/dev/null
PKG="$STAGE/CongBinh-ZaloCRM-TronBo"
mkdir -p "$PKG/MA-NGUON"
cp "$OUT/CongBinh-ZaloCRM-Setup-$VER.exe" "$PKG/CAI-DAT-CongBinh-ZaloCRM.exe"
cp "$ROOT/installer/HUONG-DAN-TRON-BO.txt" "$PKG/"
git -C "$ROOT" archive HEAD | tar -x -C "$PKG/MA-NGUON"

ZIP="$OUT/CongBinh-ZaloCRM-TronBo-$VER.zip"
rm -f -- "$ZIP"
( cd "$STAGE" && zip -qr -9 "$ZIP" "CongBinh-ZaloCRM-TronBo" )
ls -l "$ZIP"
