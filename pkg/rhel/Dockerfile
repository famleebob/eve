# updating per https://github.com/lf-edge/eve/blob/master/docs/BUILD.md#how-to-update-eve-alpine-package
#** RELEVE builder container image
# updating per https://github.com/lf-edge/eve/blob/master/docs/BUILD.md#how-to-update-eve-alpine-package
#** RELEVE builder container image

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
RUN mkdir /eve
COPY repo.config /eve
RUN if grep -q x86_64 /eve/repo.config ; then \
        sed -i s/x86_64/$(uname -m)/g /eve/repo.config ; \
    fi
RUN cat /eve/repo.config

# add the expected/required version of go language
RUN echo "${GOVER}" > /eve/gover
RUN echo "${TARGETARCH}" > /eve/target_arch
RUN echo "$(uname -m | sed -e s/x86_64/amd64/ -e s/aarch64/arm64/)" > \
             /eve/this_arch

ADD https://go.dev/dl/go${GOVER}.linux-${TARGETARCH}.tar.gz /eve

#** Need to enable the full repos access through RH subscription manager
RUN dnf -q -y --nodocs --setopt=install_weak_deps=False --allowerasing \
        install curl

#** connect with RHEL via the subscription manager
#**  with secret credentials
RUN mkdir -p /var/secret
ENV SMDEV_CONTAINER_OFF=1
#** RUN --mount=type=secret,id=rhellogin,target=/var/secret/rhellogin \
#**     --mount=type=secret,id=rhelpass,target=/var/secret/rhelpass \
#**     subscription-manager register --username $(< /var/secret/rhellogin) \
#**                 --password $(< /var/secret/rhelpass) --auto-attach
#** else
#**    code for direct inclusion, must clear for public viewing
ENV RHEL_LOGIN ""
ENV RHEL_PASS ""
RUN subscription-manager register --username ${RHEL_LOGIN} \
                --password ${RHEL_PASS} --auto-attach

RUN subscription-manager repos \
     --enable codeready-builder-for-rhel-9-$(uname -m)-rpms

RUN dnf clean all
RUN dnf update -y
#** updated repo connection
#**  need wget to fetch the THIS_ARCH go tar file
RUN dnf -q -y --nodocs --setopt=install_weak_deps=False --allowerasing \
        install wget

#**  BUILDARCH, is the architecture of the machine where this runs.
#**  However, sometimes the working environment is another arch emulated
#**  Ensure that we can load both this working environment and that of
#**  of the target

#** need to wget tar file, can't progamatically set ADD URI
#** ADD https://go.dev/dl/go${GOVER}.linux-$(< /eve/this_arch).tar.gz /
RUN cd / && \
      wget -q https://go.dev/dl/go${GOVER}.linux-$(< /eve/this_arch).tar.gz

RUN if [ $(< /eve/this_arch) = "${TARGETARCH}" ]; then \
        rm /go${GOVER}.linux-$(< /eve/this_arch).tar.gz ;\
     else \
        mv /go${GOVER}.linux-$(< /eve/this_arch).tar.gz /eve ;\
     fi

RUN tar -C /usr/local -xzf /eve/go${GOVER}.linux-"$(< /eve/this_arch)".tar.gz
RUN cd /usr/bin && ln -s /usr/local/go/bin/go . && \
                   ln -s /usr/local/go/bin/gofmt .

RUN go install golang.org/x/lint/golint@latest
RUN go install github.com/gordonklaus/ineffassign@latest
RUN cd /root && tar czf /eve/golibs.tgz go

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

#** repo id                 repo name
#** ubi-9-appstream-rpms    Red Hat Universal Base Image 9 (RPMs) - AppStream
#** ubi-9-baseos-rpms       Red Hat Universal Base Image 9 (RPMs) - BaseOS
#** ubi-9-codeready-builder Red Hat Universal Base Image 9 (RPMs) - CodeReady Builder
#** example /var/cache/dnf/ubi-9-appstream-rpms-b5efbddad0d332c6/packages/patch-2.7.6-16.el9.x86_64.rpm

