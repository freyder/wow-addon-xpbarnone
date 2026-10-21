#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
version=$(awk -F': ' '/^## Version:/{print $2; exit}' "$repo_dir/XPBarNone.toc")
dist_dir="$repo_dir/dist"
work_dir=$(mktemp -d)
package_dir="$work_dir/XPBarNone"

cleanup() {
    rm -rf "$work_dir"
}
trap cleanup EXIT

if [[ -z "$version" ]]; then
    echo "Could not determine version from XPBarNone.toc" >&2
    exit 1
fi

if [[ ! -f "$repo_dir/libs/AceGUI-3.0/widgets/AceGUIWidget-CheckBox.lua" ]]; then
    echo "Embedded libraries are missing; assemble or fetch .pkgmeta externals first." >&2
    exit 1
fi

checkbox_version=$(awk -F'[, ]+' '/local Type, Version = "CheckBox"/{print $6; exit}' \
    "$repo_dir/libs/AceGUI-3.0/widgets/AceGUIWidget-CheckBox.lua" | tr -d '\r')
if [[ -z "$checkbox_version" || "$checkbox_version" -lt 27 ]]; then
    echo "AceGUI CheckBox widget version 27 or newer is required." >&2
    exit 1
fi

mkdir -p "$package_dir" "$dist_dir"
rsync -a \
    --exclude='.git/' \
    --exclude='.github/' \
    --exclude='.gitignore' \
    --exclude='.pkgmeta' \
    --exclude='dist/' \
    --exclude='tools/' \
    "$repo_dir/" "$package_dir/"

archive="$dist_dir/XPBarNone-$version.zip"
rm -f "$archive"
(cd "$work_dir" && 7z a -tzip -mx=9 "$archive" XPBarNone >/dev/null)

echo "$archive"
