FROM lfedge/eve-rhel:9ad685cd8abb440ce4c7101bf5f0a828f3a525dd-dirty-aa26ab2 AS build

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
