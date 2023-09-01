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

RHEL_VERSION=${1:-9.2}

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

#** pull packages from the cache, and install them
#**  special care to install selected version of go language
DOGO=
if [ "$BUILD_PKGS" != " " ]
then
   LCL_PKGS=
   for xpkg in $BUILD_PKGS
   do
      #** should check for go${GOVER} only as allow, with error out
      #**  if the go version requested is not the expected
      #**  I can be as opinionated as linuxkit
      if [ "${xpkg}" = "go" ] || [ "${xpkg}" = "golang*" ]
      then
         DOGO="true"
      else
         LCL_PKGS="${LCL_PKGS} ${xpkg}"
      fi
   done
   #** should work with --cacheonly (-C) set, need to fully populate
   #**  the package cache and try again, just appears to ignore it
   #**  will also try higher debug and error reporting levels
   dnf -C --nodocs --assumeyes --setopt=install_weak_deps=False \
         --cacheonly --allowerasing install ${LCL_PKGS}
fi

gover="$(cat /eve/gover)"
if [ "${DOGO}" = "true" ]; then
   this_arch="$(< /eve/this_arch)"
   tar -C /usr/local -xzf /eve/go${gover}.linux-"$(< /eve/this_arch)".tar.gz
   tar -C /usr/local -xzf /eve/golibs.tgz
   cd /usr/bin
   ln -s /usr/local/go/bin/go .
   ln -s /usr/local/go/bin/gofmt .
   ln -s /usr/local/go/bin/golint .
   ln -s /usr/local/go/bin/ineffasign .
   cd /
fi

#** expect minimal rootfs in /mirror
rm -rf /out
mkdir /out
tar -C "/mirror/$RHEL_VERSION/rootfs" -cf- . | tar -C /out -xf-

#** and install target/runtime packages in this minimal root image
#** NOTE: needed to create symlink to get a valid package cache
#**  `--installroot` is more like a `chroot` not just an alternate
#**  location to install
if [ "$PKGS" != " " ]; then
   LCL_PKGS=
   for xpkg in $PKGS
   do
      #** see comment above, craete a shell function for this??
      if [ "${xpkg}" = "go" ] || [ "${xpkg}" = "golang*" ]
      then
         targetarch="$(cat /eve/targetarch)"
         tar -C /out/usr/local -xzf /eve/go${gover}.linux-${targetarch}.tar.gz
         cd /out/usr/bin && ln -s /usr/local/go/bin/go .
         cd /out/usr/bin && ln -s /usr/local/go/bin/gofmt .
         cd /
      else
         LCL_PKGS="${LCL_PKGS} ${xpkg}"
      fi
   done

   cd /out/var/cache && mv dnf dnf.save && ln -s /var/cache/dnf dnf
   if [ -e /out/etc/yum.repos.d ]; then
      cd /out/etc && mv yum.repos.d save.repos.d && \
                        ln -s /etc/yum.repos.d yum.repos.d
   fi
   cd /
   find /out/var/cache/dnf -name core\*.rpm
   dnf --nodocs --assumeyes --installroot /out -C \
       --setopt=install_weak_deps=False \
           --allowerasing install $PKGS
   cd /out/var/cache && rm dnf && mv dnf.save dnf
   rm -f /out/etc/yum.repos.d
   if [ -e /out/etc/save.repos.d ]; then
      mv /out/etc/save.repos.d /out/etc/yum.repos.d
   fi
   cd /
fi
