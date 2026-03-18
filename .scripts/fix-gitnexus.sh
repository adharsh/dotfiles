#!/bin/bash
# fix-gitnexus.sh — Post-install fixes for gitnexus on Ubuntu 22.04
#
# @ladybugdb/core ships a prebuilt native binary requiring GLIBC 2.38,
# but Ubuntu 22.04 has GLIBC 2.35. This script rebuilds from source
# with gcc-13 (including the FTS extension).
#
# Called from: initialize.sh, pnpm-update.service (systemd timer)

set -euo pipefail

PNPM_GLOBAL_DIR="$(dirname "$(pnpm root -g)")"
LBUG_DIR=$(find "$PNPM_GLOBAL_DIR/.pnpm" -path "*/@ladybugdb/core/package.json" -not -path "*/lbug-source/*" -printf '%h\n' 2>/dev/null | head -1)

if [ -z "$LBUG_DIR" ]; then
    echo "[fix-gitnexus] @ladybugdb/core not found, skipping."
    exit 0
fi

if node -e "require('$LBUG_DIR/lbug_native.js')" 2>/dev/null; then
    echo "[fix-gitnexus] @ladybugdb/core native binary OK, skipping rebuild."
    exit 0
fi

echo "[fix-gitnexus] Rebuilding @ladybugdb/core from source with gcc-13..."
(cd "$LBUG_DIR/lbug-source" && \
    CC=gcc-13 CXX=g++-13 cmake -B build/release \
        -DCMAKE_BUILD_TYPE=Release -DBUILD_NODEJS=TRUE -DBUILD_EXTENSIONS="fts" \
        -DCMAKE_C_COMPILER=gcc-13 -DCMAKE_CXX_COMPILER=g++-13 . && \
    cmake --build build/release --config Release -j"$(nproc)")

cp "$LBUG_DIR/lbug-source/tools/nodejs_api/build/lbugjs.node" "$LBUG_DIR/"

# Copy FTS extension to ladybugdb's runtime extension dir
LBUG_EXT_VER=$(node -e "console.log(require('$LBUG_DIR/package.json').version.replace(/\.\d+$/,''))" 2>/dev/null || echo "0.15.0")
mkdir -p "$HOME/.lbdb/extension/$LBUG_EXT_VER/linux_amd64/fts"
cp "$LBUG_DIR/lbug-source/extension/fts/build/libfts.lbug_extension" \
    "$HOME/.lbdb/extension/$LBUG_EXT_VER/linux_amd64/fts/"

echo "[fix-gitnexus] Done."