#** objective is to fill the local dnf (yum, rpm) cache with all packages
#**  enumerated in mirrors/* {appstream-rpms | baseos-rpms | codeready-builder}
#**  and any strong (that is not weak) dependencies.  Such that, the
#**  remaining linuxkit builds of `pkg` container package installs work only
#**  from that package cache. NOTE: package list file names should match the
#**  section names.
RUN for repo in baseos-rpms appstream-rpms codeready-builder; do \
      for p in "$repo"; do \
        packages="" &&\
        if [ -f "$p" ]; then packages="$packages $(cat "$p")"; fi &&\
        if [ -f "$p.${TARGET_ARCH}" ]; then packages="$packages $(cat "$p.${TARGET_ARCH}")"; fi &&\
        if [ -n "$packages" ]; then build-cache.sh "$p" "/mirror/$(dirname "$p")" "$packages"; fi \
      done \
    done

RUN dnf makecache
RUN du -hs /var/cache/dnf
RUN cd /var/cache/dnf && \
       tar -czf /eve/repo.cache.tgz rhel-9-* codeready-builder-*

#** end of sesion with RHEL subscription manager for package access
RUN subscription-manager unregister

RUN cd /var/cache/dnf && tar xzf /eve/repo.cache.tgz
RUN cp /eve/repo.config /etc/yum.repos.d/cache.repo

RUN mkdir -p /mirror/${RHEL_VERSION}/rootfs
COPY --from=base_rootfs / /mirror/${RHEL_VERSION}/rootfs

FROM registry.access.redhat.com/ubi9/ubi as compactor

COPY --from=cache /mirror /mirror/
COPY --from=cache /var/cache/dnf /var/cache/dnf
COPY --from=cache /etc/dnf /etc/dnf
COPY --from=cache /etc/yum.repos.d /etc/yum.repos.d
COPY --from=cache /var/lib/dnf /var/lib/dnf
COPY --from=cache /eve /eve
COPY eve-rhel-deploy.sh go-compile.sh /bin/

# we merge layers in previous step
# so we should avoid large possible diff
FROM scratch

COPY --from=compactor / /
CMD ["/bin/sh"]

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
RUN mkdir /eve
COPY repo.config /eve
RUN if grep -q x86_64 /eve/repo.config ; then \
        sed -i s/x86_64/$(uname -m)/g /eve/repo.config ; \
    fi
RUN cat /eve/repo.config

# add the expected/required version of go language
RUN echo "${GOVER}" > /eve/gover
RUN echo "${TARGETARCH}" > /eve/target_arch
RUN echo "$(uname -m | sed -e s/x86_64/amd64/ -e s/aarch64/arm64/)" > \
             /eve/this_arch

ADD https://go.dev/dl/go${GOVER}.linux-${TARGETARCH}.tar.gz /eve

#** Need to enable the full repos access through RH subscription manager
RUN dnf -q -y --nodocs --setopt=install_weak_deps=False --allowerasing \
        install curl

#** connect with RHEL via the subscription manager
#**  with secret credentials
RUN mkdir -p /var/secret
ENV SMDEV_CONTAINER_OFF=1
#** RUN --mount=type=secret,id=rhellogin,target=/var/secret/rhellogin \
#**     --mount=type=secret,id=rhelpass,target=/var/secret/rhelpass \
#**     subscription-manager register --username $(< /var/secret/rhellogin) \
#**                 --password $(< /var/secret/rhelpass) --auto-attach
#** else
#**    code for direct inclusion, must clear for public viewing
ENV RHEL_LOGIN "zededa-bob"
ENV RHEL_PASS "6OHbJ&*f2KRMlr&#2Ho1kIkzKV7IQRn"
RUN subscription-manager register --username ${RHEL_LOGIN} \
                --password ${RHEL_PASS} --auto-attach

RUN subscription-manager repos \
     --enable codeready-builder-for-rhel-9-$(uname -m)-rpms

RUN dnf clean all
RUN dnf update -y
#** updated repo connection
#**  need wget to fetch the THIS_ARCH go tar file
RUN dnf -q -y --nodocs --setopt=install_weak_deps=False --allowerasing \
        install wget

