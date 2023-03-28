# syntax=docker/dockerfile-upstream:1.5.0-rc2-labs

FROM lfedge/eve-uefi:d29780144e4dbf0f667b807956699b4412941626 as uefi-build

FROM lfedge/eve-suse:c055c434cf56a79abfdb33f37e482f7c26efab9d as runx-build
# ENV BUILD_PKGS mkinitfs gcc e2fsprogs
ENV BUILD_PKGS make gcc patch libblkid-devel libkmod-devel libcryptsetup-devel \
		libbsd-devel binutils elfutils
RUN eve-suse-deploy.sh

#* SuSE Linux EVE -- need to build mkinitfs,
#*  clone the repo, patch it so it will build here, build/install
WORKDIR /
ENV MKINITFS_SHA 224826dcee28425a81bae099ade87fad797a5674
COPY suse.patch /
ADD https://gitlab.alpinelinux.org/alpine/mkinitfs.git#${MKINITFS_SHA} /initramfs
RUN cd /initramfs && patch -p1 < /suse.patch && make all install

#* mkinitfs needs lddtree to function, couldn't find
#*  a SuSE package that has it, located this script
#*  so, clone, and use the script.  Added `binutils`
#*  and `elftools` to help
ADD https://github.com/ncopa/lddtree.git /lddtree
RUN cp /lddtree/lddtree.sh /usr/sbin/lddtree
RUN mkdir -p /etc/apk/keys && touch /etc/apk/keys/kaka

RUN rm -f /sbin/poweroff /etc/mkinitfs/features.d/base.files
COPY initrd/base.files /etc/mkinitfs/features.d/base.files
COPY initrd/init-initrd initrd/mount_disk.sh initrd/udhcpc_script.sh /
COPY initrd/poweroff /sbin/poweroff
COPY initrd/chroot2.c initrd/hacf.c /tmp/
COPY initrd/00000080 /etc/acpi/PWRF/
RUN gcc -s -o /chroot2 /tmp/chroot2.c
RUN gcc -s -o /hacf /tmp/hacf.c

RUN mkinitfs -n -F base -i /init-initrd -o /runx-initrd

FROM lfedge/eve-suse:c055c434cf56a79abfdb33f37e482f7c26efab9d as build
## removed texinfo, pulls in multiple GiBytes of stuff
ENV BUILD_PKGS \
    gcc make glibc-devel dev86 xz-devel perl bash python3-devel \
    gettext-runtime acpica util-linux-devel ncurses-devel libglib-2_0-0 \
    libpixman-1-0-devel libaio-devel libyajl-devel glib2-devel \
    git patch tar libcap-ng-devel bzip2 gettext-tools \
    libattr-devel flex bison cmake libusb-1_0-devel libuuid-devel
ENV BUILD_PKGS_arm64 dtc-dev

## remove sudo part of SuSE busybox utils
ENV PKGS bash libaio1 libbz2-1 libglib-2_0-0 libpixman-1-0 libyajl2 keyutils libusb-1_0-0 xz-devel libuuid1
ENV PKGS_arm64 libfdt

RUN eve-suse-deploy.sh

# Alpine linux defines all 64bit integer types as long. Patch
# /usr/include/bits/alltypes.h to fix compilation with -m32
WORKDIR /
#* COPY alpine.patch /
#* RUN patch -p1 < alpine.patch

ENV LIBURING_VERSION 0.7
ENV LIBURING_SOURCE=https://git.kernel.dk/cgit/liburing/snapshot/liburing-${LIBURING_VERSION}.tar.bz2

# Download and verify liburing
# hadolint ignore=DL3020
ADD ${LIBURING_SOURCE} /liburing.tar.bz2
RUN tar --absolute-names -xj < /liburing.tar.bz2 && mv "/liburing-${LIBURING_VERSION}" /liburing

WORKDIR /liburing
RUN ./configure --prefix=/usr
RUN make src && make install DESTDIR=/out && make install

