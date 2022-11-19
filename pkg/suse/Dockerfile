# updating per https://github.com/lf-edge/eve/blob/master/docs/BUILD.md#how-to-update-eve-alpine-package
#*   for SuSE not Alpine -- no more card board tree hanging on the rear view mirror
# FROM lfedge/eve-alpine:145f062a40639b6c65efa36bed1c5614b873be52 AS cache
FROM registry.suse.com/bci/bci-base:15.4 as cache

ARG releasever_major=15
ARG releasever_minor=4
ARG suse_product=SLE_BCI
ARG SUSE_VERSION=${releasever_major}-SP${releasever_minor}
ARG TARGET_ARCH=amd64
# this is only needed once, when this package
# is rebased on the new version of Alpine and
# you have to have FROM alpine:x.y.z above:
# RUN apk update && apk upgrade -a
RUN zypper refresh && zypper update
RUN zypper -n in tar gzip make python gawk pkg-config
#*  Will need to add `-r local` at some point to limite
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
RUN zypper mr -k 1
RUN zypper addrepo -k -p 1 https://download.opensuse.org/repositories/zypp:/SLE-${SUSE_VERSION}-Branch/openSUSE_Leap_${releasever_major}.${releasever_minor}/zypp:SLE-${SUSE_VERSION}-Branch.repo
RUN zypper addrepo -k -p 2 https://download.opensuse.org/repositories/filesystems/${releasever_major}.${releasever_minor}/filesystems.repo
# RUN zypper mr -F -k --local
# RUN zypper se zfs

#RUN curl -O http://createrepo.baseurl.org/download/createrepo-0.10.4.tar.gz
#RUN tar xC /tmp -zf createrepo-0.10.4.tar.gz
#RUN cd /tmp/createrepo-0.10.4 && make install
#RUN ls -l /usr/bin/createrepo
#RUN /usr/bin/createrepo --help

#   Where was that mirror again???
ARG THE_CACHE=https://download.opensuse.org/repositories/zypp:/SLE-${SUSE_VERSION}-Branch/openSUSE_Leap_${releasever_major}.${releasever_minor}/zypp:SLE-${SUSE_VERSION}-Branch.repo

RUN ls /etc/zypp/repos.d
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

ARG CACHE_BASE=/var/cache/zypp/packages/SLE_BCI/x86_64
RUN find / -name \*.rpm
RUN mv /tmp/mirrors/suse-busybox-bci-x86_64.tar /tmp
RUN mkdir -p /mirror/${SUSE_VERSION}/rootfs
# may want to make this verbose, once working -- debug stuff
RUN tar -C /mirror/${SUSE_VERSION}/rootfs -xf /tmp/suse-busybox-bci-x86_64.tar

#RUN cp /mirror/${SUSE_VERSION}/rootfs/etc/suse/repositories /etc/suse
RUN ls /var/cache/zypp

#* FROM lfedge/eve-alpine:145f062a40639b6c65efa36bed1c5614b873be52 as compactor

FROM registry.suse.com/bci/bci-base:15.4 as compactor

#COPY --from=cache /etc/apk/repositories* /etc/apk/
#COPY --from=cache /etc/apk/keys /etc/apk/keys/
COPY --from=cache /mirror /mirror/
COPY --from=cache /var/cache/zypp /var/cache/zypp
COPY --from=cache /etc/zypp /etc/zypp
COPY eve-suse-deploy.sh go-compile.sh /bin/
RUN find / -name \*.git\*.rpm

#RUN apk update && apk upgrade -a

# we merge layers in previous step
# so we should avoid large possible diff
FROM scratch
COPY --from=compactor / /
CMD ["/bin/sh"]
