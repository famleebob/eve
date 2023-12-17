# syntax=docker/dockerfile-upstream:1.5.0-rc2-labs

# SPDX-License-Identifier: Apache-2.0

FROM lfedge/eve-rhel:9ad685cd8abb440ce4c7101bf5f0a828f3a525dd-dirty-aa26ab2 AS build

#** Alpine pam package is linux-pam-dev, SuSE pam-devel, RHEL pam-devel
ENV BUILD_PKGS git gcc make glibc-devel pam-devel m4 findutils util-linux \
               make patch go file
RUN eve-rhel-deploy.sh

ENV FSCRYPT_COMMIT=b41569d397d3e66099cde07d8eef36b2f42dd0ec
WORKDIR /go/src/github.com/google/fscrypt
# hadolint ignore=DL3020
ADD --keep-git-dir=true https://github.com/google/fscrypt.git#${FSCRYPT_COMMIT} .
COPY patch/* ./
RUN patch -p1 < patch01-no-pam.diff && \
    patch -p1 < patch02-rotate-raw-key.diff && \
    patch -p1 < patch03-vendor.diff && \
    patch -p1 < patch04-goConv.diff && \
    make -j "$(getconf _NPROCESSORS_ONLN)" && make DESTDIR=/out/opt/zededa/bin install

FROM scratch
COPY --from=build /out/opt/zededa/bin /opt/zededa/bin
