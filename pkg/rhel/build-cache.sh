#!/bin/sh
set -e

bail() {
  echo "$*"
  exit 1
}

[ "$#" -gt 2 ] || bail "Usage: $0 <os version> <path to the cache> [packages...]"

DNF_CACHE_LOC=/var/cache/dnf
#** file name must match the package section name
RHEL_PKG_SECT=$1
DNF_CACHE="$(find "${DNF_CACHE_LOC}" -type d -print | \
          grep "${rhel_product}-${releasever_major}-${RHEL_PKG_SECT}" | \
          grep -v repodata )"
#** the packages directory does not exist until the first download
#**  even `dnf makecache` doesn't create the packages directory
DNF_CACHE="${DNF_CACHE}"/packages
shift 2

# ensure package cache exists
if [ ! -d "${DNF_CACHE}" ]; then
  rm -rf "${DNF_CACHE}"
  mkdir -p "${DNF_CACHE}"
fi

# check for existing packages in the cache: we NEVER overwrite packages
for p in "$@"; do
  [ -f "$(echo "${DNF_CACHE}/${p}"-[0-9]*)" ] || PKGS="$PKGS $p"
done

# fetch the missing packages
# shellcheck disable=SC2086
if [ -n "$PKGS" ]; then
   rm -f in_output
   touch in_output
   #  Get packages and dependencies.  Following should
   #   download the set of packages needed
   dnf --assumeyes --nodocs --downloadonly \
            --setopt=install_weak_deps=False install $PKGS 2>&1 | \
       tee in_output

   #** download packages already installed, so they are in the cache
   fix_list="$(grep 'already installed' in_output | \
               sed -e's/Package \(.*\) is already installed.*$/\1/')"
   if [ -n "${fix_list}" ]; then
      for xpkg in ${fix_list}
      do
         echo "cache=\"${DNF_CACHE}\" xpkg = \"${xpkg}\""
         # --resolve should pull in dependencies
         dnf download --resolve --setopt=install_weak_deps=False \
             --assumeyes --destdir="${DNF_CACHE}" ${xpkg}
      done
   fi
   rm -f in_output

   # attempt to keep metadata especially the checksum up to date
   dnf makecache

   PKG_CNT="$(find "${DNF_CACHE}" -name \*.rpm | wc -l)"
   echo "${RHEL_PKG_SECT} Package count ${PKG_CNT}"
fi

# index the cache

#** for now don't try to copy/set up dnf/yum for EVE runtime
#**  ROOTFS is not defined as well
#** mkdir -p "$ROOTFS/etc/dnf"
#** echo "$CACHE/.." > "$ROOTFS/etc/rhel/repositories"
