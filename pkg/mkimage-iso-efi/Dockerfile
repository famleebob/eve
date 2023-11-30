FROM lfedge/eve-rhel:8c785ecb375912be79d40433553247b0a17b879e-dirty-91c7b8c AS build

#** bsdcpio can't be found (for libarchive-tools replacement)
ENV PKGS dosfstools bsdtar binutils mtools xorriso glibc-gconv-extra \
         elfutils-debuginfod-client
RUN eve-rhel-deploy.sh

RUN echo "mtools_skip_check=1" >> /out/etc/mtools.conf

FROM scratch
COPY --from=build /out /
COPY . /
WORKDIR /
ENTRYPOINT [ "/make-efi" ]
