# Copyright (c) 2018 Zededa, Inc.
# SPDX-License-Identifier: Apache-2.0
FROM lfedge/eve-fscrypt:7c5426d6d7e5c209ed2bf579a3475f3483cff7c8 as fscrypt

FROM lfedge/eve-dom0-ztools:4e4771ff4556ceb12dc917870e5b9afd79c14da2 as zfs
RUN mkdir /out
# copy zfs-related files from dom0-ztools using prepared list of files
RUN while read -r x; do \
        if [ -d "$x" ]; then \
          mkdir -p "/out/$x"; \
        else \
          cp -P "$x" "/out/$x"; \
        fi \
    done < /etc/zfs-files

FROM lfedge/eve-suse:279e9bb118f7cb178eb46fd081bc318f5d69a0dc as build

ARG DEV=n

ENV BUILD_PKGS git gcc glibc-devel make pam pam-devel m4 findutils go1.18 util-linux make patch \
    gettext-tools libuuid-devel libtirpc-devel libblkid-devel libopenssl-devel zlib tar libtasn1-devel
# SuSE iprout2 busybox version installed
ENV PKGS libtasn1 pciutils libyajl2 xz bash iptables libxtables12 dhcp-client \
    coreutils dmidecode libbz2-1 libuuid1 ipset curl radvd ethtool util-linux e2fsprogs openssl-1_1 xorriso \
    qemu-tools jq keyutils ca-certificates hdparm \
    gettext-runtime libtirpc3 libblkid1 zlib
RUN eve-suse-deploy.sh

COPY --from=fscrypt /opt/zededa/bin /out/opt/zededa/bin

# we need zfs files during build
COPY --from=zfs /out /

# These three are supporting rudimentary cross-build capabilities.
# The only one supported so far is cross compiling for aarch64 on x86
ENV GOFLAGS=-mod=vendor
ENV GO111MODULE=on
ENV CGO_ENABLED=1
ARG GOARCH=
ARG CROSS_GCC=https://musl.cc/aarch64-linux-musl-cross.tgz
# hadolint ignore=DL3020
ADD ${CROSS_GCC} /cross.tgz
RUN [ -z "$GOARCH" ] || tar -C / -xzvf /cross.tgz && rm -f /cross.tgz

ADD ./  /pillar/

# go vet/format and go install
WORKDIR /pillar

COPY pillar-patches/* /patches/
RUN set -e && for patch in ../patches/*.patch; do \
        echo "Applying $patch"; \
        patch -p1 --no-backup-if-mismatch -r /tmp/deleteme.rej < "$patch"; \
    done

# hadolint ignore=DL4006
RUN [ -z "$GOARCH" ] || export CC=$(echo /*-cross/bin/*-gcc) ;\
    echo "Running go vet" && go vet ./... && \
    echo "Running go fmt" && ERR=$(gofmt -e -l -s $(find . -name \*.go | grep -v /vendor/)) && \
       if [ -n "$ERR" ] ; then echo "go fmt Failed - ERR: "$ERR ; exit 1 ; fi && \
    make DEV=$DEV DISTDIR=/out/opt/zededa/bin build

WORKDIR /

RUN if [ ${DEV} = "y" ]; then \
    unset GOFLAGS && \
    CGO_ENABLED=0 go install -ldflags "-s -w -extldflags '-static'" github.com/go-delve/delve/cmd/dlv@v1.9.1 && \
    cp /root/go/bin/dlv /out/opt; \
fi

COPY patches/* /sys-patches/

# hadolint ignore=SC1097
#* SuSE has no dhcpcd package, trying to patch configuration
#*  files, as such will fail need to get dhcpcd and its config
#*  files installed -- thought I had it ... sigh!
#* RUN set -ex && for patch in /sys-patches/*.patch; do \
#*        echo "Applying $patch"; \
#*        patch -p0 --no-backup-if-mismatch -r /tmp/deleteme.rej < "$patch"; \
#*    done

# we need zfs files on running system
COPY --from=zfs /out /out

FROM lfedge/eve-dnsmasq:06478299b9d0373b15fa2dceff91352463ca64d6 as dnsmasq
FROM lfedge/eve-strongswan:c3c879e21248315b5fe5de69c0dd171f38fab1cb as strongswan
FROM lfedge/eve-gpt-tools:35186db63b4718670ae89b84f736dd6ead4adede as gpttools

# collector collects everything together and then does any processing like stripping binaries.
# We use this interim "collector" so that we can do processing.
FROM lfedge/eve-suse:279e9bb118f7cb178eb46fd081bc318f5d69a0dc as collector

SHELL ["/bin/bash", "-eo", "pipefail", "-c"]

# we put everything into /final
COPY --from=build /out/ /final
COPY --from=gpttools / /final
COPY --from=dnsmasq /usr/sbin/dnsmasq /final/opt/zededa/bin/dnsmasq
COPY --from=strongswan / /final

# We have to make sure configs survive in some location, but they don't pollute
# the default /config (since that is expected to be an empty mount point)
ADD conf/root-certificate.pem conf/server conf/server.production /final/opt/zededa/examples/config/
ADD scripts/device-steps.sh \
    scripts/onboot.sh \
    scripts/handlezedserverconfig.sh \
    scripts/veth.sh \
    scripts/dhcpcd.sh \
  /final/opt/zededa/bin/
ADD conf/lisp.config.base /final/var/tmp/zededa/lisp.config.base

# And now a few local tweaks
COPY rootfs/ /final

# We will start experimenting with stripping go binaries on ARM only for now
#* will need SL-EVE attention, apk is Alpine only and doesn't work with SuSE
RUN if [ "$(uname -m)" = "aarch64" ] ; then                                             \
       apk add --no-cache findutils binutils file                                      ;\
       find /final -type f -executable -exec file {} \; | grep 'not stripped' | cut -f1 -d: |\
       xargs strip                                                                     ;\
       apk del findutils binutils file                                                 ;\
    fi

FROM scratch

SHELL ["/bin/sh", "-c"]

COPY --from=collector /final /

# FIXME: replace with tini+monit ASAP
WORKDIR /
CMD ["/init.sh"]
