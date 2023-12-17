# syntax=docker/dockerfile-upstream:1.5.0-rc2-labs
# Copyright (c) 2018 Zededa, Inc.
# SPDX-License-Identifier: Apache-2.0

# use the same set of packages for simplicity
ARG BUILD_PKGS_BASE="git gcc kernel-headers glibc-devel make pam-devel m4 findutils go util-linux make patch go \
                     libuuid libtirpc libblkid zlib tar"

# we use the same image in several places
ARG EVE_RHEL_IMAGE=lfedge/eve-rhel:9ad685cd8abb440ce4c7101bf5f0a828f3a525dd-dirty-aa26ab2

FROM lfedge/eve-dom0-ztools:da7a40f83c7c012d8d4010989ffb4e89225758ec as zfs
RUN mkdir /out
# copy zfs-related files from dom0-ztools using prepared list of files
RUN while read -r x; do \
        if [ -d "$x" ]; then \
          mkdir -p "/out/$x"; \
        else \
          cp -P "$x" "/out/$x"; \
        fi \
    done < /etc/zfs-files

# hadolint ignore=DL3006
FROM ${EVE_RHEL_IMAGE} as build
ARG BUILD_PKGS_BASE
RUN BUILD_PKGS="${BUILD_PKGS_BASE}" eve-rhel-deploy.sh

#* SuSE/RHEL provides `dhclient`, Alpine `dhcpcd` `pillar` makes extensive
#*  use of it.  `dhclient` will soon be deprecated.
#* For now, build it ourselves rather than attempt to use OpenSuSE
#*  which would bring an unknown set of version conflicts
ADD --keep-git-dir https://github.com/NetworkConfiguration/dhcpcd.git#v9.4.1 /dhcpcd
WORKDIR /dhcpcd
RUN ./configure --enable-ipv6               \
            --sysconfdir=/etc               \
            --libexecdir=/usr/lib/dhcpcd    \
            --dbdir=/var/lib/dhcpcd         \
            --runstatedir=/run              \
            --disable-privsep

RUN make && make DESTDIR=/out install
WORKDIR /
#* end SuSE/RHEL addition

# we need zfs files during build
#** Need to be specific because of directory symlinks used by RHEL
COPY --from=zfs /etc/ /etc
COPY --from=zfs /lib/ /usr/lib
COPY --from=zfs /lib64/ /usr/lib64
COPY --from=zfs /sbin/ /usr/sbin
COPY --from=zfs /usr/ /usr

ARG DEV=n
ARG TARGETARCH

# building with runtime stats
ARG RSTATS=n
ARG RSTATS_ENDPOINT=
ARG RSTATS_TAG=

#** why? did a copy from zfs / to build,
#**      only to over-write it here
# we need zfs files during build
#** Need to be specific because of directory symlinks used by RHEL
COPY --from=zfs /out/etc/ /out/etc
COPY --from=zfs /out/lib/ /out/usr/lib
#COPY --from=zfs /out/lib64/ /out/usr/lib64
COPY --from=zfs /out/sbin/ /out/usr/sbin
COPY --from=zfs /out/usr /out/usr

ADD ./  /pillar/

# go vet/format and go install
WORKDIR /pillar

ENV GOFLAGS=-mod=vendor
ENV GO111MODULE=on
ENV CGO_ENABLED=1
ENV GOOS=linux
ENV GOARCH=${TARGETARCH}
ENV CC=gcc
ARG GOPKGVERSION