#**  BUILDARCH, is the architecture of the machine where this runs.
#**  However, sometimes the working environment is another arch emulated
#**  Ensure that we can load both this working environment and that of
#**  of the target

#** need to wget tar file, can't progamatically set ADD URI
#** ADD https://go.dev/dl/go${GOVER}.linux-$(< /eve/this_arch).tar.gz /
RUN cd / && \
      wget -q https://go.dev/dl/go${GOVER}.linux-$(< /eve/this_arch).tar.gz

RUN if [ $(< /eve/this_arch) = "${TARGETARCH}" ]; then \
        rm /go${GOVER}.linux-$(< /eve/this_arch).tar.gz ;\
     else \
        mv /go${GOVER}.linux-$(< /eve/this_arch).tar.gz /eve ;\
     fi

RUN tar -C /usr/local -xzf /eve/go${GOVER}.linux-"$(< /eve/this_arch)".tar.gz
RUN cd /usr/bin && ln -s /usr/local/go/bin/go . && \
                   ln -s /usr/local/go/bin/gofmt .

RUN go install golang.org/x/lint/golint@latest
RUN go install github.com/gordonklaus/ineffassign@latest
RUN cd /root && tar czf /eve/golibs.tgz go

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

#** repo id                 repo name
#** ubi-9-appstream-rpms    Red Hat Universal Base Image 9 (RPMs) - AppStream
#** ubi-9-baseos-rpms       Red Hat Universal Base Image 9 (RPMs) - BaseOS
#** ubi-9-codeready-builder Red Hat Universal Base Image 9 (RPMs) - CodeReady Builder
#** example /var/cache/dnf/ubi-9-appstream-rpms-b5efbddad0d332c6/packages/patch-2.7.6-16.el9.x86_64.rpm

#** objective is to fill the local dnf (yum, rpm) cache with all packages
#**  enumerated in mirrors/* {appstream-rpms | baseos-rpms | codeready-builder}
#**  and any strong (that is not weak) dependencies.  Such that, the
#**  remaining linuxkit builds of `pkg` container package installs work only
#**  from that package cache. NOTE: package list file names should match the
#**  section names.
RUN for repo in baseos-rpms appstream-rpms codeready-builder; do \
      for p in "$repo"; do \
        packages="" &&\
        if [ -f "$p" ]; then packages="$packages $(cat "$p")"; fi &&\
        if [ -f "$p.${TARGET_ARCH}" ]; then packages="$packages $(cat "$p.${TARGET_ARCH}")"; fi &&\
        if [ -n "$packages" ]; then build-cache.sh "$p" "/mirror/$(dirname "$p")" "$packages"; fi \
      done \
    done

RUN dnf makecache
RUN du -hs /var/cache/dnf
RUN cd /var/cache/dnf && \
       tar -czf /eve/repo.cache.tgz rhel-9-* codeready-builder-*

#** end of sesion with RHEL subscription manager for package access
RUN subscription-manager unregister

RUN cd /var/cache/dnf && tar xzf /eve/repo.cache.tgz
RUN cp /eve/repo.config /etc/yum.repos.d/cache.repo

#** need mount points for actual file systems required by EVE
WORKDIR /base_rootfs
RUN mkdir -p persist config conf

RUN mkdir -p /mirror/${RHEL_VERSION}/rootfs

COPY --from=base_rootfs / /mirror/${RHEL_VERSION}/rootfs

FROM registry.access.redhat.com/ubi9/ubi as compactor

COPY --from=cache /mirror /mirror/
COPY --from=cache /var/cache/dnf /var/cache/dnf
COPY --from=cache /etc/dnf /etc/dnf
COPY --from=cache /etc/yum.repos.d /etc/yum.repos.d
COPY --from=cache /var/lib/dnf /var/lib/dnf
COPY --from=cache /eve /eve
COPY eve-rhel-deploy.sh go-compile.sh /bin/

# we merge layers in previous step
# so we should avoid large possible diff
FROM scratch

COPY --from=compactor / /
CMD ["/bin/sh"]
