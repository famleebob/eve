FROM lfedge/eve-suse:8f41da0470c198d5da94d2d05eefebcaa72cd75a AS build

ENV BUILD_PKGS patch curl make gcc perl util-linux git mtools glibc-devel xz-devel libelf-devel libbz2-1
ENV PKGS xz-devel util-linux libelf-devel libbz2-1

RUN eve-suse-deploy.sh

# Build kexec-tools
ENV KEXEC_VERSION=2.0.23
WORKDIR /tmp/kexec/kexec-tools-${KEXEC_VERSION}
ADD https://mirrors.edge.kernel.org/pub/linux/utils/kernel/kexec/kexec-tools-2.0.23.tar.gz /tmp/kexec/kexec-tools.tgz
RUN tar -C .. -xzvf ../kexec-tools.tgz && rm -f ../kexec-tools.tgz
RUN ./configure --prefix /usr && \
    make && \
    make DESTDIR=/out install

FROM scratch
COPY --from=build /out /
