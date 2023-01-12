FROM lfedge/eve-suse:c30aba4558a5f755e2875f8cdf48c4e46d31a29f AS build

#* SuSE linux headers come from glibc-devel, libdw* for dwarf info
ENV BUILD_PKGS patch curl make gcc perl util-linux git mtools glibc-devel xz-devel elfutils libbz2-1 patch libdw-devel
ENV PKGS busybox-xz elfutils libbz2-1 libdw1

RUN eve-suse-deploy.sh

# Build makedumpfile
WORKDIR /tmp/makedumpfile/makedumpfile-1.7.1
RUN curl -L https://github.com/makedumpfile/makedumpfile/archive/refs/tags/1.7.1.tar.gz | tar -C .. -xzvf -
RUN ln -s /usr/lib/libbz2.so.1 /usr/lib/libbz2.so && \
    ln -s /usr/lib64/libbz2.so.1 /usr/lib64/libbz2.so && \
    make LINKTYPE=dynamic && \
    make DESTDIR=/out install
RUN  make LINKTYPE=dynamic
RUN  make DESTDIR=/out install

FROM scratch
COPY --from=build /out /
COPY kdump.sh /

WORKDIR /
ENTRYPOINT []
CMD ["/kdump.sh"]
