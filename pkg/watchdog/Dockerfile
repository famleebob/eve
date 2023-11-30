# Build watchdogd for RHEL EVE

FROM lfedge/eve-rhel:8c785ecb375912be79d40433553247b0a17b879e-dirty-91c7b8c AS watchdog-build
ENV BUILD_PKGS file libtirpc-devel kernel-headers tar util-linux patch gcc
ENV PKGS libsmartcols
RUN eve-rhel-deploy.sh

# Version 5.15
ENV WATCHDOGD_VERSION 5.15
ENV WATCHDOGD_SRC_DIR watchdog-${WATCHDOGD_VERSION}
ENV WATCHDOGD_SRC_TAR ${WATCHDOGD_SRC_DIR}.tar
ENV WATCHDOGD_SRC_TGZ ${WATCHDOGD_SRC_TAR}.gz
ENV WATCHDOGD_MIRROR_URL https://jaist.dl.sourceforge.net/project/watchdog/watchdog/
ENV WATCHDOGD_SRC_URL ${WATCHDOGD_MIRROR_URL}/${WATCHDOGD_VERSION}/${WATCHDOGD_SRC_TGZ}

WORKDIR /
COPY ${WATCHDOGD_SRC_TGZ} /
RUN tar --absolute-names -zxf /${WATCHDOGD_SRC_TGZ}

# Apply local patches
COPY patches-${WATCHDOGD_SRC_DIR} /patches

WORKDIR /${WATCHDOGD_SRC_DIR}

RUN \
    echo "Applying local patches." ; \
    set -e && for patch in /patches/*.diff; do \
        echo "Applying patch from file $patch"; \
        patch -p1 < "$patch"; \
    done

# XXX: NFS 'support' is a right pain on alpine, and of unclear benefit.
ENV CONFIGURE_OPTS "--disable-nfs"

RUN \
    CPPFLAGS=-I/usr/include/tirpc ./configure ${CONFIGURE_OPTS} && make -j "$(getconf _NPROCESSORS_ONLN)" && make install DESTDIR=/out

FROM scratch
WORKDIR /
COPY --from=watchdog-build /out/ /
COPY --from=watchdog-build /bin/wdctl /bin/wdctl
COPY init.sh /
COPY watchdog.conf.seed /etc/
COPY watchdog-report.sh /sbin/

ENTRYPOINT []
CMD ["/init.sh"]
