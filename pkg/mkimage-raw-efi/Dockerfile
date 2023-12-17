# syntax=docker/dockerfile-upstream:1.5.0-rc2-labs
# This mkimage-raw-efi produces the raw EFI partition for EVE,
# including the files in efi-files in the image.  This includes:
#
#   /EFI/BOOT/grub.cfg - Chainloads main bootloader
#   /UsbInvocationScript.txt - Enables USB boot on Dell 3000 series
#
FROM lfedge/eve-rhel:9ad685cd8abb440ce4c7101bf5f0a828f3a525dd-dirty-aa26ab2 AS build
#** SHELL ["/bin/ash", "-eo", "pipefail", "-c"]
SHELL ["/bin/bash", "-eo", "pipefail", "-c"]
#** lddtree not available, libarchive-tools => bsdtar
ENV BUILD_PKGS grep patch git make gcc kernel-headers glibc-devel autoconf \
               automake pkgconfig kmod-devel util-linux cryptsetup-devel \
               libgcc cpio diffutils bzip2 binutils elfutils perl-Pod-Html
ENV PKGS mtools dosfstools bsdtar gdisk e2fsprogs util-linux squashfs-tools \
         coreutils tar dmidecode kmod-libs kmod cryptsetup-libs \
         libblkid cpio glibc-devel watchdog
RUN eve-rhel-deploy.sh

#** get the same version of busy box that Alpine uses
ENV BB_VERSION=1_35_0

#ADD --keep-git-dir git://git@github.com:mirror/busybox.git#${BB_VERSION} /busybox
ADD --keep-git-dir https://github.com/mirror/busybox.git#${BB_VERSION} /busybox

WORKDIR /busybox
#** --insstall applet not found ... sigh!
COPY /bb.config .config
RUN mkdir /bb-out
RUN git branch
#** created a custom config to generate only what we need/need
#**  a work in progress
RUN make && make install CONFIG_PREFIX=/bb-out
RUN cp /bb-out/bin/busybox /bin/busybox

# get mkinitfs source from git and build it locally
# it depends on mod-libs cryptsetup-libs libblkid at runtime and lddtree to run mkinitfs itself
# we could build APK file ourselves but 'apk add' would failed because networking is disabled for almost all linuxkit images
WORKDIR /tmp/mkinitfs
ADD https://github.com/alpinelinux/mkinitfs.git#3.8.1 /tmp/mkinitfs
#** compile fix, strlcpy not available use strncpy
RUN sed -i 's/strlcpy/strncpy/' nlplug-findfs/nlplug-findfs.c
RUN make -j "$(getconf _NPROCESSORS_ONLN)"
WORKDIR /
RUN make -C /tmp/mkinitfs install

WORKDIR /out
RUN echo "mtools_skip_check=1" >> etc/mtools.conf
RUN mkdir -p efifs parts root bits config persist opt/pillar opt/debug lib/modules run sys
COPY make-raw install grub.cfg.in UsbInvocationScript.txt ./
RUN ln -s /usr/sbin/sgdisk ./usr/bin/sgdisk
RUN find / -name libzfs.so.4

#** mkinitfs needs lddtree to function, couldn't find
#**  a SuSE package that has it, located this script
#**  so, clone, and use the script.  Added `binutils`
#**  and `elftools` to help
ADD https://github.com/ncopa/lddtree.git /lddtree
RUN cp /lddtree/lddtree.sh /usr/sbin/lddtree
RUN chmod a+x /usr/sbin/lddtree

#** needed for the initramfs list of "base" files
RUN mkdir -p /etc/apk/keys && touch /etc/apk/keys/kaka

# Before changing something here please take a look into the
# images/rootfs.yml.in onboot section: the installer should
# precede the storage-init container.
#
# now lets create an edge container
# FIXME: 003-installer? why not linuxkit build?
WORKDIR /eco/media/root-rw/root/containers/onboot/003-installer
COPY runtime.json config.json ./
RUN mv /out rootfs
# hadolint ignore=DL3003
RUN (cd /eco && find . -xdev | grep -v installer.img | sort | cpio --quiet -o -H newc) | gzip > rootfs/installer.img
RUN mv rootfs /out

# bootstrap Alpine's initrd
WORKDIR /
COPY initramfs-init.patch /tmp/
RUN patch -p1 < /tmp/initramfs-init.patch

# from https://git.alpinelinux.org/aports/tree/main/mkinitfs/mkinitfs.post-install?id=7b64ec6e904040bd75ea21529b4fce61c908a553
# we need to simulate mkinitfs.post-install from the original APK file
# --- Quote ---
# safety. if nlplug-findfs is missing in the initramfs image we may end up
# with an unbootable system.
RUN if ! grep -q -w /sbin/nlplug-findfs  /etc/mkinitfs/features.d/base.files; then \
        echo "/sbin/nlplug-findfs" >> /etc/mkinitfs/features.d/base.files; \
    fi

RUN echo /bin/grep >> /etc/mkinitfs/features.d/base.files

RUN cd /bin && rm sh && ln -s busybox sh
RUN mkinitfs -n -o /out/initrd.img
RUN cd /bin && rm sh && ln -s ../usr/bin/bash sh

FROM scratch
SHELL ["/bin/bash", "-eo", "pipefail", "-c"]

COPY --from=build /out/ /

ENTRYPOINT [ "/make-raw" ]
