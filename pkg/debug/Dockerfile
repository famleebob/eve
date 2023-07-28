# syntax=docker/dockerfile-upstream:1.5.0-rc2-labs
# for debug container we need to build our own copy of musl
# with -fno-omit-frame-pointer to make sure that perf(1)
# has a fast path for stack unwinding. This also happens
# to be a perfect place to put any other kind of debug info
# into the package: see abuild/etc/abuild.conf.
FROM lfedge/eve-suse:54c6e6238e27f66068f42fc0ef33e8b611a7b64d as build

ENV BUILD_PKGS curl tar make gawk glibc-devel patch gcc-c++ git gcc \
		ncurses-devel autoconf gzip cmake glibc-devel-static

# Feel free to add additional packages here, but be aware that
# EVE's rootfs image can be no larger than 300Mb (and don't
# forget to check on all supported architectures: e.g. arm64
# binaries are typically larger and amd64 ones).
# RUN apk add --no-cache gdb valgrind

ENV PKGS openssl openssh-clients tcpdump gperf strace lshw openssh-server \
	bash util-linux pciutils util-linux-systemd jq curl socat

RUN eve-suse-deploy.sh

ENV LSHW_VERSION 02.19.2
ENV UE_VERSION 4.2.5
# setting up building account
#* args don't match up with SuSE
#*  -D is don't assign a password ...
#* RUN useradd -G abuild -D builder || :

#* SuSE is glibc, has no musl
# hadolint ignore=DL4006

#* Use SuSE version of lshw provided

# building hexedit
WORKDIR /tmp/hexedit/hexedit-1.5

# hadolint ignore=DL4006
ADD https://github.com/pixel/hexedit/archive/refs/tags/1.5.tar.gz ../1.5.tar.gz
RUN ls ../1.5.tar.gz
RUN /usr/bin/tar -C .. -xzvf ../1.5.tar.gz
RUN ./autogen.sh && ./configure && make DESTDIR=/out install

# tweaking various bit
WORKDIR /out
COPY ssh.sh spec.sh scripts/ ./usr/bin/
RUN mkdir -p ./etc/ssh ./root/.ssh && chmod 0700 ./root/.ssh
RUN cp /etc/passwd /etc/group ./etc/

RUN sed -i -e 's#AllowTcpForwarding.*$#AllowTcpForwarding yes#' ./etc/ssh/sshd_config

#* add uemacs NOTE:DESTDIR doesn't work!
WORKDIR /
ADD https://github.com/rfivet/uemacs.git#${UE_VERSION} /uemacs
WORKDIR /uemacs
RUN sed -i -e's/lcurses/lncurses/' Makefile
RUN make install
RUN cp /usr/bin/ue /out/usr/bin
RUN cp /usr/lib/emacs.hlp /usr/lib/.emacsrc /out/usr/lib
WORKDIR /

#* tini not provided by SuSE... is found in OpenSuSE
#*  hard to mix those two without version issues, build it
ENV TINI_SHA=5aa249684e3b4628df47ad9dc5f93d80301614ae
ENV TINI_VER=v0.19.0
ADD --keep-git-dir https://github.com/krallin/tini.git#${TINI_VER} /tini
WORKDIR /tini
RUN cmake .
RUN make DESTDIR=/out install

FROM scratch

WORKDIR /

COPY --from=build /out/ /

RUN groupadd sshd
RUN useradd sshd

#* from documentation, looks like tini needs to be a "sub-reaper"
ENTRYPOINT ["/usr/local/bin/tini", "-s", "-vv", "/usr/bin/ssh.sh"]
