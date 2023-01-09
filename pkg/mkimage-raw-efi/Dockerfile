# syntax=docker/dockerfile-upstream:1.5.0-rc2-labs
# This mkimage-raw-efi produces the raw EFI partition for EVE,
# including the files in efi-files in the image.  This includes:
#
#   /EFI/BOOT/grub.cfg - Chainloads main bootloader
#   /UsbInvocationScript.txt - Enables USB boot on Dell 3000 series
#
FROM lfedge/eve-suse:2f1c38631c5199f885ef4ddde47108a7cb5e6e2d AS build

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]
ENV BUILD_PKGS grep patch libblkid-devel libkmod-devel libcryptsetup-devel \
		util-linux libbsd-devel gcc binutils elfutils which
ENV PKGS mtools libarchive13 gptfdisk squashfs dmidecode
ENV MKINITFS_SHA 224826dcee28425a81bae099ade87fad797a5674

RUN eve-suse-deploy.sh

WORKDIR /out

RUN echo "mtools_skip_check=1" >> etc/mtools.conf
RUN mkdir -p efifs parts root bits config persist opt/pillar opt/debug lib/modules run sys
COPY make-raw install grub.cfg.in UsbInvocationScript.txt ./

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
#* SuSE Linux EVE -- need to build mkinitfs,
#*  clone the repo, patch it so it will build here, build/install
COPY suse.patch /
ADD https://gitlab.alpinelinux.org/alpine/mkinitfs.git#${MKINITFS_SHA} /initramfs
RUN cd /initramfs && patch -p1 < /suse.patch && make all install
COPY initramfs-init.patch /tmp/
#* modified the patche file as the `git` version does not
#*  have the `-r0` at the end of it
RUN patch -p1 < /tmp/initramfs-init.patch
RUN echo /bin/grep >> /etc/mkinitfs/features.d/base.files

#* mkinitfs needs lddtree to function, couldn't find
#*  a SuSE package that has it, located this script
#*  so, clone, and use the script.  Added `binutils`
#*  and `elftools` to help
ADD https://github.com/ncopa/lddtree.git /lddtree
RUN cp /lddtree/lddtree.sh /usr/sbin/lddtree
RUN mkdir -p /etc/apk/keys && touch /etc/apk/keys/kaka

RUN mkinitfs -n -o /out/initrd.img

FROM scratch
SHELL ["/bin/bash", "-eo", "pipefail", "-c"]

COPY --from=build /out/ /

ENTRYPOINT [ "/make-raw" ]
