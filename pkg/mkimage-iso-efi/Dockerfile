FROM lfedge/eve-rhel:0be024f2e7fea299d8de2d33aceaa40f38b7c4da-dirty-8ca61fa AS build

#** bsdcpio can't be found (for libarchive-tools replacement)
ENV PKGS dosfstools bsdtar binutils mtools xorriso
RUN eve-rhel-deploy.sh

RUN echo "mtools_skip_check=1" >> /out/etc/mtools.conf

FROM scratch
COPY --from=build /out /
COPY . /
WORKDIR /
ENTRYPOINT [ "/make-efi" ]
