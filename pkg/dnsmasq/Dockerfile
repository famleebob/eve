FROM lfedge/eve-rhel:c215632c87d22f89ab2d20aebe3d66462e793b20-dirty-aac5fba as build
ENV BUILD_PKGS gcc make patch glibc-devel kernel-headers tar
RUN eve-rhel-deploy.sh

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

