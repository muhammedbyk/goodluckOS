#!/usr/bin/env bash
echo "[*] Starting build..."
echo "[*] Note: You can use this script to rebuild specific packages. (eg. ./scripts/build.sh puppy-rebuild)"

br() { make -C buildroot O="/src/out" BR2_EXTERNAL="/src" BR2_DL_DIR="/src/dl" "$@"; }

if [ $# -gt 0 ]; then
    br "$@"
    exit
fi

# Buildroot copies goodluckOS's own packages (SITE_METHOD = local) into out/ only the first time
# it builds them, so a plain build never picks up later changes to their sources. Rebuild the
# enabled ones every time (<pkg>-rebuild copies the sources again); they are small.
rebuild=()
for mk in /src/package/*/*.mk; do
    grep -q '_SITE_METHOD = local' "$mk" || continue
    pkg=$(basename "$(dirname "$mk")")
    grep -q "^BR2_PACKAGE_$(echo "$pkg" | tr 'a-z-' 'A-Z_')=y" /src/out/.config 2>/dev/null && rebuild+=("$pkg-rebuild")
done
echo "[*] Rebuilding goodluckOS's own packages: ${rebuild[*]:-none}"
br "${rebuild[@]}" all
