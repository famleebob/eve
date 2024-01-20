FROM lfedge/eve-rhel:c215632c87d22f89ab2d20aebe3d66462e793b20-dirty-aac5fba AS build

#** bsdcpio missing, for libarchive-tools matching
ENV PKGS dosfstools bsdtar binutils mtools gdisk xfsprogs e2fsprogs \
          util-linux coreutils device-mapper-multipath squashfs-tools \
          glibc-devel elfutils-debuginfod-client
RUN eve-rhel-deploy.sh

COPY . /out/

FROM scratch
COPY --from=build /out/ /
ENTRYPOINT [ "/make-rootfs" ]
