#!/bin/sh
# CodeCrew installer
# Usage: curl -fsSL https://codecrew.aichargelabs.com/install.sh | sh
# Env: CODECREW_VERSION=1.0.0, CODECREW_DRY_RUN=1
# Flag: --dry-run
# Author: aichargelabs

set -eu

dry_run=0
for arg in "$@"; do
    case "$arg" in
        --dry-run) dry_run=1 ;;
        *) printf '%s\n' "Error: unsupported option: $arg" >&2; exit 1 ;;
    esac
done
if [ "${CODECREW_DRY_RUN-}" = "1" ]; then
    dry_run=1
fi

os=$(uname -s 2>/dev/null || true)
case "$os" in
    Darwin) os_name=darwin ;;
    Linux) os_name=linux ;;
    MINGW*|MSYS*|CYGWIN*)
        if [ "$dry_run" -eq 1 ]; then
            os_name=linux
        else
            printf '%s\n' "Error: unsupported operating system: $os (supported: Darwin, Linux)" >&2
            exit 1
        fi
        ;;
    *) printf '%s\n' "Error: unsupported operating system: $os (supported: Darwin, Linux)" >&2; exit 1 ;;
esac

machine=$(uname -m 2>/dev/null || true)
case "$machine" in
    x86_64) arch=x64 ;;
    arm64|aarch64) arch=arm64 ;;
    *) printf '%s\n' "Error: unsupported architecture: $machine (supported: x86_64, arm64, aarch64)" >&2; exit 1 ;;
esac

requested_version=${CODECREW_VERSION-}
if [ -n "$requested_version" ]; then
    case "$requested_version" in
        v*) tag=$requested_version ;;
        *) tag=v$requested_version ;;
    esac
    api_url=https://api.github.com/repos/aichargelabs/codecrew-releases/releases/tags/$tag
else
    tag=latest
    api_url=https://api.github.com/repos/aichargelabs/codecrew-releases/releases/latest
fi

if command -v curl >/dev/null 2>&1; then
    fetch="curl -fsSL --connect-timeout 10 --max-time 30"
elif command -v wget >/dev/null 2>&1; then
    fetch="wget -qO- --timeout=30"
else
    printf '%s\n' "Error: curl or wget is required to resolve the CodeCrew release." >&2
    exit 1
fi

release_json=$(mktemp "${TMPDIR-/tmp}/codecrew-release.XXXXXX") || {
    printf '%s\n' "Error: could not create a temporary file." >&2
    exit 1
}
cleanup() { rm -f "$release_json"; }
trap cleanup 0 1 2 3 15

if ! $fetch "$api_url" >"$release_json"; then
    if [ "$dry_run" -eq 1 ]; then
        if [ "$os_name" = "darwin" ]; then
            asset=CodeCrew-darwin-$arch-latest.dmg
        else
            asset=codecrew-linux-$arch-latest.AppImage
        fi
        printf '%s\n' "==> CodeCrew version: latest (release not found)"
        printf '%s\n' "==> asset not yet published: $asset"
        exit 0
    fi
    printf '%s\n' "Error: could not resolve the CodeCrew release from GitHub." >&2
    exit 1
fi

tag=$(grep '"tag_name"' "$release_json" | sed -n '1s/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
if [ -z "$tag" ]; then
    printf '%s\n' "Error: GitHub returned a release without a tag." >&2
    exit 1
fi
version=${tag#v}
if [ "$os_name" = "darwin" ]; then
    asset=CodeCrew-darwin-$arch-$version.dmg
else
    asset=codecrew-linux-$arch-$version.AppImage
fi
download_url=$(grep '"browser_download_url"' "$release_json" | grep -F "\"$asset\"" | sed -n '1s/.*"browser_download_url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' || true)

printf '%s\n' "==> CodeCrew version: $version"
if [ -z "$download_url" ]; then
    if [ "$dry_run" -eq 1 ]; then
        printf '%s\n' "==> asset not yet published: $asset"
        exit 0
    fi
    printf '%s\n' "CodeCrew builds for $os_name/$arch are coming soon; watch https://github.com/aichargelabs/codecrew-releases/releases" >&2
    exit 1
fi
printf '%s\n' "==> Download URL: $download_url"
if [ "$dry_run" -eq 1 ]; then
    exit 0
fi

tmp_dir=$(mktemp -d "${TMPDIR-/tmp}/codecrew.XXXXXX") || {
    printf '%s\n' "Error: could not create a temporary download directory." >&2
    exit 1
}
cleanup_install() { rm -rf "$tmp_dir"; cleanup; }
trap cleanup_install 0 1 2 3 15

if [ "$os_name" = "darwin" ]; then
    dmg="$tmp_dir/$asset"
    printf '%s\n' "==> Downloading CodeCrew"
    if command -v curl >/dev/null 2>&1; then
        curl -fL --progress-bar "$download_url" -o "$dmg"
    else
        wget -q --show-progress "$download_url" -O "$dmg"
    fi
    mount_dir="$tmp_dir/mount"
    mkdir "$mount_dir"
    hdiutil attach -quiet -nobrowse -mountpoint "$mount_dir" "$dmg" >/dev/null
    if [ -w /Applications ]; then
        app_dir=/Applications
    else
        app_dir=${HOME:?}/Applications
        mkdir -p "$app_dir"
    fi
    if [ ! -d "$mount_dir/CodeCrew.app" ]; then
        printf '%s\n' "Error: CodeCrew.app was not found in the downloaded disk image." >&2
        exit 1
    fi
    printf '%s\n' "==> Installing CodeCrew to $app_dir"
    cp -R "$mount_dir/CodeCrew.app" "$app_dir/"
    hdiutil detach "$mount_dir" -quiet >/dev/null
    printf '%s\n' "==> CodeCrew installed. Launch with: open -a CodeCrew"
    printf '%s\n' "==> The app is unsigned for now; right-click and choose Open on first launch."
else
    bin_dir=${HOME:?}/.local/bin
    app_dir=${HOME:?}/.local/share/applications
    mkdir -p "$bin_dir" "$app_dir"
    printf '%s\n' "==> Downloading CodeCrew to $bin_dir/codecrew"
    if command -v curl >/dev/null 2>&1; then
        curl -fL --progress-bar "$download_url" -o "$bin_dir/codecrew"
    else
        wget -q --show-progress "$download_url" -O "$bin_dir/codecrew"
    fi
    chmod +x "$bin_dir/codecrew"
    desktop_file="$app_dir/codecrew.desktop"
    cat >"$desktop_file" <<EOF
[Desktop Entry]
Name=CodeCrew
Exec=$bin_dir/codecrew
Terminal=false
Categories=Development;Utility;
Type=Application
EOF
    printf '%s\n' "==> CodeCrew installed to $bin_dir/codecrew"
    case ":${PATH-}:" in
        *:"$bin_dir":*) ;;
        *) printf '%s\n' "==> Add $bin_dir to PATH to run codecrew from any terminal." ;;
    esac
    printf '%s\n' "==> AppImage may require FUSE; install FUSE if CodeCrew does not start."
fi
