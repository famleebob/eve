# syntax=docker/dockerfile-upstream:1.5.0-rc2-labs

# SPDX-License-Identifier: Apache-2.0

FROM lfedge/eve-suse:5b666917dbdbbbe9ccce73eead47f860ae96473c as build

ENV BUILD_PKGS git gcc glibc-devel pam-devel m4 go1.19 make patch \
		findutils util-linux wget

RUN eve-suse-deploy.sh

ENV FSCRYPT_COMMIT=b41569d397d3e66099cde07d8eef36b2f42dd0ec
WORKDIR /go/src/github.com/google/fscrypt
# hadolint ignore=DL3020
ADD --keep-git-dir=true https://github.com/google/fscrypt.git#${FSCRYPT_COMMIT} .
COPY patch/* ./
RUN patch -p1 < patch01-no-pam.diff && \
    patch -p1 < patch02-rotate-raw-key.diff && \
    patch -p1 < patch03-vendor.diff && \
    patch -p1 < patch04-goConv.diff
RUN make --debug && make DESTDIR=/out/opt/zededa/bin install

FROM scratch
COPY --from=build /out/opt/zededa/bin /opt/zededa/bin
