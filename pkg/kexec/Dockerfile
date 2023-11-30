FROM lfedge/eve-rhel:8c785ecb375912be79d40433553247b0a17b879e-dirty-91c7b8c AS build

ENV BUILD_PKGS patch make gcc util-linux git mtools kernel-headers glibc-devel xz-devel elfutils-devel bzip2-devel
ENV PKGS xz-libs util-linux elfutils-devel bzip2-libs zlib-devel

RUN eve-rhel-deploy.sh

# Build kexec-tools
ENV KEXEC_VERSION=2.0.23
WORKDIR /tmp/kexec/kexec-tools-${KEXEC_VERSION}
ADD https://mirrors.edge.kernel.org/pub/linux/utils/kernel/kexec/kexec-tools-2.0.23.tar.gz /tmp/kexec/kexec-tools.tgz
RUN tar -C .. -xzvf ../kexec-tools.tgz && rm -f ../kexec-tools.tgz
RUN ./configure --prefix /usr && \
    make -j "$(getconf _NPROCESSORS_ONLN)" && \
    make DESTDIR=/out install

FROM scratch
COPY --from=build /out /
