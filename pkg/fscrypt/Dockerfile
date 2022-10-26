# syntax=docker/dockerfile-upstream:master-labs

# SPDX-License-Identifier: Apache-2.0

FROM lfedge/eve-suse:279e9bb118f7cb178eb46fd081bc318f5d69a0dc as build

ENV BUILD_PKGS git gcc make glibc-devel pam-devel m4 findutils go util-linux make patch
RUN eve-suse-deploy.sh

ENV FSCRYPT_COMMIT=b41569d397d3e66099cde07d8eef36b2f42dd0ec
WORKDIR /go/src/github.com/google/fscrypt
# hadolint ignore=DL3020
ADD --keep-git-dir=true https://github.com/google/fscrypt.git#${FSCRYPT_COMMIT} .
COPY patch/* ./
RUN patch -p1 < patch01-no-pam.diff && \
    patch -p1 < patch02-rotate-raw-key.diff && \
    patch -p1 < patch03-vendor.diff && \
    patch -p1 < patch04-goConv.diff && \
    make && make DESTDIR=/out/opt/zededa/bin install

FROM scratch
COPY --from=build /out/opt/zededa/bin /opt/zededa/bin
