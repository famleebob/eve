#!/bin/sh -x
# shellcheck disable=SC2086
# shellcheck disable=SC2154
#
# This script is used to setup SuSE build environments
# for EVE containers and produce the resulting, SuSE-based
# executable container if needed (note that not all builds produce
# executable containers -- some just wrap binaries).
#
# This script is drive by the following environment variables:
#   BUILD_PKGS - packages required for the build stage
#   BUILD_PKGS_[amd64|arm64|riscv64] - like BUILD_PKGS but arch specific
#   PKGS - packages required for the executable container
#   PKGS_[amd64|arm64|riscv64] - like PKGS but arch specific
#
# In the future, you'll be able to pass an optional SuSE version to
# the script to indicate the the environment has to be setup with that
# cached version. E.g.:
#   eve-suse-deploy.sh 15-SP4
set -e

SUSE_VERSION=${1:-15-SP4}

bail() {
   echo "$@"
   exit 1
}

case "$(uname -m)" in
   x86_64) BUILD_PKGS="$BUILD_PKGS $BUILD_PKGS_amd64"
           PKGS="$PKGS $PKGS_amd64"
           ;;
  aarch64) BUILD_PKGS="$BUILD_PKGS $BUILD_PKGS_arm64"
           PKGS="$PKGS $PKGS_arm64"
           ;;
  riscv64) BUILD_PKGS="$BUILD_PKGS $BUILD_PKGS_riscv64"
           PKGS="$PKGS $PKGS_riscv64"
           ;;
esac

set $BUILD_PKGS
# [ $# -eq 0 ] || zypper --no-refresh --non-interactive install --dry-run "$@"

rm -rf /out
mkdir /out
tar -C "/mirror/$SUSE_VERSION/rootfs" -cf- . | tar -C /out -xf-

# FIXME: for now we're apk-enabling executable repos, but strictly
# speaking this maybe not needed (or at least optional)
#*  PKGS="$PKGS apk-tools"

set $PKGS
# [ $# -eq 0 ] || zipper --non-interactive in --dry-run -p /out "$@"
# [ $# -eq 0 ] || zipper --no-refresh --non-interactive --root /out in --dry-run "$@"  #install into /out

# FIXME: see above
# cp /etc/apk/repositories.upstream /out/etc/apk/repositories
