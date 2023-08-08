#!/bin/sh
# shellcheck disable=SC2086
# shellcheck disable=SC2154
#
# This script is used to setup RHEL build environments
# for EVE containers and produce the resulting, RHEL-based
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
#   eve-rhel-deploy.sh 9.2
set -e

SUSE_VERSION=${1:-9,2}

#* Zypper return values are more complex, and some
#*  types of errors we can ignore
#*  see https://en.opensuse.org/SDB:Zypper_manual_(plain)
#*  the "EXIT CODES" section
#** function check_zypp_error () {
#**     local rval=$1
#**     if [ $rval -ge 100 ] && [ $rval -ne 105 ] && [ $rval -ne 101 ]
#**     then
#**         echo "Zypper rval=${rval}, swizzle to 0" >&2
#**         rval=0
#**     fi
#**     return $rval
#** }

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

#** yum --terse --non-interactive modifyrepo --no-refresh --keep-packages --all

if [ "$BUILD_PKGS" != " " ]
then
   yum --nodocs --ignore-unknown --assumeyes --cacheonly \
         install $BUILD_PKGS
   z_rel=$?
fi
#** check_zypp_error $z_rel

#** rm -rf /out
#** mkdir /out
#** tar -C "/mirror/$SUSE_VERSION/rootfs" -cf- . | tar -C /out -xf-

if [ "$PKGS" != " " ]
then
    yum --nodocs --ignore-unknown --installroot /out --cacheonly \
           install $PKGS
    z_rel=$?
fi
#** check_zypp_error $z_rel
