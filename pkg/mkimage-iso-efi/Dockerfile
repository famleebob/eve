FROM lfedge/eve-rhel:c215632c87d22f89ab2d20aebe3d66462e793b20-dirty-aac5fba AS build

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
