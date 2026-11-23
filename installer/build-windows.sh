#!/usr/bin/env bash
# Dong goi bo cai Windows (.exe) tu ma nguon dang commit.
# Can: git, makensis (apt-get install nsis). Chay tu thu muc goc repo:
#   bash installer/build-windows.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/dist-installer}"
STAGE="$(mktemp -d)"
trap 'rm -rf -- "$STAGE"' EXIT

mkdir -p "$OUT" "$STAGE/payload"
git -C "$ROOT" archive HEAD \
  backend frontend docker docker-compose.yml .env.demo \
  LICENSE NOTICE NGUON-GOC.md THIRD-PARTY-LICENSES.md CAI-DAT-CONG-BINH.md \
  | tar -x -C "$STAGE/payload"

VER="$(git -C "$ROOT" rev-parse --short HEAD)"
EXE="$OUT/CongBinh-ZaloCRM-Setup-$VER.exe"
( cd "$ROOT/installer/windows" && makensis -V2 -DPAYLOAD="$STAGE/payload" -DOUTFILE="$EXE" ZL-CRM-Setup.nsi )
ls -l "$EXE"
