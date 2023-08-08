#!/bin/sh
set -e

bail() {
  echo "$*"
  exit 1
}

[ "$#" -gt 2 ] || bail "Usage: $0 <os version> <path to the cache> [packages...]"

REPO_FILE=" $1"
SUSE_REPO="$(cat /etc/dnf/cache.url)/v$1"
MY_ARCH="$(uname -m | sed s/aarch64/arm64/ | sed s/x86_64/amd64/)"
MY_ARCH=${MY_ARCH##*-}
CACHE="$2/${MY_ARCH}"
ROOTFS="${CACHE}/../rootfs"
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
   #  Get single package, and dependencies.  Following should
   #   just download the set of packages needed
   yum --assumeyes --nodocs --quiet --noautoremove --downloadonly \
       install $PKGS

   echo -n "${REPO_FILE} Package count "
   find /var/cache/dnf -name \*.rpm | wc
   echo "========"
fi

# index the cache

mkdir -p "$ROOTFS/etc/dnf"
#echo "$CACHE/.." > "$ROOTFS/etc/rhel/repositories"