# Filter out unneeded stuff
RUN rm -rf /out/usr/man
RUN strip /out/usr/lib/* || :

# When changing this version, also update SEABIOS_UPSTREAM_REVISION to whatever is in `Config.mk` in the xen source
ENV XEN_VERSION 4.15.0
ENV XEN_SOURCE=https://downloads.xenproject.org/release/xen/${XEN_VERSION}/xen-${XEN_VERSION}.tar.gz
ENV EXTRA_QEMUU_CONFIGURE_ARGS="--enable-libusb --enable-linux-aio \
    --enable-vhost-net --enable-vhost-vsock --enable-vhost-scsi --enable-vhost-kernel \
    --enable-vhost-user --enable-linux-io-uring"

WORKDIR /

# Download and verify xen
#TODO: verify Xen
# hadolint ignore=DL3020
ADD ${XEN_SOURCE} /xen.tar.gz
RUN [ -f "$(basename ${XEN_SOURCE})" ] || tar --absolute-names -xz < /xen.tar.gz && mv "/xen-${XEN_VERSION}" /xen

# Apply local patches
COPY patches-${XEN_VERSION} /patches
WORKDIR /xen
RUN cat /patches/*.patch /patches/"$(uname -m)"/*.patch | patch -p1

# we will need this to build xen; without it, it will try and download directly
# Note that Xen's `configure` command uses this env variable SEABIOS_UPSTREAM_URL to find the seabios source.
ENV SEABIOS_UPSTREAM_URL /seabios.git
# this revision should be kept in sync with the XEN_VERSION by reading `Config.mk` in the xen source
ENV SEABIOS_UPSTREAM_REVISION rel-1.14.0
ADD --keep-git-dir git://xenbits.xen.org/seabios.git#${SEABIOS_UPSTREAM_REVISION} ${SEABIOS_UPSTREAM_URL}
# we need this because it will complain about ambiguous refs
RUN git config --global core.warnambiguousrefs false

RUN mkdir -p /out

# FEATURES="--enable-stubdom --enable-vtpm-stubdom --enable-vtpmmgr-stubdom"
COPY gmp.patch /xen/stubdom
WORKDIR /xen
RUN ./configure --prefix=/usr --disable-xen --disable-qemu-traditional --disable-docs --enable-9pfs \
                --with-system-ovmf=/usr/lib/xen/boot/ovmf.bin --disable-stubdom
RUN make -j "$(getconf _NPROCESSORS_ONLN)" && make dist
RUN dist/install.sh /out

# Filter out a few things that we don't currently need
RUN rm -rf /out/usr/share/qemu-xen/qemu/edk2-* /out/var/run /usr/include /usr/lib/*.a
# FIXME: this is a workaround for Xen on ARM still requiring qemu-system-i386
#   https://wiki.xenproject.org/wiki/Xen_ARM_with_Virtualization_Extensions#Use_of_qemu-system-i386_on_ARM
WORKDIR /out/usr/lib/xen/bin/
RUN strip * || :
RUN if [ "$(uname -m)" = "x86_64" ]; then rm -f qemu-system-i386 && ln -s "qemu-system-$(uname -m)" qemu-system-i386 ;fi

COPY --from=uefi-build / /uefi/
RUN mkdir -p /out/usr/lib/xen/boot && cp /uefi/OVMF.fd /out/usr/lib/xen/boot/ovmf.bin && \
  cp /uefi/OVMF_PVH.fd /out/usr/lib/xen/boot/ovmf-pvh.bin
RUN if [ "$(uname -m)" = "x86_64" ]; then cp /uefi/*.rom /out/usr/lib/xen/boot/;fi

FROM scratch
COPY --from=build /out/ /
COPY --from=runx-build /runx-initrd /usr/lib/xen/boot/runx-initrd
COPY init.sh /
COPY qemu-ifup xen-start /etc/xen/scripts/

# We need to keep a slim profile, which means removing things we don't need
RUN rm -rf /usr/lib/libxen*.a /usr/lib/libxl*.a /usr/lib/debug /usr/lib/python*

# Adjust /var/run, /var/lib and /var/lock to be shared
RUN mv /var /var.template && ln -s /run /var && ln -s /run /var.template/run

# Add a few mountpoints so we can use lowerfs in R/O mode
RUN mkdir /persist /hostfs

ENTRYPOINT []
CMD ["/init.sh"]
