FROM lfedge/eve-rhel:fd11ea87f91a90596f75c4f2aba61b13704f7fa0-dirty-399c4aa AS build

ENV BUILD_PKGS patch make gcc util-linux git mtools kernel-headers glibc-devel xz-devel elfutils-devel bzip2-devel
ENV PKGS xz-libs elfutils-devel bzip2-libs

RUN eve-rhel-deploy.sh

# Build makedumpfile
WORKDIR /tmp/makedumpfile/makedumpfile-1.7.1
RUN curl -L https://github.com/makedumpfile/makedumpfile/archive/refs/tags/1.7.1.tar.gz | tar -C .. -xzvf -
RUN ln -s /usr/lib/libbz2.so.1 /usr/lib/libbz2.so && \
    make LINKTYPE=dynamic && \
    make DESTDIR=/out install

FROM scratch
COPY --from=build /out /
COPY kdump.sh /

WORKDIR /
ENTRYPOINT []
CMD ["/kdump.sh"]
