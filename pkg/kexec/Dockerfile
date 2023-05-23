FROM lfedge/eve-suse:5b666917dbdbbbe9ccce73eead47f860ae96473c AS build

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
