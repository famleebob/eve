# syntax=docker/dockerfile-upstream:1.5.0-rc2-labs
# This mkimage-raw-efi produces the raw EFI partition for EVE,
# including the files in efi-files in the image.  This includes:
#
#   /EFI/BOOT/grub.cfg - Chainloads main bootloader
#   /UsbInvocationScript.txt - Enables USB boot on Dell 3000 series
#
FROM lfedge/eve-suse:5b666917dbdbbbe9ccce73eead47f860ae96473c AS build

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]
ENV BUILD_PKGS grep patch libblkid-devel libkmod-devel libcryptsetup-devel \
		util-linux libbsd-devel gcc binutils elfutils which \
		util-linux-systemd git
ENV PKGS mtools libarchive13 gptfdisk squashfs dmidecode dosfstools coreutils \
		 util-linux kmod dash e2fsprogs systemd-sysvinit
ENV MKINITFS_SHA 224826dcee28425a81bae099ade87fad797a5674

RUN eve-suse-deploy.sh

#* SuSE copy lsblk int /out as all supporting libs are there
#*  verified at least onece
RUN cp /usr/bin/lsblk /out/usr/bin

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
COPY suse.patch hack.init.sh /
#* RUN git clone file:///Users/gerald/z-src/downloads/mkinitfs.git /initramfs
ADD https://gitlab.alpinelinux.org/alpine/mkinitfs.git#${MKINITFS_SHA} /initramfs
#* SuSE moved busybox from /bin to /usr/bin ...
RUN sed -i -e 's/bin\/busybox/usr\/bin\/busybox/' /initramfs/initramfs-init.in
RUN sed -i -e 's/\/bin\/sh/\/bin\/sh -x/' /initramfs/initramfs-init.in
#*RUN sed -i -e 's/nlplug\-findfs/nlplug\-findfs \-d /g' /initramfs/initramfs-init.in
RUN grep busybox /initramfs/initramfs-init.in
RUN cd /initramfs && patch -p1 < /suse.patch && make all install
COPY initramfs-init.patch /tmp/

#* modified the patche file as the `git` version does not
#*  have the `-r0` at the end of it
RUN patch -p1 < /tmp/initramfs-init.patch
#* RUN sed -i -e 's/nlplug\-findfs/nlplug\-findfs \-d /g' /usr/share/mkinitfs/initramfs-init
#* RUN sed -i -e 's/\(^\#\![        ]*\/bin\/sh.*$\)/\1\nKOPT_debug_init=\"yes\"/' /usr/share/mkinitfs/initramfs-init
#* RUN sed -i -e 's/\(^\#\![        ]*\/bin\/sh.*$\)/\1\nKOPT_usbdelay=30/' /usr/share/mkinitfs/initramfs-init
RUN sed -i -e 's/^\([    ][      ]*\-n \-b \$repofile -a \/tmp\/apkovls\)/\1\necho \"\$\ result of nlput\-findfs\"/' /usr/share/mkinitfs/initramfs-init
RUN cp /hack.init.sh /usr/share/mkinitfs/initramfs-init
RUN echo /bin/grep >> /etc/mkinitfs/features.d/base.files
#* add only the utilities required for start up...
#*  may miss some, but allows this to work.  The SuSE
#*  busybox doesn't do the `install` command
RUN echo /usr/bin/mount >> /etc/mkinitfs/features.d/base.files
RUN echo /usr/bin/cat >> /etc/mkinitfs/features.d/base.files
RUN echo /usr/bin/ln >> /etc/mkinitfs/features.d/base.files
RUN echo /usr/bin/tr >> /etc/mkinitfs/features.d/base.files
RUN echo /usr/bin/mkdir >> /etc/mkinitfs/features.d/base.files
RUN echo /usr/bin/mknod >> /etc/mkinitfs/features.d/base.files
RUN echo /usr/bin/sleep >> /etc/mkinitfs/features.d/base.files
RUN echo /usr/sbin/findfs >> /etc/mkinitfs/features.d/base.files
RUN echo /usr/sbin/losetup >> /etc/mkinitfs/features.d/base.files
RUN echo /usr/bin/sync >> /etc/mkinitfs/features.d/base.files
RUN echo /usr/bin/cut >> /etc/mkinitfs/features.d/base.files
RUN echo /usr/bin/realpath >> /etc/mkinitfs/features.d/base.files
RUN echo /usr/bin/head >> /etc/mkinitfs/features.d/base.files
RUN sed -i -e 's/bin\/busybox/usr\/bin\/busybox/' \
                 /etc/mkinitfs/features.d/base.files
RUN sed -i -e 's/lib\/mdev/sbin\/mdev/' /etc/mkinitfs/features.d/base.files

#* mkinitfs needs lddtree to function, couldn't find
#*  a SuSE package that has it, located this script
#*  so, clone, and use the script.  Added `binutils`
#*  and `elftools` to help
ADD https://github.com/ncopa/lddtree.git /lddtree
RUN cp /lddtree/lddtree.sh /usr/sbin/lddtree
RUN chmod a+x /usr/sbin/lddtree

#* needed for the initramfs list of "base" files
RUN mkdir -p /etc/apk/keys && touch /etc/apk/keys/kaka

RUN cp -r /out/usr/bin/busybox /usr/bin && \
        cp /out/usr/bin/busybox.install /usr/bin && \
        cp -r /out/usr/share/licenses/busybox /usr/share/licenses/ && \
        cp -r /out/usr/share/busybox /usr/share/
RUN cp /mirror/15-SP4/rootfs/sbin/mdev /sbin

#* RUN /bin/bash
RUN mkinitfs -n -o /out/initrd.img

FROM scratch
SHELL ["/bin/bash", "-eo", "pipefail", "-c"]

COPY --from=build /out/ /

ENTRYPOINT [ "/make-raw" ]
