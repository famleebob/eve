FROM lfedge/eve-rhel:e4e622342e3b174764195ffc7e632b779fa0c3fc-dirty-a632dff AS build

ENV PKGS dosfstools bsdtar binutils mtools util-linux-ng gdisk \
    xfsprogs e2fsprogs util-linux coreutils device-mapper-multipath \
    squashfs-tools
RUN eve-rhel-deploy.sh

COPY . /out/

FROM scratch
COPY --from=build /out/ /
ENTRYPOINT [ "/make-rootfs" ]