COPY pillar-patches/* /patches/
RUN set -e && for patch in ../patches/*.patch; do \
        echo "Applying $patch"; \
        patch -p1 --no-backup-if-mismatch -r /tmp/deleteme.rej < "$patch"; \
    done

# hadolint ignore=DL4006
RUN --mount=type=cache,target=/root/.cache/go-build echo "Running go vet" && go vet ./... && \
    echo "Running go fmt" && ERR="$(find . -name \*.go | grep -v /vendor/ | xargs gofmt -d -e -l -s)" && \
       if [ -n "$ERR" ] ; then printf 'go fmt Failed - ERR: %s' "$ERR" ; exit 1 ; fi && \
       make DEV="$DEV" RSTATS=$RSTATS RSTATS_ENDPOINT=$RSTATS_ENDPOINT RSTATS_TAG=$RSTATS_TAG DISTDIR=/final/opt/zededa/bin BUILD_VERSION=${GOPKGVERSION} build

WORKDIR /

ENV DELVE_VERSION 1.20.1
ENV DELVE_SOURCE=https://github.com/go-delve/delve/archive/refs/tags/v${DELVE_VERSION}.tar.gz
# hadolint ignore=DL3020
ADD ${DELVE_SOURCE} /delve.tar.gz
RUN --mount=type=cache,target=/root/.cache/go-build if [ ${DEV} = "y" ]; then \
    tar --absolute-names -xz < /delve.tar.gz && \
    cd "/delve-${DELVE_VERSION}" &&  \
    GOFLAGS= CGO_ENABLED=0 go build -ldflags "-s -w -extldflags '-static'" github.com/go-delve/delve/cmd/dlv && \
    cp dlv /final/opt/ ; \
fi

FROM lfedge/eve-fscrypt:3c759b13e78cba2772bddf88c6904bfaf5fe9ce7 as fscrypt
FROM lfedge/eve-dnsmasq:0613c64049e86605203fb43b7382a1e61f95d24c as dnsmasq
FROM lfedge/eve-gpt-tools:e8521f4c8dbd43aa43ddcd20f1840006662d6783 as gpttools

# collector collects everything together and then does any processing like stripping binaries.
# We use this interim "collector" so that we can do processing.
# hadolint ignore=DL3006
FROM ${EVE_RHEL_IMAGE} as collector
ENV BUILD_PKGS patch
ENV PKGS libtasn1-tools pciutils yajl xz bash iptables iproute \
    coreutils dmidecode bzip2-libs libuuid ipset radvd ethtool \
    util-linux e2fsprogs xorriso \
    qemu-img jq keyutils ca-certificates hdparm \
    libtirpc libblkid zlib net-tools kmod
RUN eve-rhel-deploy.sh
#** THERE BE DRAGONS HERRE!!
#**  copy all the dhcpcd files to the local /out
#**  from the build /out.  Know all the files,
#**  if something changes in dhcpcd this MUST
#**  be verified!!
COPY --from=build /out/usr/lib/dhcpcd /out/usr/lib/dhcpcd
COPY --from=build /out/usr/sbin/dhcpcd /out/usr/sbin
COPY --from=build /out/etc/dhcpcd.conf /out/etc

#** ash not available in RHEL (or SuSE)
SHELL ["/bin/bash", "-eo", "pipefail", "-c"]

WORKDIR /

COPY patches/* /sys-patches/
# hadolint ignore=SC1097
RUN set -e && for patch in /sys-patches/*.patch; do \
        echo "Applying $patch"; \
        patch -p0 --no-backup-if-mismatch -r /tmp/deleteme.rej < "$patch"; \
    done

#** We KNOW what to copy, and which are the directory symlinks
#**  exist at the top level
#** COPY --from=zfs /out/["etc","usr"] /out
COPY --from=zfs /out/etc /out
COPY --from=zfs /out/usr/ /out/usr
COPY --from=zfs /out/lib /out/usr
COPY --from=zfs /out/sbin/ /out/usr/sbin

COPY --from=fscrypt /opt/zededa/bin /out/opt/zededa/bin

#** We KNOW what to copy, and which are the directory symlinks
#**  exist at the top level
COPY --from=gpttools /usr/bin/sgdisk /out/usr/bin/sgdisk
COPY --from=gpttools /usr/bin/cgpt /out/usr/bin/cgpt
COPY --from=gpttools /usr/bin/zboot /out/usr/bin/zboot

COPY --from=dnsmasq /usr/sbin/dnsmasq /out/opt/zededa/bin/dnsmasq
# we use final directory and move the line to the bottom
# to avoid conflicts and speedup re-builds
COPY --from=build /final /out

# We have to make sure configs survive in some location, but they don't pollute
# the default /config (since that is expected to be an empty mount point)
ADD conf/root-certificate.pem conf/server conf/server.production /out/opt/zededa/examples/config/
ADD scripts/device-steps.sh \
    scripts/onboot.sh \
    scripts/handlezedserverconfig.sh \
    scripts/veth.sh \
    scripts/dhcpcd.sh \
  /out/opt/zededa/bin/
ADD conf/lisp.config.base /out/var/tmp/zededa/lisp.config.base

# And now a few local tweaks
COPY rootfs/ /out

# We will start experimenting with stripping go binaries on ARM only for now
#** safe for now, but will need update to run arm64 EVE
#** RUN if [ "$(uname -m)" = "aarch64" ] ; then                                             \
#**        apk add --no-cache findutils binutils file                                      ;\
#**        find /out -type f -executable -exec file {} \; | grep 'not stripped' | cut -f1 -d: |\
#**        xargs strip                                                                     ;\
#**        apk del findutils binutils file                                                 ;\
#**     fi

FROM scratch

SHELL ["/bin/sh", "-c"]

COPY --from=collector /out /

# FIXME: replace with tini+monit ASAP
WORKDIR /
CMD ["/init.sh"]
