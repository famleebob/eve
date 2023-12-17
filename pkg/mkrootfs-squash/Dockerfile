FROM lfedge/eve-rhel:9ad685cd8abb440ce4c7101bf5f0a828f3a525dd-dirty-aa26ab2 AS build

ENV PKGS dosfstools bsdtar binutils mtools util-linux-ng gdisk \
    xfsprogs e2fsprogs util-linux coreutils device-mapper-multipath \
    squashfs-tools glibc-devel elfutils-debuginfod-client
RUN eve-rhel-deploy.sh

COPY . /out/

FROM scratch
COPY --from=build /out/ /
ENTRYPOINT [ "/make-rootfs" ]
