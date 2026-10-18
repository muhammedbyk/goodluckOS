#!/usr/bin/env bash
echo "[*] Starting build..."
echo "[*] Note: You can use this script to rebuild specific packages. (eg. ./scripts/build.sh puppy-rebuild)"

br() { make -C buildroot O="/src/out" BR2_EXTERNAL="/src" BR2_DL_DIR="/src/dl" "$@"; }

if [ $# -gt 0 ]; then
    br "$@"
    exit
fi

# Buildroot copies goodluckOS's own packages (SITE_METHOD = local) into out/ only the first time
# it builds them, so a plain build never picks up later changes to their sources. Mark the
# enabled ones to be built again (<pkg>-clean-for-rebuild also makes it copy the sources again),
# then build everything: they are built in the usual order, after what they need.
rebuild=()
for mk in /src/package/*/*.mk; do
    grep -q '_SITE_METHOD = local' "$mk" || continue
    pkg=$(basename "$(dirname "$mk")")
    grep -q "^BR2_PACKAGE_$(echo "$pkg" | tr 'a-z-' 'A-Z_')=y" /src/out/.config 2>/dev/null && rebuild+=("$pkg-clean-for-rebuild")
done
echo "[*] goodluckOS's own packages will be built again: ${rebuild[*]%-clean-for-rebuild}"
if [ ${#rebuild[@]} -gt 0 ]; then
    br "${rebuild[@]}" || exit
fi
br all
