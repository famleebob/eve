# updating per https://github.com/lf-edge/eve/blob/master/docs/BUILD.md#how-to-update-eve-alpine-package
#*   for SuSE not Alpine -- no more card board tree hanging on the rear view mirror

FROM registry.suse.com/bci/bci-busybox:15.4 as base_rootfs

# FROM lfedge/eve-alpine:145f062a40639b6c65efa36bed1c5614b873be52 AS cache
FROM registry.suse.com/bci/bci-base:15.4 as cache

ENV releasever_major=15
ENV releasever_minor=4
ENV suse_product=SLE_BCI
ENV SUSE_VERSION=${releasever_major}-SP${releasever_minor}
ENV TARGET_ARCH=amd64
# this is only needed once, when this package
# is rebased on the new version of Alpine and
# you have to have FROM alpine:x.y.z above:
# RUN apk update && apk upgrade -a
# RUN zypper refresh && zypper update
RUN zypper -n in -y tar gzip make python gawk pkg-config

#*  Will need to add `-r local` at some point to limit
#*  the search to local repos, need to know how to create
#*  a zypper alias ...

# Copy Dockerfile so we can include it in the hash
COPY Dockerfile /etc/
COPY mirrors /tmp/mirrors/
COPY build-cache.sh /bin/

# install abuild for signing (which requires gcc as well)
#* RUN apk add --no-cache abuild gcc sudo
#*  replace abuild with rmt-server for package repos
#*  remove gcc for now, needed for abuild to sign packages
#* RUN zypper install o
#*  -- tried to use rmt-server the SuSE written in ruby, needs my.sql

# install a new key into /etc/apk/keys
#* RUN abuild-keygen -a -i -n
#*  may not need keygen locally ... sort out SuSE repo needs

# create all the mirrors
WORKDIR /tmp/mirrors

#   first point to the public package repositories
# RUN zypper --non-interactive addrepo -keep-packages https://download.opensuse.org/repositories/zypp:/SLE-${SUSE_VERSION}-Branch/openSUSE_Leap_${releasever_major}.${releasever_minor}/zypp:SLE-${SUSE_VERSION}-Branch.repo
# RUN zypper --non-interactive --gpg-auto-import-keys refresh 2
RUN zypper --non-interactive addrepo --keep-packages https://download.opensuse.org/repositories/filesystems/${releasever_major}.${releasever_minor}/filesystems.repo
RUN zypper --non-interactive --gpg-auto-import-keys refresh filesystems
RUN zypper --non-interactive modifyrepo --keep-packages --all

RUN zypper -n in -y tar gcc gzip make python gawk pkg-config patch

#RUN curl -O http://createrepo.baseurl.org/download/createrepo-0.10.4.tar.gz
#RUN tar xC /tmp -zf createrepo-0.10.4.tar.gz
#RUN cd /tmp/createrepo-0.10.4 && make install
#RUN ls -l /usr/bin/createrepo
#RUN /usr/bin/createrepo --help

#   Where was that mirror again???
ARG THE_CACHE=https://download.opensuse.org/repositories/zypp:/SLE-${SUSE_VERSION}-Branch/openSUSE_Leap_${releasever_major}.${releasever_minor}/zypp:SLE-${SUSE_VERSION}-Branch.repo

RUN [ -d /etc/zypper ] || mkdir /etc/zypper
RUN [ -f /etc/zypper/cache.url ] || echo ${THE_CACHE} > /etc/zypper/cache.url
RUN for repo in main community testing; do \
      for p in "$repo"; do \
        packages="" &&\
        if [ -f "$p" ]; then packages="$packages $(cat "$p")"; fi &&\
        if [ -f "$p.${TARGET_ARCH}" ]; then packages="$packages $(cat "$p.${TARGET_ARCH}")"; fi &&\
        if [ -n "$packages" ]; then build-cache.sh "$p" "/mirror/$(dirname "$p")" "$packages"; fi \
      done \
    done

RUN zypper --non-interactive download libcom_err-devel-1.46.4 libopenssl-1_1-devel-1.1.1l libopenssl-devel-1.1.1l go1.18

ARG CACHE_BASE=/var/cache/zypp/packages/SLE_BCI/x86_64
RUN mkdir -p /mirror/${SUSE_VERSION}/rootfs
COPY --from=base_rootfs / /mirror/${SUSE_VERSION}/rootfs

FROM registry.suse.com/bci/bci-base:15.4 as compactor
## FROM lfedge/eve-suse:7595cac560afd50d82093da86567899883918377 as compactor

COPY --from=cache /mirror /mirror/
COPY --from=cache /var/cache/zypp /var/cache/zypp
COPY --from=cache /etc/zypp /etc/zypp
COPY eve-suse-deploy.sh go-compile.sh /bin/

# load base tools expected in EVE linuxkit build container
RUN zypper -n in -y tar gzip make python gawk pkg-config

# we merge layers in previous step
# so we should avoid large possible diff
FROM scratch

COPY --from=compactor / /
CMD ["/bin/sh"]
