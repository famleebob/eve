FROM lfedge/eve-suse:8f41da0470c198d5da94d2d05eefebcaa72cd75a AS build

#* SuSE linux headers come from glibc-devel, libdw* for dwarf info
ENV BUILD_PKGS patch curl make gcc perl util-linux git mtools glibc-devel xz-devel elfutils libbz2-1 patch libdw-devel
ENV PKGS busybox-xz elfutils libbz2-1 libdw1

RUN eve-suse-deploy.sh

# Build makedumpfile
WORKDIR /tmp/makedumpfile/makedumpfile-1.7.1
RUN curl -L https://github.com/makedumpfile/makedumpfile/archive/refs/tags/1.7.1.tar.gz | tar -C .. -xzvf -

#* SuSE supplies only the 64bit version of libbz2
#*  so try but allow for failure of the 32bit,
#*  but insist that the 64bit (`/usr/lib64`) exists
RUN ln -s /usr/lib/libbz2.so.1 /usr/lib/libbz2.so || :
RUN ln -s /usr/lib64/libbz2.so.1 /usr/lib64/libbz2.so && \
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
