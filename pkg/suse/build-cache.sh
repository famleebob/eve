#!/bin/sh
set -e

bail() {
  echo "$*"
  exit 1
}

[ "$#" -gt 2 ] || bail "Usage: $0 <os version> <path to the cache> [packages...]"

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
   zypper -n download $PKGS
   #  Get single package, not dependencies.  Following should
   #   just download the set of packages needed
   # zypper -n install -y -d $PKGS
fi

# DEBUG:peek to see if packages on node
find / -name \*.rpm
# index the cache

mkdir -p "$ROOTFS/etc/zypp"
echo "$CACHE/.." > "$ROOTFS/etc/suse/repositories"
# -X from repo, xx, --initdb new package database, -p manage as a root
zypper -n --installroot "$ROOTFS" --resposd "$CACHE/.." in busybox
