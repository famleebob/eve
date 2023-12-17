FROM lfedge/eve-rhel:9ad685cd8abb440ce4c7101bf5f0a828f3a525dd-dirty-aa26ab2 as zfs
ENV BUILD_PKGS git patch ca-certificates util-linux gettext-devel \
               libtirpc-devel automake autoconf libtool kernel-headers \
               e2fsprogs openssl-devel util-linux zlib-devel libuuid-devel \
               coreutils libblkid-devel e2fsprogs-devel glibc-devel
ENV PKGS ca-certificates util-linux libuuid libtirpc libblkid openssl zlib
RUN eve-rhel-deploy.sh

COPY /patches /

# should be aligned with kernel
#  * ZFS on Linux
ENV ZFS_VERSION=2.1.2
ENV ZFS_COMMIT=zfs-${ZFS_VERSION}
ENV ZFS_REPO=https://github.com/openzfs/zfs
ENV ZFS_PATCH_DIR=/patches-zfs-"${ZFS_VERSION}"

WORKDIR /tmp/zfs

ADD ${ZFS_REPO}/tarball/${ZFS_COMMIT}/ zfs.tgz
RUN tar -zxvf zfs.tgz  --strip-components=1 && \
    rm zfs.tgz
RUN set -e; \
    if [ ! -d "${ZFS_PATCH_DIR}" ]; then \
        echo "No such dir ${ZFS_PATCH_DIR}"; \
    else \
        for patch in "${ZFS_PATCH_DIR}"/*.patch; do \
            echo "Applying $patch"; \
            patch -p1 < "$patch"; \
        done \
    fi
RUN ./autogen.sh && \
    ./configure \
    --prefix=/usr \
    --with-tirpc \
    --sysconfdir=/etc \
    --mandir=/usr/share/man \
    --infodir=/usr/share/info \
    --localstatedir=/var \
    --with-config=user \
    --with-udevdir=/lib/udev \
    --disable-systemd \
    --disable-static && \
    ./scripts/make_gitrev.sh && \
    make -j "$(getconf _NPROCESSORS_ONLN)" && \
    make DESTDIR=/tmp/zfs-out install-strip

# cleanup
RUN rm -rf /tmp/zfs-out/usr/share && rm -rf /tmp/zfs-out/usr/src && \
    rm -rf /tmp/zfs-out/etc/init.d && rm -rf /tmp/zfs-out/etc/conf.d

# make the list of files built from zfs to reuse later
# hadolint ignore=DL4006
RUN find /tmp/zfs-out -mindepth 1|sed 's@/tmp/zfs-out@@'>/out/etc/zfs-files

#** symlinks in the cloud container image to save space, not so busy box
#**  gets everthing confused, so for the top level directories linked
#**  to its counerpart in /usr, do an explicit copy
RUN cp -r /tmp/zfs-out/etc/* /out/etc
RUN cp -r /tmp/zfs-out/lib/* /out/usr/lib
RUN cp -r /tmp/zfs-out/sbin/* /out/usr/sbin
RUN cp -r /tmp/zfs-out/usr/* /out/usr

FROM scratch
COPY --from=zfs /out/ /
# hadolint ignore=DL3020
#** ADD rootfs/ /
#** see above: same symlinks blow up the ADD command...
RUN mkdir /tmp/trash
ADD rootfs/ /tmp/trash
RUN cd /tmp/trash && cp -r bin/* /usr/bin && cp -r etc/* /etc && \
     cp -r usr/* /usr && cp -r persist / && cp -r config /
#** can't find /bin/sh after using this set of tar commands, so ls
#**  at the end just dies.
#** RUN cd /tmp/trash && tar cf - ./* | $( cd / && tar xf -)
