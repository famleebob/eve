#!/bin/sh
set -e

bail() {
  echo "$*"
  exit 1
}

[ "$#" -gt 2 ] || bail "Usage: $0 <alpine version> <path to the cache> [packages...]"

SUSE_REPO="$(cat /etc/zypper/cache.url)/v$1"
MY_ARCH="$(zypper tos)"
MY_ARCH=${MY_ARCH##*-}
#CACHE="$2/$(zypper --print-arch)"
CACHE="$2/$MY_ARCH"
ROOTFS="$CACHE/../rootfs"
shift 2

# optionally initialize the cache
[ ! -d "$CACHE" ] && mkdir -p "$CACHE"

# check for existing packages in the cache: we NEVER overwrite packages
for p in "$@"; do
  [ -f "$(echo "$CACHE/${p}"-[0-9]*)" ] || PKGS="$PKGS $p"
done

# fetch the missing packages
# shellcheck disable=SC2086
if [ -n "$PKGS" ]; then
   zypper download -X "$SUSE_REPO" --no-cache --recursive -o "$CACHE" $PKGS || \
     zypper download -X "$SUSE_REPO" --no-cache -o "$CACHE" $PKGS
fi

# index the cache
#rm -f "$CACHE"/APKINDEX*
#apk index --rewrite-arch "$(apk --print-arch)" -o "$CACHE/APKINDEX.unsigned.tar.gz" "$CACHE"/*.apk
#cp "$CACHE/APKINDEX.unsigned.tar.gz" "$CACHE/APKINDEX.tar.gz"
#abuild-sign "$CACHE/APKINDEX.tar.gz"

mkdir -p "$ROOTFS/etc/apk"
cp -r /etc/suse/keys "$ROOTFS/etc/suse"
#cp ~/.abuild/*.rsa.pub "$ROOTFS/etc/suse/keys/"
#cp ~/.abuild/*.rsa.pub /etc/suse/keys/
echo "$CACHE/.." > "$ROOTFS/etc/suse/repositories"
zypper add -X "$CACHE/.." --no-cache --initdb -p "$ROOTFS" busybox
