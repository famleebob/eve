FROM lfedge/eve-suse:8c48adb6dc81928dfc1016e2ee44c4b18cacbeb2 as build
ENV BUILD_PKGS gcc make patch glibc-devel tar
RUN eve-suse-deploy.sh

ENV DNSMASQ_VERSION 2.84

RUN mkdir -p /dnsmasq/patches

COPY dnsmasq-${DNSMASQ_VERSION}.tar.gz /dnsmasq
COPY patches/* /dnsmasq/patches/

WORKDIR /dnsmasq
RUN tar xvzf dnsmasq-${DNSMASQ_VERSION}.tar.gz

WORKDIR /dnsmasq/dnsmasq-${DNSMASQ_VERSION}
RUN set -e && for patch in ../patches/*.patch; do \
        echo "Applying $patch"; \
        patch -p1 < "$patch"; \
    done

RUN rm -rf /out
RUN make  -j "$(getconf _NPROCESSORS_ONLN)"
RUN make install DESTDIR=/out PREFIX=/usr

FROM scratch
ENTRYPOINT []
CMD []
WORKDIR /
COPY --from=build /out ./

