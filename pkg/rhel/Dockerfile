# updating per https://github.com/lf-edge/eve/blob/master/docs/BUILD.md#how-to-update-eve-alpine-package
#** for RHEL not SuSE or Alpine -- the cardboard tree hanging from rear view
#**                                mirror now has a lizard attached

FROM registry.access.redhat.com/ubi9/ubi-init as base_rootfs
FROM registry.access.redhat.com/ubi9/ubi as cache

ARG TARGETARCH
ARG BUILDARCH
ARG GOVER=1.20.1
ENV releasever_major=9
ENV releasever_minor=2
ENV rhel_product=ubi
ENV RHEL_VERSION=${releasever_major}.${releasever_minor}

# Copy Dockerfile so we can include it in the hash
COPY Dockerfile /etc/
COPY mirrors /tmp/mirrors/
COPY build-cache.sh /bin/
COPY add.files /

# add the expected/required version of go language
RUN mkdir /eve
RUN echo "${GOVER}" > /eve/gover

ADD https://go.dev/dl/go${GOVER}.linux-${TARGETARCH}.tar.gz /eve

#** working initial assumption is that the current working environment
#**  is the BUILDARCH, the architecture of the machine where this runs
#**  However, sometimes the working environment is another arch emulated
#**  Ensure that we can load both this working environment and that of
#**  of the target
ENV THIS_ARCH=${BUILDARCH}
RUN export THIS_ARCH="$(uname -m | sed s/aarch64/arm64/ | sed s/x86_64/amd64/)"\
        && echo "${THIS_ARCH}" > /eve/this_arch
ADD https://go.dev/dl/go${GOVER}.linux-${THIS_ARCH}.tar.gz / 
RUN if [ "${THIS_ARCH}" = "${TARGETARCH}" ]; then \
        rm /go${GOVER}.linux-"${THIS_ARCH}".tar.gz ;\
     else \
        mv /go${GOVER}.linux-"${THIS_ARCH}".tar.gz /eve ;\
     fi

# create all the mirrors
WORKDIR /tmp/mirrors

#   Where was that mirror again???
ARG THE_CACHE=https://cdn-ubi.redhat.com/content/public/ubi/dist/ubi9/9

RUN sed -i 's/enabled=1/enabled=0/' /etc/dnf/plugins/subscription-manager.conf
#** assumes only [Main] section, propagate into normal container build
RUN echo "keepcache=1" >> /etc/dnf/dnf.conf
RUN echo "install_weak_deps=False" >> /etc/dnf/dnf.conf
RUN echo "keepcache=True" >> /etc/dnf.conf
#** must create the cache, creates the directory structure used for the cache
RUN dnf makecache

#** repo id                 repo name
#** ubi-9-appstream-rpms    Red Hat Universal Base Image 9 (RPMs) - AppStream
#** ubi-9-baseos-rpms       Red Hat Universal Base Image 9 (RPMs) - BaseOS
#** ubi-9-codeready-builder Red Hat Universal Base Image 9 (RPMs) - CodeReady Builder
#** example /var/cache/dnf/ubi-9-appstream-rpms-b5efbddad0d332c6/packages/patch-2.7.6-16.el9.x86_64.rpm

#** objective is to fill the local dnf (yum, rpm) cache with all packages
#**  enumerated in mirrors/* {appstream-rpms | baseos-rpms | codeready-builder}
#**  and any strong (that is not weak) dependencies.  Such that, the
#**  remaining linuxkit builds of `pkg` container package installs work only
#**  from that package cache. NOTE: package list file names MUST match the
#**  section names.
RUN for repo in baseos-rpms appstream-rpms codeready-builder; do \
      for p in "$repo"; do \
        packages="" &&\
        if [ -f "$p" ]; then packages="$packages $(cat "$p")"; fi &&\
        if [ -f "$p.${TARGET_ARCH}" ]; then packages="$packages $(cat "$p.${TARGET_ARCH}")"; fi &&\
        if [ -n "$packages" ]; then build-cache.sh "$p" "/mirror/$(dirname "$p")" "$packages"; fi \
      done \
    done

#** HACK alert, allows us to directly add to the above packages
#**  entries takes the form of "<section> <package name>"
#**  for example, "appstream-rpms  kernel-headers" one per line
RUN while read -r REPO PACKAGE; do \
      this_cache="$(find /var/cache/dnf -type d -print | grep ubi-9-${REPO} | grep packages | grep -v packages/package | head -1)" ; \
      dnf download -y --nodocs --setopt=install_weak_deps=False \
          --destdir=${this_cache} ${PACKAGE} ; \
    done < /add.files

RUN mkdir -p /mirror/${RHEL_VERSION}/rootfs
COPY --from=base_rootfs / /mirror/${RHEL_VERSION}/rootfs

FROM registry.access.redhat.com/ubi9/ubi as compactor

ENV GOVER=1.20.1
RUN export GOVER="$(cat /eve/gover)"
COPY --from=cache /mirror /mirror/
COPY --from=cache /var/cache/dnf /var/cache/dnf
COPY --from=cache /etc/dnf /etc/dnf
COPY --from=cache /var/lib/dnf /var/lib/dnf
COPY --from=cache /eve /eve
COPY eve-rhel-deploy.sh go-compile.sh /bin/

# we merge layers in previous step
# so we should avoid large possible diff
FROM scratch

COPY --from=compactor / /
CMD ["/bin/sh"]
