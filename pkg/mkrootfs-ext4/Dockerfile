FROM lfedge/eve-rhel:0be024f2e7fea299d8de2d33aceaa40f38b7c4da-dirty-8ca61fa AS build

#** bsdcpio missing, for libarchive-tools matching
ENV PKGS dosfstools bsdtar binutils mtools gdisk xfsprogs e2fsprogs \
          util-linux coreutils device-mapper-multipath squashfs-tools
RUN eve-rhel-deploy.sh

COPY . /out/

FROM scratch
COPY --from=build /out/ /
ENTRYPOINT [ "/make-rootfs" ]
