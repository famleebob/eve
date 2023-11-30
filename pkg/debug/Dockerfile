# syntax=docker/dockerfile-upstream:1.5.0-rc2-labs
# for debug container we need to build our own copy of musl
# with -fno-omit-frame-pointer to make sure that perf(1)
# has a fast path for stack unwinding. This also happens
# to be a perfect place to put any other kind of debug info
# into the package: see abuild/etc/abuild.conf.
FROM lfedge/eve-rhel:8c785ecb375912be79d40433553247b0a17b879e-dirty-91c7b8c as build
#** removed abuild
#ENV BUILD_PKGS curl tar make kernel-headers patch gcc-c++ git gcc \
#               ncurses-devel autoconf
ENV BUILD_PKGS curl tar make kernel-headers patch gcc-c++ git gcc \
               ncurses-devel autoconf libstdc++-devel cmake glibc-static
# Feel free to add additional packages here, but be aware that
# EVE's rootfs image can be no larger than 300Mb (and don't
# forget to check on all supported architectures: e.g. arm64
# binaries are typically larger and amd64 ones).
# RUN apk add --no-cache gdb valgrind
#ENV PKGS openssl openssh-clients openssh-server tini util-linux \
#         ca-certificates pciutils usbutils vim-minimal tcpdump \
#         perf strace iproute curl tar
ENV PKGS openssl openssh-clients openssh-server util-linux \
         ca-certificates pciutils vim-minimal lshw \
         strace iproute libcurl curl tar
RUN eve-rhel-deploy.sh

#** this version provided by RHEL 9.2
ENV LSHW_VERSION 02.19.2

# setting up building account
#** RUN adduser -G abuild -D builder || :
#** RUN su builder -c 'abuild-keygen -a -n'

#** COPY --chown=builder:abuild abuild/ /
#** ENV MUSL_VERSION v1.2.3
#** ENV DISTFILES_MIRROR /tmp/mirror
#** ADD --chown=builder:abuild https://git.musl-libc.org/cgit/musl/snapshot/${MUSL_VERSION}.tar.gz ${DISTFILES_MIRROR}/musl-${MUSL_VERSION}.tar.gz
#** RUN su builder -c 'cd /musl && abuild checksum && abuild -r'

# now install it locally so we can pick it up later on below
# hadolint ignore=DL3019,DL3018
#** RUN apk add -p /out --allow-untrusted /home/builder/packages/*/musl-1.2*.apk

#** do we want to build it, or use RHEL lshw (hardware lister)? RHEL??
# hadolint ignore=DL4006
#** ADD https://www.ezix.org/software/files/lshw-B.${LSHW_VERSION}.tar.gz lshw.tar.gz
#** RUN tar -xzvf lshw.tar.gz
#** 
#** COPY lshw/ lshw-B.${LSHW_VERSION}/
#** 
#** WORKDIR /lshw-B.${LSHW_VERSION}
#** 
#** RUN for patch in *.patch; do \
#**    patch -p1 < "$patch"; \
#**  done && \
#**  make -C src RPM_OPT_FLAGS=-DNONLS static && \
#**  cp src/lshw-static /out/usr/bin/lshw && strip /out/usr/bin/lshw

# building hexedit
WORKDIR /tmp/hexedit/hexedit-1.5
# hadolint ignore=DL4006
ADD https://github.com/pixel/hexedit/archive/refs/tags/1.5.tar.gz ../1.5.tar.gz
RUN tar -C .. -xzvf ../1.5.tar.gz
RUN ./autogen.sh && ./configure && make DESTDIR=/out install

# building picocom
# Need this patch to build with musl: https://github.com/npat-efault/picocom/commit/1acf1ddabaf3576b4023c4f6f09c5a3e4b086fb8
ENV PICOCOM_COMMIT=1acf1ddabaf3576b4023c4f6f09c5a3e4b086fb8
ADD --keep-git-dir=true https://github.com/npat-efault/picocom.git#${PICOCOM_COMMIT} /tmp/picocom
WORKDIR /tmp/picocom
RUN make -j "$(getconf _NPROCESSORS_ONLN)" && strip picocom && cp picocom /out/usr/bin/

# tweaking various bit
WORKDIR /out
COPY ssh.sh spec.sh scripts/ ./usr/bin/
RUN mkdir -p ./etc/ssh ./root/.ssh && chmod 0700 ./root/.ssh
RUN cp /etc/passwd /etc/group ./etc/
RUN ln -s /run ./var/run
RUN sed -i -e 's#AllowTcpForwarding.*$#AllowTcpForwarding yes#' ./etc/ssh/sshd_config

#** tini is present in RHEL 7 and 8, but not 9
#**  build it for RHEL also
RUN pwd
ENV TINI_SHA=5aa249684e3b4628df47ad9dc5f93d80301614ae
ENV TINI_VER=v0.19.0
ADD --keep-git-dir https://github.com/krallin/tini.git#${TINI_VER} /tini
WORKDIR /tini
RUN cmake .
RUN make
RUN make DESTDIR=/out install

FROM scratch
ENTRYPOINT []
WORKDIR /

COPY --from=build /out/ /

RUN groupadd sshd
RUN useradd sshd -g sshd

#* from documentation, looks like tini needs to be a "sub-reaper"
ENTRYPOINT ["/usr/local/bin/tini", "-s", "-vv", "/usr/bin/ssh.sh"]
