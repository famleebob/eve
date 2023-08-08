# updating per https://github.com/lf-edge/eve/blob/master/docs/BUILD.md#how-to-update-eve-alpine-package
#*   for RHEL not SuSE or Alpine -- no more card board tree hanging on the rear view mirror or ugly lizzard hanging from it

FROM registry.access.redhat.com/ubi9/ubi-init as base_rootfs

# FROM lfedge/eve-alpine:145f062a40639b6c65efa36bed1c5614b873be52 AS cache
FROM registry.access.redhat.com/ubi9/ubi as cache

ARG TARGETARCH
ENV releasever_major=9
ENV releasever_minor=2
ENV rhel_product=ubi
ENV RHEL_VERSION=${releasever_major}-${releasever_minor}
RUN echo "TARGETARCH=${TARGETARCH}"

RUN zypper --terse -n in -y tar gzip make python gawk pkg-config

# Copy Dockerfile so we can include it in the hash
COPY Dockerfile /etc/
COPY mirrors /tmp/mirrors/
COPY build-cache.sh /bin/

# create all the mirrors
WORKDIR /tmp/mirrors

#   first point to the public package repositories
# OpenSuSE which we comment out for now to keep as close as possible
#  to the default SuSE packages.
# RUN zypper --non-interactive addrepo -keep-packages https://download.opensuse.org/repositories/zypp:/SLE-${RHEL_VERSION}-Branch/openSUSE_Leap_${releasever_major}.${releasever_minor}/zypp:SLE-${SUSE_VERSION}-Branch.repo
# RUN zypper --non-interactive --gpg-auto-import-keys refresh 2
# However, we pull the zfs packages from the filesystems repos; however,
#* we (EVE) build the zfs user level utilities...
#  may pollute the meta-data with higher version number pacakages such
#  as e2fs packages -- may need to pull the zfs packages without full
#  setting it up as a repo ...
#RUN zypper --terse --non-interactive addrepo --keep-packages https://download.opensuse.org/repositories/filesystems/${releasever_major}.${releasever_minor}/filesystems.repo
#RUN zypper --terse --non-interactive --gpg-auto-import-keys refresh filesystems
#RUN yum --assumeyes --non-interactive modifyrepo --keep-packages --all

RUN zypper --assumeyes in tar gcc gzip make python gawk pkg-config patch

#   Where was that mirror again???
ARG THE_CACHE=https://cdn-ubi.redhat.com/content/public/ubi/dist/ubi9/9

RUN [ -d /etc/dnf ] || mkdir /etc/dnf
RUN [ -f /etc/dnf/cache.url ] || echo ${THE_CACHE} > /etc/dnf/cache.url
RUN for repo in main community testing; do \
      for p in "$repo"; do \
        packages="" &&\
        if [ -f "$p" ]; then packages="$packages $(cat "$p")"; fi &&\
        if [ -f "$p.${TARGET_ARCH}" ]; then packages="$packages $(cat "$p.${TARGET_ARCH}")"; fi &&\
        if [ -n "$packages" ]; then build-cache.sh "$p" "/mirror/$(dirname "$p")" "$packages"; fi \
      done \
    done

RUN zypper --terse --non-interactive download libcom_err-devel-1.46.4 libopenssl-1_1-devel-1.1.1l libopenssl-devel-1.1.1l

ARG CACHE_BASE=/var/cache/dnf/packages/SLE_BCI/x86_64
RUN mkdir -p /mirror/${RHEL_VERSION}/rootfs
COPY --from=base_rootfs / /mirror/${RHEL_VERSION}/rootfs

FROM registry.access.redhat.com/ubi9/ubi as compactor
## FROM lfedge/eve-suse:c44c0bbfa6d2ecd892de235362d2c635c6475090 as compactor

COPY --from=cache /mirror /mirror/
COPY --from=cache /var/cache/dnf /var/cache/dnf
COPY --from=cache /etc/dnf /etc/dnf
COPY eve-suse-deploy.sh go-compile.sh /bin/

# load base tools expected in EVE linuxkit build container
RUN zypper --terse -n in -y tar gzip make python gawk pkg-config

# we merge layers in previous step
# so we should avoid large possible diff
FROM scratch

COPY --from=compactor / /
CMD ["/bin/sh"]
