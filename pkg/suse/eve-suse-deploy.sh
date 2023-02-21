#!/bin/sh
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

SUSE_VERSION=${1:-15-SP4}

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
        # condition shell variables so always at least 1 space
        *) BUILD_PKGS="$BUILD_PKGS "
           PKGS="$PKGS "
           echo "Unknown Machine" >&2
           ;;
esac

zypper --terse --non-interactive modifyrepo --no-refresh --keep-packages --all

[ "$BUILD_PKGS" == " " ] || zypper --verbose --ignore-unknown \
				--non-interactive install --no-confirm \
				--no-recommends --force-resolution $BUILD_PKGS

rm -rf /out
mkdir /out
tar -C "/mirror/$SUSE_VERSION/rootfs" -cf- . | tar -C /out -xf-

[ "$PKGS" == " " ] || zypper --verbose --ignore-unknown --installroot /out \
			--no-refresh --non-interactive install --no-confirm \
			--no-recommends --force-resolution $PKGS

# Utilizes the default location for the package cache
#  sometimes, zypper returns an error code even when
#  the message indicates that evrything installed ...
echo "Results is $? <<<======="
